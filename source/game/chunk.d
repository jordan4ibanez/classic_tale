module game.chunk;

import math.vec3i;

// Width is for X and Z.
immutable public int CHUNK_WIDTH = 16;
immutable public int CHUNK_HEIGHT = 256;

immutable public int CHUNK_STRIDE = CHUNK_WIDTH * CHUNK_HEIGHT;

/// Get a position from an index in a chunk.
public Vec3i indexToPosition(int index) {
    return Vec3i(
        index / CHUNK_STRIDE,
        (index % CHUNK_HEIGHT),
        (index % CHUNK_STRIDE) / CHUNK_HEIGHT
    );
}

/// Get an index from a position within a chunk.
pragma(inline, true)
public int positionToIndex(Vec3i position) {
    return (position.x * CHUNK_STRIDE) + (position.z * CHUNK_HEIGHT) + position.y;
}

/// Get an index from a position within a chunk.
pragma(inline, true)
public int positionToIndex(int positionX, int positionY, int positionZ) {
    return (positionX * CHUNK_STRIDE) + (positionZ * CHUNK_HEIGHT) + positionY;
}

// Maybe this shouldn't be in here but it's part of a chunk so it's here for now.
struct BlockData {
    uint blockID = 0;
    // Uses banked lighting. 
    //~ The banked lighting is blended together in the shader.
    //? Sun light (and moon light). Basically exposed to open sky straight upwards.
    ubyte naturalLightBank = 0;
    //? Artificial light sources like torches or camp fire.
    ubyte artificialLightBank = 0;
    bool isSunlight = false;
}

struct Chunk {
    ulong modelKey = 0;

    BlockData[CHUNK_HEIGHT * CHUNK_WIDTH * CHUNK_WIDTH] data;

    // todo: these need to be 1D.
    // Z, X
    int[CHUNK_WIDTH][CHUNK_WIDTH] heightmap;
}

//? 3D
/*
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
*/

//? 2D

// pragma(inline, true)
// Vec2i indexToPosition(int index) const {
//     return Vec2i(
//         // index / (_y * _z),
//         (index % (xSize * ySize)) / ySize, //_x used to be _z 
//         (index % ySize),
//     );
// }

// pragma(inline, true)
// int positionToIndex(int xPos, int yPos) const {
//     return  /*(xPos * (_z * _y)) +*/ (xPos * ySize) + yPos; // xPos used to be zPos
// }

// pragma(inline, true)
// int positionToIndex(Vec2i position) const {
//     return positionToIndex(position.x, position.y);
// }
