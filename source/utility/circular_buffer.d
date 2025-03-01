module utility.circular_buffer;

import core.memory;
import std.algorithm;
import std.range;
import std.stdio;

/*
https://github.com/aceawan/cybuf

This thing doesn't have a license.

Also, this thing has been modified to use a raw pointer array.
*/

struct CircularBuffer(T) {

    private T* buf;
    private size_t place;
    private size_t size;
    ulong length = 0;

    bool initialized = false;

    // @disable
    // public this();

    public this(size_t length) {
        this.buf = cast(T*) GC.malloc(T.sizeof * length);
        this.length = length;
        place = 0;
        size = 0;
        this.initialized = true;
    }

    // public this(T[] buf, size_t place, size_t size) {
    //     this.buf = buf;
    //     this.place = place;
    //     this.size = size;
    //     this.initialized = true;
    // }

    // @property
    // public T back() {
    //     return this[$ - 1];
    // }

    @property
    public bool empty() {
        return (size == 0);
    }

    @property
    public T* front() {
        if (place >= length) {
            return buf - (length - place);
        } else {
            return buf + place;
        }
    }

    // @property
    // public size_t length() {
    //     return size;
    // }

    // public T opIndex(size_t index)
    // in {
    //     assert(index < size);
    // }
    // body {
    //     if (place + index >= length) {
    //         return buf[index - (length - place)];
    //     } else {
    //         return buf[place + index];
    //     }
    // }

    // public size_t opDollar() {
    //     return size;
    // }

    // public void popBack() {
    //     size--;
    // }

    public void popFront() {
        place = (place + 1 == length) ? 0 : place + 1;
        size--;
    }

    public void put(T elem) {
        if (place + size < length) {
            buf[place + size] = elem;
        } else {
            buf[size - (length - place)] = elem;
        }

        if (size == length) {
            place = (place + 1 == length) ? 0 : place + 1;
        } else {
            size++;
        }
    }

    // public void put(T[] elems) {
    //     foreach (e; elems) {
    //         this.put(e);
    //     }
    // }

    // public T[] rawBuf() {
    //     return this.buf;
    // }

    // @property
    // public CircularBuffer!T save() const {
    //     return CircularBuffer!T(buf.dup, place, size);
    // }
}
