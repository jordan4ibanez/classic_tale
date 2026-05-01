module utility.flat_container_3d;

import math.vec3i;

/// A 3D container utilizing a 1D array with 3D -> 1D basic data packing.
/// Uses this to maximize performance.
///
/// Can have any size from 0 up in each dimension.
///
/// If you need a 2D container, use FlatContainer2D.
/// 
///? Note: this container is one long piece of memory. It should be put on the heap unless you're using a small one!
struct FlatContainer3D(T, int xSize, int ySize, int zSize) {

private:

    T[xSize * ySize * zSize] data;

    pragma(inline, true)
    Vec3i indexToPosition(int index) const {
        return Vec3i(
            index / (ySize * zSize),
            (index % ySize),
            (index % (zSize * ySize)) / ySize
        );
    }

    pragma(inline, true)
    int positionToIndex(int xPos, int yPos, int zPos) const {
        return (xPos * (zSize * ySize)) + (zPos * ySize) + yPos;
    }

    pragma(inline, true)
    int positionToIndex(Vec3i position) const {
        return positionToIndex(position.x, position.y, position.z);
    }

public:

    const(T) get(int x, int y, int z) const {
        return data[positionToIndex(x, y, z)];
    }

    const(T) get(Vec3i position) const {
        return data[positionToIndex(position)];
    }

    T get(int x, int y, int z) {
        return data[positionToIndex(x, y, z)];
    }

    T get(Vec3i position) {
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

    T* getRef(int x, int y, int z) {
        return &data[positionToIndex(x, y, z)];
    }

    T* getRef(Vec3i position) {
        return &data[positionToIndex(position)];
    }

    const(T)* getRef(int x, int y, int z) const {
        return &data[positionToIndex(x, y, z)];
    }

    const(T)* getRef(Vec3i position) const {
        return &data[positionToIndex(position)];
    }

    ///! Danger zone.
    T* getIndexRef(int index) {
        return &data[index];
    }

    void set(int x, int y, int z, T newData) {
        data[positionToIndex(x, y, z)] = newData;
    }

    void set(Vec3i position, T newData) {
        data[positionToIndex(position)] = newData;
    }

    ///! Danger zone.
    void setIndex(int index, T newData) {
        data[index] = newData;
    }

    ulong getLength() const {
        return data.length;
    }

    /// Completely reset the underlying array.
    void reset() {
        this.data = this.data.init;
    }

    ///! This is extremely dangerous!
    T[xSize * ySize * zSize]* getDataArray() {
        return &data;
    }
}

unittest {
    // void blah() {
    import std.conv;
    import std.datetime;
    import std.random;
    import std.stdio;

    // foreach (pass; 0 .. 100) {
    auto rng = Random(unpredictableSeed());
    // This can take 0 for 1D or 2D, but that's dumb.
    // const int testX = uniform(1, 200, rng);
    // const int testY = uniform(1, 200, rng);
    // const int testZ = uniform(1, 200, rng);
    // const int testX = 67;
    // const int testY = 132;
    // const int testZ = 100;
    enum size = () {
        // Hack job to get 3 random integers at compile time.
        int seed = 0;
        foreach (char c; __TIMESTAMP__) {
            seed = (seed * 31) + c;
        }
        auto rngX = Random(seed);
        auto rngY = Random(seed + 31);
        auto rngZ = Random(seed + 62);
        return Vec3i(
            uniform(1, 200, rngX), uniform(1, 200, rngY), uniform(1, 200, rngZ)
        );
    }();
    //? Note: this container is one long piece of memory. It should be put on the heap unless you're using a small one!
    FlatContainer3D!(int, size.x, size.y, size.z)* database = new FlatContainer3D!(int, size.x, size.y, size
            .z)();
    writeln("[Note]: Unit test on FlatContainer3D requires a rebuild to randomize!");
    writeln("test: ", 1, " | size: ( ", size.x, ", ", size.y, ", ", size.z, " )");
    int realIndex = 0;
    int t = 0;
    foreach (x; 0 .. size.x) {
        foreach (z; 0 .. size.z) {
            foreach (y; 0 .. size.y) {
                t++;
                const Vec3i realPosition = Vec3i(x, y, z);
                const int calculatedIndex = database.positionToIndex(realPosition);
                const int calculatedIndexLiteral = database.positionToIndex(realPosition);
                assert(realIndex == calculatedIndex, i"Index not correct. Real: $(
                        realIndex) vs $(
                        calculatedIndex)".text);
                assert(realIndex == calculatedIndexLiteral);
                const Vec3i calculatedPosition = database.indexToPosition(realIndex);
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
    }
    // writeln("pass basic");
    // Next step is randomized position as a baseline.
    immutable int sampleSize = 500_000;
    foreach (_; 0 .. sampleSize) {
        const Vec3i realPosition = Vec3i(
            uniform(0, size.x, rng),
            uniform(0, size.y, rng),
            uniform(0, size.z, rng),
        );
        const calculatedIndex = database.positionToIndex(realPosition);
        const calculatedIndexRaw = database.positionToIndex(realPosition.x, realPosition.y, realPosition
                .z);
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
                reverseCalculatedIndex)) == database.positionToIndex(realPosition.x, realPosition.y, realPosition
                .z));
    }
    // }
    writeln("passed.");
}
