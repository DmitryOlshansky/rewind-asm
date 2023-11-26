module rewind.dynasm;

struct X86Assembler {
    static struct Register {
        uint value;
    }
    
    static struct  ExtendedRegister {
        uint value;
    }

    static struct Label {
        uint value;
    }

    static struct Fixup {
        size_t source;
        size_t target;
    }

    enum EAX = Register(0);
    enum EBX = Register(3);
    enum ECX = Register(1);
    enum EDX = Register(2);
    enum ESI = Register(6);
    enum EDI = Register(7);
    enum EBP = Register(5);
    enum ESP = Register(4);
    
    enum RAX = ExtendedRegister(0);
    enum RBX = ExtendedRegister(3);
    enum RCX = ExtendedRegister(1);
    enum RDX = ExtendedRegister(2);
    enum RSI = ExtendedRegister(6);
    enum RDI = ExtendedRegister(7);
    enum RBP = ExtendedRegister(5);
    enum RSP = ExtendedRegister(4);
    enum R8 = ExtendedRegister(8);
    enum R9 = ExtendedRegister(9);
    enum R10 = ExtendedRegister(10);
    enum R11 = ExtendedRegister(11);
    enum R12 = ExtendedRegister(12);
    enum R13 = ExtendedRegister(13);
    enum R14 = ExtendedRegister(14);
    enum R15 = ExtendedRegister(15);

    private ubyte[] code;
    private Fixup[int] fixups;
    private int labelCounter;

    void label(int n) {
        if (auto p = n in fixups) {
            p.target = code.length;
        } else {
            fixups[n] = Fixup(-1, code.length);
        }
    }

    private ubyte modrm(uint mode, uint reg, int m) {
        return cast(ubyte)((mode << 6) | (reg<<3) | m);
    }

    private ubyte rex(uint w, uint r, uint x, uint b) {
        return cast(ubyte)((0b0100 << 4) | (w << 3) | (r << 2) | (x << 1) | b);
    }

    void mov(Register to, Register from) {
        code ~= 0x89;
        code ~= modrm(0b11, from.value, to.value);
    }

    void mov(ExtendedRegister to, ExtendedRegister from) {
        code ~= rex(1, (from.value & 0x8)>>3, 0, (to.value & 0x8)>>3);
        code ~= 0x89;
        code ~= modrm(0b11, from.value & 0x7, to.value & 0x7);
    }

    void ret() {
        code ~= 0xc3;
    }

    ubyte[] finish() {
        // go through all fixups and fix call/jump to label targets
        return code;
    }
}

auto X86() {
    X86Assembler assembler;
    return assembler;
}

version(unittest):

void testEncoding(ubyte[] code, string assembly, int line = __LINE__) {
    import std.file : writeFile = write, tempDir;
    import std.stdio, std.process, std.path, std.conv, std.regex, std.algorithm, std.array, std.uni;
    auto path = buildPath(tempDir(), text("rewind_asm_", line));
    writeFile(path, code);
    auto result = execute(["objdump", "-M", "intel", "-m", "i386:x86-64", "-b", "binary", "-D", path]);
    assert(result.status == 0);
    debug writeln(result.output);
    auto r = regex(`\d+:\s*([0-9-a-f]+ )+\s*(\S.*)`);
    auto dumped = matchAll(result.output, r).map!(x => x[2]).join("\n") ~"\n";
    auto dumpedFiltered = dumped.filter!(isAlphaNum).array;
    auto assemblyFiltered = assembly.filter!(isAlphaNum).array;
    assert(assemblyFiltered == dumpedFiltered);
}

unittest {
    with(X86()) {
        ret();
        testEncoding(finish(), "ret\n");
    }
}

unittest {
    with(X86()) {
        mov(EAX, EBX);
        mov(ESP, EBP);
        testEncoding(finish(), "mov eax,ebx\nmov esp,ebp\n");
    }
}

unittest {
    with(X86()) {
        mov(RAX, RDX);
        testEncoding(finish(), "mov rax,rdx\n");
    }
}

unittest
{
     with(X86()) {
        mov(RAX, R9);
        mov(R9, RAX);
        mov(R14, R13);
        testEncoding(finish(), "mov rax,r9\nmov r9, rax\nmov r14,r13\n");
     }
}