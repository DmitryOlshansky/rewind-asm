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

    void mov(Register to, Register from) {

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
    import std.stdio, std.process, std.path, std.conv, std.regex, std.algorithm, std.array;
    auto path = buildPath(tempDir(), text("rewind_asm_", line));
    writeFile(path, code);
    auto result = execute(["objdump", "-M", "intel", "-m", "i386:x86-64", "-b", "binary", "-D", path]);
    assert(result.status == 0);
    //writeln(result.output);
    auto r = regex(`\d+:\s*([0-9-a-f]+ )+\s*(\S.*)`);
    auto dumped = matchAll(result.output, r).map!(x => x[2]).join("\n") ~"\n";
    assert(assembly == dumped);
}

unittest {
    with(X86()) {
        ret();
        ubyte[] code = finish();
        testEncoding(code, "ret\n");
    }
}