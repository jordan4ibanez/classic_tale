module math.floating;

import std.traits;

pragma(inline, true)
T lerp(T)(T a, T b, T amount) if (isFloatingPoint!T) {
    return a + amount * (b - a);
}

pragma(inline, true)
T inverseLerp(T)(T position, T start, T end) if (isFloatingPoint!T) {
    return (position - start) / (end - start);
}
