module utility.queue;

import optibrev;
import std.container;

struct Queue(T) {
private:

    DList!T elements;

public:

    void push(T data) {
        elements.insertBack(data);
    }

    Option!T pop() {
        Option!T result;
        if (elements.empty()) {
            return result;
        }
        result = elements.front();
        elements.removeFront();
        return result;
    }
}
