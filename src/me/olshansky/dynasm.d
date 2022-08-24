module me.olshansky.dynasm;

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
        size_t offset;
        Label label;
    }

    enum EAX = Register(0);
    enum EBX = Register(1);
    enum ECX = Register(2);

    private ubyte[] code;
    private Fixup[] fixups;
    private int labelCounter;

    void mov(Register to, Register from) {

    }

    ubyte[] finish() {
        // fixup jump to label targets
        return code;
    }
}

auto X86() {
    X86Assembler assembler;
    return assembler;
}