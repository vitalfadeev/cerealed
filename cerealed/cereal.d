module cerealed.cereal;

import std.traits;

class Cereal {
public:

    //catch all signed numbers and forward to reinterpret
    void grain(T)(ref T val) if(isSigned!T || isBoolean!T || is(T == char) || isFloatingPoint!T) {
        grainReinterpret(val);
    }

    void grain(T)(ref T val) if(is(T == ubyte)) {
        grainUByte(val);
    }

    void grain(T)(ref T val) if(is(T == ushort)) {
        ubyte valh = (val >> 8);
        ubyte vall = val & 0xff;
        grainUByte(valh);
        grainUByte(vall);
        val = (valh << 8) + vall;
    }

    void grain(T)(ref T val) if(is(T == uint)) {
        ubyte val0 = (val >> 24);
        ubyte val1 = cast(ubyte)(val >> 16);
        ubyte val2 = cast(ubyte)(val >> 8);
        ubyte val3 = val & 0xff;
        grainUByte(val0);
        grainUByte(val1);
        grainUByte(val2);
        grainUByte(val3);
        val = (val0 << 24) + (val1 << 16) + (val2 << 8) + val3;
    }

    void grain(T)(ref T val) if(is(T == ulong)) {
        auto ptr = cast(ubyte*)(&val);
        for(int i = 7; i >= 0; --i) {
            grainUByte(ptr[i]);
        }
        ulong newVal = 0;
        for(int i = 7; i >= 0; --i) {
            newVal += (ptr[i] << (i * 8));
        }
        val = newVal;
    }

    void grain(T)(ref T val) if(is(T == wchar)) {
        grain(*cast(ushort*)&val);
    }

    void grain(T)(ref T val) if(is(T == dchar)) {
        grain(*cast(uint*)&val);
    }

    void grain(T, U = ushort)(ref T val) if(isArray!T) {
        U length = cast(U)val.length;
        grain(length);
        foreach(e; val) grain(e);
    }

    void grain(T, U = ushort)(ref T val) if(isAssociativeArray!T) {
        U length = cast(U)val.length;
        grain(length);
        foreach(k, v; val) {
            grain(k);
            grain(v);
        }
    }

    @property const(ubyte[]) bytes() const nothrow {
        return _bytes;
    }

protected:

    abstract void grainUByte(ref ubyte val);
    void addByte(ubyte b) {
        _bytes ~= b;
    }

private:

    ubyte[] _bytes;

    void grainReinterpret(T)(ref T val) {
        auto ptr = cast(CerealPtrType!T)(&val);
        grain(*ptr);
    }
}

private template CerealPtrType(T) {
    static if(is(T == bool) || is(T == char)) {
        alias ubyte* CerealPtrType;
    } else static if(is(T == float)) {
        alias uint* CerealPtrType;
    } else static if(is(T == double)) {
        alias ulong* CerealPtrType;
    } else {
       import std.traits;
       alias Unsigned!T* CerealPtrType;
    }
}
