module utility.flat_container_2d;

import math.vec2i;

/// A 2D container utilizing a 1D array with 2D -> 1D basic data packing.
/// Uses this to maximize performance.
///
/// Can have any size from 0 up in each dimension.
///
/// If you need a 3D container, use FlatContainer3D.
/// 
///? Note: this container is one long piece of memory. It should be put on the heap unless you're using a small one!
struct FlatContainer2D(T, int xSize, int ySize) {

private:

    T[xSize * ySize] data;

    pragma(inline, true)
    Vec2i indexToPosition(int index) const {
        return Vec2i(
            // index / (_y * _z),
            (index % (xSize * ySize)) / ySize, //_x used to be _z 
            (index % ySize),
        );
    }

    pragma(inline, true)
    int positionToIndex(int xPos, int yPos) const {
        return  /*(xPos * (_z * _y)) +*/ (xPos * ySize) + yPos; // xPos used to be zPos
    }

    pragma(inline, true)
    int positionToIndex(Vec2i position) const {
        return positionToIndex(position.x, position.y);
    }

public:

    const(T) get(int x, int y) const {
        return data[positionToIndex(x, y)];
    }

    const(T) get(Vec2i position) const {
        return data[positionToIndex(position)];
    }

    T get(int x, int y) {
        return data[positionToIndex(x, y)];
    }

    T get(Vec2i position) {
        return data[positionToIndex(position)];
    }

    ///! Danger zone.
    const(T) getIndex(int index) const {
        return data[index];
    }

    ///! Danger zone.
    T getIndex(int index) {
        return data[index];
    }

    T* getRef(int x, int y) {
        return &data[positionToIndex(x, y)];
    }

    T* getRef(Vec2i position) {
        return &data[positionToIndex(position)];
    }

    const(T)* getRef(int x, int y) const {
        return &data[positionToIndex(x, y)];
    }

    const(T)* getRef(Vec2i position) const {
        return &data[positionToIndex(position)];
    }

    ///! Danger zone.
    T* getIndexRef(int index) {
        return &data[index];
    }

    void set(int x, int y, T newData) {
        data[positionToIndex(x, y)] = newData;
    }

    void set(Vec2i position, T newData) {
        data[positionToIndex(position)] = newData;
    }

    ///! Danger zone.
    void setIndex(int index, T newData) {
        data[index] = newData;
    }

    ulong getLength() {
        return data.length;
    }

    /// Completely reset the underlying array.
    void reset() {
        this.data = this.data.init;
    }

    ///! This is extremely dangerous!
    T[xSize * ySize]* getDataArray() {
        return &data;
    }
}

unittest {
    // void blah2() {
    import std.conv;
    import std.datetime;
    import std.random;
    import std.stdio;

    // foreach (pass; 0 .. 100) {
    auto rng = Random(unpredictableSeed());
    // This can take 0 for 1D, but that's dumb.
    // const int testX = uniform(1, 200, rng);
    // const int testY = uniform(1, 200, rng);
    // const int testX = 67;
    // const int testY = 132;
    enum size = () {
        // Hack job to get 3 random integers at compile time.
        int seed = 0;
        foreach (char c; __TIMESTAMP__) {
            seed = (seed * 31) + c;
        }
        auto rngX = Random(seed);
        auto rngY = Random(seed + 31);
        return Vec2i(
            uniform(1, 200, rngX), uniform(1, 200, rngY)
        );
    }();
    //? Note: this container is one long piece of memory. It should be put on the heap unless you're using a small one!
    FlatContainer2D!(int, size.x, size.y)* database = new FlatContainer2D!(int, size.x, size.y)();
    writeln("[Note]: Unit test on FlatContainer2D requires a rebuild to randomize!");
    writeln("test: ", 1, " | size: ( ", size.x, ", ", size.y, " )");
    int realIndex = 0;
    int t = 0;
    foreach (x; 0 .. size.x) {
        foreach (y; 0 .. size.y) {
            t++;
            const Vec2i realPosition = Vec2i(x, y);
            const int calculatedIndex = database.positionToIndex(realPosition);
            const int calculatedIndexLiteral = database.positionToIndex(realPosition);
            assert(realIndex == calculatedIndex, i"Index not correct. Real: $(
                    realIndex) vs $(
                    calculatedIndex)".text);
            assert(realIndex == calculatedIndexLiteral);
            const Vec2i calculatedPosition = database.indexToPosition(realIndex);
            assert(realPosition == calculatedPosition, i"Position not correct. real $(
                    realPosition) vs $(calculatedPosition) | iteration: $(t)".text);
            // Triple check.
            assert(realIndex == database.positionToIndex(calculatedPosition));
            // Quadruple check. (Dumb)
            assert(database.indexToPosition(calculatedIndex) ==
                    database.indexToPosition(
                        database.positionToIndex(calculatedPosition)));
            // And I have no idea why I even added this one at this point.
            assert(database.positionToIndex(
                    realPosition) == database.positionToIndex(calculatedPosition));
            //! Now, to calculate some data.
            const testData = uniform(0, 1_000_000, rng);
            database.setIndex(realIndex, testData);
            assert(database.getIndex(realIndex) == testData);
            assert(database.getIndex(calculatedIndex) == testData);
            assert(database.get(realPosition) == testData);
            assert(database.get(calculatedPosition) == testData);
            realIndex++;
        }
    }
    // writeln("pass basic");
    // Next step is randomized position as a baseline.
    immutable int sampleSize = 500_000;
    foreach (_; 0 .. sampleSize) {
        const Vec2i realPosition = Vec2i(
            uniform(0, size.x, rng),
            uniform(0, size.y, rng),
        );
        const calculatedIndex = database.positionToIndex(realPosition);
        const calculatedIndexRaw = database.positionToIndex(realPosition.x, realPosition.y);
        const calculatedPosition = database.indexToPosition(calculatedIndex);
        assert(realPosition == calculatedPosition);
        const reverseCalculatedIndex = database.positionToIndex(calculatedPosition);
        assert(reverseCalculatedIndex == calculatedIndex);
        assert(calculatedIndex == calculatedIndexRaw);
        const testData = uniform(0, 1_000_000, rng);
        database.setIndex(calculatedIndex, testData);
        assert(database.getIndex(calculatedIndex) == testData);
        assert(database.getIndex(reverseCalculatedIndex) == testData);
        assert(database.positionToIndex(
                database.indexToPosition(
                reverseCalculatedIndex)) == database.positionToIndex(realPosition));
        assert(reverseCalculatedIndex == database.positionToIndex(
                database.indexToPosition(reverseCalculatedIndex)));
        assert(calculatedIndex == database.positionToIndex(
                database.indexToPosition(reverseCalculatedIndex)));
        assert(database.positionToIndex(
                database.indexToPosition(
                reverseCalculatedIndex)) == database.positionToIndex(realPosition.x, realPosition.y));
    }
    // }

    writeln("passed.");
}
