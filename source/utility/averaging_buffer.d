module utility.averaging_buffer;
import core.memory;
import std.traits;

struct AveragingBuffer(T) if (isFloatingPoint!T) {
private:

    ulong index = 0;
    ulong size = 0;
    T divisor = 0;
    T* data;

public:

    this(ulong size) {
        this.data = cast(T*) GC.malloc(T.sizeof * size);
        this.size = size;
        this.divisor = cast(T) 1.0 / cast(T) size;
    }

    void push(T newData) {
        this.data[index] = newData;
        this.index++;
        if (this.index >= this.size) {
            this.index = 0;
        }
    }

    T getAverage() {
        T output = 0;
        foreach (i; 0 .. this.size) {
            output += this.data[i];
        }
        output *= this.divisor;
        return output;
    }
}
