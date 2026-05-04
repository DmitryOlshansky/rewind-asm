module rewind.dynasm.mem;

import std.exception : enforce;

// LLVM/GCC intrinsic for instruction cache flushing (critical for JITs)
private extern(C) void __clear_cache(char* begin, char* end);

immutable size_t pageSize;

void[] reallocateVM(void[] mapping, size_t newSize) {
    enforce(mapping.length < newSize);
    void[] buffer = allocateVM(newSize);
    buffer[0..mapping.length] = mapping[];
    deallocateVM(mapping);
    return buffer[0..newSize];
}

version (Posix) {
    import core.sys.posix.sys.mman;
    import core.sys.posix.unistd;

    void[] allocateVM(size_t size) {
        enforce(size % pageSize == 0, "allocateVM only accepts multiple of page size");
        void* buffer = mmap(null, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
        enforce(buffer != MAP_FAILED, "mmap failed to allocate buffer");
        return buffer[0..size];
    }

    void makeExecutableAndFlushCache(void[] mapping) {
        int res = mprotect(mapping.ptr, mapping.length, PROT_READ | PROT_EXEC);
        enforce(res == 0, "mprotect failed to set PROT_EXEC");
        // This builtin flushes the cache lines to prevent executing stale data.
        __clear_cache(cast(char*)mapping.ptr, cast(char*)(mapping.ptr+mapping.length));
    }

    void deallocateVM(void[] mapping) {
        int res = munmap(mapping.ptr, mapping.length);
        enforce(res == 0, "munmap failed to unmap memory");
    }

    shared static this() {
        pageSize = sysconf(_SC_PAGESIZE);
    }

} else version (Windows) {
    import core.sys.windows.core;
    import std.windows.syserror;

    void[] allocateVM(size_t size) {
        void* p = VirtualAlloc(null, size, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
        wenforce(p != null, "VirtualAlloc failed");
        return p[0..size];
    }

    void makeExecutableAndFlushCache(void[] mapping) {
        DWORD old;
        auto res = VirtualProtect(mapping.ptr, mapping.length, PAGE_EXECUTE_READ, &old);
        wenforce(res != 0, "VirtualProtect failed");

    }

    void deallocateVM(void[] mapping) {
        int res = VirtualFree(mapping.ptr, 0, MEM_RELEASE);
        wenforce(res != 0, "VirtualFree failed");
        // This builtin flushes the cache lines to prevent executing stale data.
        __clear_cache(cast(char*)mapping.ptr, cast(char*)(mapping.ptr+mapping.length));
    }

    shared static this() {
        SYSTEM_INFO si;
        GetSystemInfo(&si);
        pageSize = si.dwPageSize;
    }
} else {
    static assert(false, "Unsupported OS for JIT memory management");
}

unittest {
    uint[] p = cast(uint[])allocateVM(pageSize);
    p[pageSize/uint.sizeof-1] = 42;
    p = cast(uint[])reallocateVM(p, pageSize*2);
    assert(p[pageSize/uint.sizeof-1] == 42);
    p[pageSize*2/uint.sizeof-1] = 43;
    assert(p[pageSize*2/uint.sizeof-1] == 43);
    makeExecutableAndFlushCache(p);
    deallocateVM(p);
}