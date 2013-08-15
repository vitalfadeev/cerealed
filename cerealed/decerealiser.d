module cerealed.decerealiser;

import cerealed.cereal;
import std.traits;

class Decerealiser: Cereal {
public:

    this(T)(T[] bytes) if(isNumeric!T) {
        static if(is(T == ubyte)) {
            _bytes = bytes.dup;
        } else {
            foreach(b; bytes) _bytes ~= cast(ubyte)b;
        }
    }

    @property T value(T)() if(!isArray!T && !isAssociativeArray!T) {
        T val;
        grain(val);
        return val;
    }

    @property T value(T, U = ushort)() if(isArray!T && !is(T == string)) {
        U length;
        grain(length);
        Unqual!T values;
        values.length = length; //allocate, can't use new (new what?)
        for(ushort i = 0; i < length; ++i) {
            grain(values[i]);
        }
        return values;
    }

    @property string value(T, U = ushort)() if(is(T == string)) {
        U length;
        grain(length);
        auto values = new char[length];
        for(ushort i = 0; i < length; ++i) {
            grain(values[i]);
        }
        return cast(string)values;
    }

    @property T value(T, U = ushort)() if(isAssociativeArray!T) {
        U length;
        grain(length);
        T values;
        for(ushort i = 0; i < length; ++i) {
            KeyType!T key;
            ValueType!T value;
            grain(key);
            grain(value);
            values[key] = value;
        }
        return values;
    }

protected:

    override void grainUByte(ref ubyte val) {
        val = _bytes[0];
        _bytes = _bytes[1..$];
    }
}
