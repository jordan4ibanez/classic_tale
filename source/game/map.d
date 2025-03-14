module game.map;

public import math.aabb : CollisionAxis;
import fast_noise;
import game.biome_database;
import game.block_database;
import game.map_graphics;
import graphics.camera_handler;
import graphics.model_handler;
import graphics.render;
import graphics.texture_handler;
import math.aabb;
import math.rect;
import math.vec2d;
import math.vec2i;
import math.vec3d;
import math.vec3i;
import std.algorithm.comparison;
import std.bitmanip;
import std.conv;
import std.math.algebraic;
import std.math.rounding;
import std.random;
import std.stdio;
import utility.circular_buffer;
import utility.window;

// Width is for X and Z.
immutable public int CHUNK_WIDTH = 16;
immutable public int CHUNK_HEIGHT = 256;

pragma(inline, true)
private string generateKey(const ref Vec2i input) {
    return "Chunk:" ~ to!string(input.x) ~ "|" ~ to!string(input.y);
}

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
    // Y, Z, X
    BlockData[CHUNK_HEIGHT][CHUNK_WIDTH][CHUNK_WIDTH] data;
    // Z, X
    int[CHUNK_WIDTH][CHUNK_WIDTH] heightmap;

}

static final const class Map {
static:
private:

    Chunk[Vec2i] database;
    string[Vec2i] models;

    FNLState noise;
    // Vec2d[] debugDrawPoints = [];
    double gravity = 20.0;

public: //* BEGIN PUBLIC API.

    void initialize() {
        noise.seed = 1_010_010;
    }

    void setChunkModel(const ref Vec2i chunkID, const ulong modelKey) {
        Chunk* thisChunk = chunkID in database;

        if (thisChunk is null) {
            throw new Error("Tried to set a chunk that does not exist. " ~ to!string(chunkID));
        }

        thisChunk.modelKey = modelKey;
    }

    void draw() {
        // todo: this should probably order by distance. Lucky D has that built in. :D

        Vec3d position;

        foreach (const chunkPos, const ref thisChunk; database) {
            if (thisChunk.modelKey == 0) {
                continue;
            }

            position.x = chunkPos.x * CHUNK_WIDTH;
            position.z = chunkPos.y * CHUNK_WIDTH;

            const double maxX = position.x + CHUNK_WIDTH;
            const double maxY = position.y + CHUNK_HEIGHT;
            const double maxZ = position.z + CHUNK_WIDTH;

            if (CameraHandler.aabbInFrustum(position.x, position.y, position.z, maxX, maxY, maxZ)) {
                ModelHandler.drawDynamic(thisChunk.modelKey, position);
            }
        }
    }

    const(Chunk*) getChunkPointer(Vec2i key) {
        return key in database;
    }

    const(Chunk*) getChunkPointer(const int keyX, const int keyZ) {
        return Vec2i(keyX, keyZ) in database;
    }

    double getGravity() {
        return gravity;
    }

    int getTopAt(Vec3d position) {
        Vec2i chunkID = calculateChunkAtWorldPosition(position);
        Vec2i posInChunk = getXZInChunk(position);
        Chunk* thisChunk = chunkID in database;
        if (thisChunk is null) {
            return 0;
        }
        return thisChunk.heightmap[posInChunk.x][posInChunk.y];
    }

    int getTopAt(int x, int z) {
        Vec2i chunkID = calculateChunkAtWorldPosition(x, z);
        Vec2i posInChunk = getXZInChunk(x, z);
        Chunk* thisChunk = chunkID in database;
        if (thisChunk is null) {
            return 0;
        }
        return thisChunk.heightmap[posInChunk.x][posInChunk.y];
    }

    Vec2i calculateChunkAtWorldPosition(Vec3d position) {
        return Vec2i(
            cast(int) floor(position.x / CHUNK_WIDTH),
            cast(int) floor(position.z / CHUNK_WIDTH),
        );
    }

    Vec2i calculateChunkAtWorldPosition(double x, double z) {
        return Vec2i(
            cast(int) floor(x / CHUNK_WIDTH),
            cast(int) floor(z / CHUNK_WIDTH),
        );
    }

    Vec2i getXZInChunk(Vec3d position) {
        int x = cast(int) floor(position.x % CHUNK_WIDTH);
        int z = cast(int) floor(position.z % CHUNK_WIDTH);
        // Account for negatives.
        if (x < 0) {
            x += CHUNK_WIDTH;
        }
        if (z < 0) {
            z += CHUNK_WIDTH;
        }
        return Vec2i(x, z);
    }

    Vec2i getXZInChunk(int xInput, int zInput) {
        int x = xInput % CHUNK_WIDTH;
        int z = zInput % CHUNK_WIDTH;
        // Account for negatives.
        if (x < 0) {
            x += CHUNK_WIDTH;
        }
        if (z < 0) {
            z += CHUNK_WIDTH;
        }
        return Vec2i(x, z);
    }

    Vec2i getXZInChunk(double px, double pz) {
        int x = cast(int) floor(px % CHUNK_WIDTH);
        int z = cast(int) floor(pz % CHUNK_WIDTH);
        // Account for negatives.
        if (x < 0) {
            x += CHUNK_WIDTH;
        }
        if (z < 0) {
            z += CHUNK_WIDTH;
        }
        return Vec2i(x, z);
    }

    BlockData getBlockAtWorldPosition(int x, int y, int z) {
        Vec2i chunkID = calculateChunkAtWorldPosition(x, z);

        Chunk* thisChunk = chunkID in database;

        if (thisChunk is null) {
            return BlockData();
        }

        Vec2i xzPosInChunk = getXZInChunk(x, z);

        // Out of bounds.
        if (y < 0 || y >= CHUNK_HEIGHT) {
            // writeln("WARNING! trying to read out of bounds! " ~ to!string(y));
            return BlockData();
        }

        return thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][y];
    }

    BlockData* getBlockPointerAtWorldPosition(int x, int y, int z) {
        Vec2i chunkID = calculateChunkAtWorldPosition(x, z);

        Chunk* thisChunk = chunkID in database;

        if (thisChunk is null) {
            return null;
        }

        Vec2i xzPosInChunk = getXZInChunk(x, z);

        // Out of bounds.
        if (y < 0 || y >= CHUNK_HEIGHT) {
            // writeln("WARNING! trying to read out of bounds! " ~ to!string(y));
            return null;
        }

        return &thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][y];
    }

    BlockData* getBlockPointerAtWorldPosition(Vec3i position) {
        Vec2i chunkID = calculateChunkAtWorldPosition(position.x, position.z);

        Chunk* thisChunk = chunkID in database;

        if (thisChunk is null) {
            return null;
        }

        Vec2i xzPosInChunk = getXZInChunk(position.x, position.z);

        // Out of bounds.
        if (position.y < 0 || position.y >= CHUNK_HEIGHT) {
            // writeln("WARNING! trying to read out of bounds! " ~ to!string(position.y));
            return null;
        }

        return &thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][position.y];
    }

    void setBlockAtWorldPositionByID(Vec3d position, uint blockID) {
        if (!BlockDatabase.hasBlockID(blockID)) {
            throw new Error("Cannot set to block ID " ~ to!string(blockID) ~ ", ID does not exist.");
        }

        Vec2i chunkID = calculateChunkAtWorldPosition(position);

        Chunk* thisChunk = chunkID in database;

        if (thisChunk is null) {
            // todo: maybe unload the chunk after?
            // loadChunk(chunkID);
            // writeln("remember to load up chunks!");
            return;
        }

        Vec2i xzPosInChunk = getXZInChunk(position);

        int yPosInChunk = cast(int) floor(position.y);

        // Out of bounds.
        if (yPosInChunk < 0 || yPosInChunk >= CHUNK_HEIGHT) {
            // writeln("WARNING! trying to write out of bounds! " ~ to!string(yPosInChunk));
            return;
        }

        thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][yPosInChunk].blockID = blockID;

        updateHeightMap(thisChunk, xzPosInChunk.x, yPosInChunk, xzPosInChunk.y, blockID,
            cast(int) position.x, cast(int) position.z);

        cascadeNaturalLight(cast(int) floor(position.x), cast(int) floor(
                position.z));

        // This gets put into a HashSetQueue so it can keep doing it over and over.
        MapGraphics.generate(chunkID);
        updateAdjacentNeighborToPositionInChunk(chunkID, xzPosInChunk);
    }

    void setBlockAtWorldPositionByID(int x, int y, int z, uint blockID) {
        if (!BlockDatabase.hasBlockID(blockID)) {
            throw new Error("Cannot set to block ID " ~ to!string(blockID) ~ ", ID does not exist.");
        }

        Vec2i chunkID = calculateChunkAtWorldPosition(x, z);

        Chunk* thisChunk = chunkID in database;

        if (thisChunk is null) {
            // todo: maybe unload the chunk after?
            // loadChunk(chunkID);
            // writeln("remember to load up chunks!");
            return;
        }

        Vec2i xzPosInChunk = getXZInChunk(x, z);

        // Out of bounds.
        if (y < 0 || y >= CHUNK_HEIGHT) {
            writeln("WARNING! trying to write out of bounds! " ~ to!string(y));
            return;
        }

        thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][y].blockID = blockID;

        updateHeightMap(thisChunk, xzPosInChunk.x, y, xzPosInChunk.y, blockID, x, z);

        cascadeNaturalLight(x, z);

        // This gets put into a HashSetQueue so it can keep doing it over and over.
        MapGraphics.generate(chunkID);
        updateAdjacentNeighborToPositionInChunk(chunkID, xzPosInChunk);
    }

    void setBlockAtWorldPositionByName(Vec3d position, string name) {

        Vec2i chunkID = calculateChunkAtWorldPosition(position);

        Chunk* thisChunk = chunkID in database;

        if (thisChunk is null) {
            // todo: maybe unload the chunk after?
            // loadChunk(chunkID);
            // writeln("remember to load up chunks!");
            return;
        }

        Vec2i xzPosInChunk = getXZInChunk(position);

        int yPosInChunk = cast(int) floor(position.y);

        // Out of bounds.
        if (yPosInChunk < 0 || yPosInChunk >= CHUNK_HEIGHT) {
            writeln("WARNING! trying to write out of bounds! " ~ to!string(yPosInChunk));
            return;
        }

        const(BlockDefinition*) thisBlock = BlockDatabase.getBlockByName(name);

        if (thisBlock is null) {
            throw new Error("Cannot set to block " ~ name ~ ", does not exist.");
        }

        thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][yPosInChunk].blockID = thisBlock.blockID;

        updateHeightMap(thisChunk, xzPosInChunk.x, yPosInChunk, xzPosInChunk.y, thisBlock.blockID,
            cast(int) position.x, cast(int) position.z);

        cascadeNaturalLight(cast(int) floor(position.x), cast(int) floor(
                position.z));

        // This gets put into a HashSetQueue so it can keep doing it over and over.
        MapGraphics.generate(chunkID);
        updateAdjacentNeighborToPositionInChunk(chunkID, xzPosInChunk);
    }

    /// x y z inside of the chunk.
    void updateHeightMap(Chunk* thisChunk, int xInChunk, int yInChunk, int zInChunk, int newID,
        int worldPositionX, int worldPositionZ) {

        const(BlockDefinition*) ultraFastBlockDatabaseAccess = BlockDatabase.getUltraFastAccess();

        const int height = thisChunk.heightmap[xInChunk][zInChunk];
        // ID was set to air. (removed/dug)
        if (newID == 0) {
            // If it was the top, have to scan down.
            //? Note: Subtractive update. Slightly more expensive. Has to scan down.
            if (height == yInChunk) {

                bool found = false;
                foreach_reverse (yScan; 0 .. yInChunk + 1) {

                    BlockData* thisBlock = &thisChunk.data[xInChunk][zInChunk][yScan];

                    // Mark new heightmap height.
                    if (!found && thisBlock.blockID != 0) {
                        thisChunk.heightmap[xInChunk][zInChunk] = yScan;
                        found = true;
                    }

                    // Cascade downwards direct sunlight until solid (non propagating) block found.
                    // This is used as a light source for calculating natural light cascade.
                    if ((ultraFastBlockDatabaseAccess + thisBlock.blockID).lightPropagates) {
                        thisBlock.isSunlight = true;
                    } else {
                        writeln((ultraFastBlockDatabaseAccess + thisBlock.blockID).name);
                        break;
                    }
                }
            }

            // This is a Y striping non-update fix. 0, 1, 0 1 -> top. If this is not triggered it will leave outdated lights.
            return cascadeNaturalLight(worldPositionX, worldPositionZ);
        }  // todo: set this to check block definition database for replaceable or airlike, not too sure how this should be handled with complex block types.
        // Else it was set to not air.
        else {
            // If it's taller, it's the top.
            // This portion of the heightmap has shifted up.
            //? Note: Additive update.
            if (yInChunk > height) {

                thisChunk.heightmap[xInChunk][zInChunk] = yInChunk;

                const BlockData* thisBlock = &thisChunk.data[xInChunk][zInChunk][yInChunk];

                // If light propagates, the blocks below are still under sunlight.
                if (!(ultraFastBlockDatabaseAccess + thisBlock.blockID).lightPropagates) {
                    foreach (yScan; height .. yInChunk) {
                        thisChunk.data[xInChunk][zInChunk][yScan].isSunlight = false;
                    }
                }
            }
        }
    }

    const ubyte LIGHT_LEVEL_MAX = 15;

    private static immutable BOUNDARY_BOX_MAX = ((LIGHT_LEVEL_MAX + 1) * 2) + 1;

    private struct MazeElement {
        bool isAir = false;
        ubyte naturalLightLevel = 0;
        ubyte artificialLightLevel = 0;

        // mixin(bitfields!(
        //         bool, "isAir", 1,
        //         ubyte, "naturalLightLevel", 4,
        //         ubyte, "artificialLightLevel", 4,
        //         bool, "", 7
        // ));
    }

    private struct LightTraversalNode {
        int x = 0;
        int y = 0;
        int z = 0;
        ubyte naturalLightLevel = 0;
        ubyte artificialLightLevel = 0;
    }

    // Y Z X
    private static MazeElement[CHUNK_HEIGHT][BOUNDARY_BOX_MAX][BOUNDARY_BOX_MAX] lightPool;
    private static Chunk*[3][3] chunkPointers;
    private static CircularBuffer!Vec3i sourceQueue;
    private static CircularBuffer!LightTraversalNode cascadeQueue;
    private static int[BOUNDARY_BOX_MAX][BOUNDARY_BOX_MAX] cacheHeightMap;

    // todo: ?MAYBE? accumulate the x and z min and max and reallocate this to utilize the box of that + max light level to do it in one shot.

    void cascadeNaturalLight(int xInWorld, int zInWorld) {
        // import std.container;
        import std.datetime.stopwatch;
        import std.math.algebraic;

        // import utility.queue;

        if (!sourceQueue.initialized) {
            // ~2.1 MB.
            sourceQueue = CircularBuffer!(Vec3i)(10_000);
            cascadeQueue = CircularBuffer!(LightTraversalNode)(150_000);
        }

        static const minW = -(LIGHT_LEVEL_MAX + 1);
        static const maxW = LIGHT_LEVEL_MAX + 1;

        auto sw = StopWatch(AutoStart.yes);

        // Pointer caching.

        const int _xMin = xInWorld + minW;
        const int _xMax = xInWorld + maxW;
        const int _zMin = zInWorld + minW;
        const int _zMax = zInWorld + maxW;

        const int minChunkX = (_xMin < 0) ? (((_xMin + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
            _xMin / CHUNK_WIDTH);
        const int maxChunkX = (_xMax < 0) ? (((_xMax + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
            _xMax / CHUNK_WIDTH);
        const int minChunkZ = (_zMin < 0) ? (((_zMin + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
            _zMin / CHUNK_WIDTH);
        const int maxChunkZ = (_zMax < 0) ? (((_zMax + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
            _zMax / CHUNK_WIDTH);

        // The max it can be is 3x3 wide.
        //? This is scoped on purpose.
        {
            Vec2i cacheKey;
            foreach (x; minChunkX .. maxChunkX + 1) {
                foreach (z; minChunkZ .. maxChunkZ + 1) {
                    cacheKey.x = x;
                    cacheKey.y = z;
                    chunkPointers[x - minChunkX][z - minChunkZ] = cacheKey in database;
                }
            }
        }

        // This is an extreme micro optimization.
        // The "shell" of the update is never mutated.
        // In certain scenarios this would have created a few extra
        // mesh updates. This stops that.
        //? This is scoped on purpose.
        {

            const int _xMinUpdate = xInWorld + minW;
            const int _xMaxUpdate = xInWorld + maxW;
            const int _zMinUpdate = zInWorld + minW;
            const int _zMaxUpdate = zInWorld + maxW;

            const int updateMinChunkX = (_xMinUpdate < 0) ? (
                ((_xMinUpdate + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
                _xMinUpdate / CHUNK_WIDTH);
            const int updateMaxChunkX = (_xMaxUpdate < 0) ? (
                ((_xMaxUpdate + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
                _xMaxUpdate / CHUNK_WIDTH);
            const int updateMinChunkZ = (_zMinUpdate < 0) ? (
                ((_zMinUpdate + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
                _zMinUpdate / CHUNK_WIDTH);
            const int updateMaxChunkZ = (_zMaxUpdate < 0) ? (
                ((_zMaxUpdate + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
                _zMaxUpdate / CHUNK_WIDTH);

            Vec2i cacheKey;
            foreach (x; updateMinChunkX .. updateMaxChunkX + 1) {
                foreach (z; updateMinChunkZ .. updateMaxChunkZ + 1) {
                    cacheKey.x = x;
                    cacheKey.y = z;
                    MapGraphics.generate(cacheKey);
                }
            }
        }

        const(BlockDefinition*) ultraFastBlockDatabaseAccess = BlockDatabase.getUltraFastAccess();

        // Search for light propogation blocks. Binary. Lightsource or darkness.
        // This is shifting the whole world position into the box position.
        // Accumulating the light data so that the world does not need the be checked again.
        Vec3i cacheVec3i;
        BlockData* currentBlockPointer;
        foreach (const xRaw; minW .. maxW + 1) {
            const int xInBox = xRaw + LIGHT_LEVEL_MAX + 1;
            const int xWorldLocal = xInWorld + xRaw;

            const int chunkXInCache = ((xWorldLocal < 0) ? (
                    ((xWorldLocal + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
                    xWorldLocal / CHUNK_WIDTH)) - minChunkX;

            const int ___doNotUseXRawInChunk = (xWorldLocal % CHUNK_WIDTH);
            const int xInChunkPointer = (___doNotUseXRawInChunk < 0) ? (
                ___doNotUseXRawInChunk + CHUNK_WIDTH) : ___doNotUseXRawInChunk;

            foreach (const zRaw; minW .. maxW + 1) {
                const int zInBox = zRaw + LIGHT_LEVEL_MAX + 1;
                const int zWorldLocal = zInWorld + zRaw;

                const int chunkZInCache = ((zWorldLocal < 0) ? (
                        ((zWorldLocal + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
                        zWorldLocal / CHUNK_WIDTH)) - minChunkZ;

                const int ___doNotUseZRawInChunk = (zWorldLocal % CHUNK_WIDTH);
                const int zInChunkPointer = (___doNotUseZRawInChunk < 0) ? (
                    ___doNotUseZRawInChunk + CHUNK_WIDTH) : ___doNotUseZRawInChunk;

                //? This is a double check.
                // auto res = calculateChunkAtWorldPosition(cast(double) xWorldLocal, cast(double) zWorldLocal);
                // assert(res.x - minChunkX == chunkXInCache && res.y - minChunkZ == chunkZInCache);
                // assert(chunkXInCache >= 0 && chunkZInCache >= 0 && chunkXInCache <= 2 && chunkZInCache <= 2);
                // auto cz = getXZInChunk(xWorldLocal, zWorldLocal);
                // assert(xInChunkPointer == cz.x && zInChunkPointer == cz.y);

                Chunk* thisChunk = chunkPointers[chunkXInCache][chunkZInCache];

                // Find the highest point on this X and Z position that touches a neighbor block.
                //? This is an extreme and aggressive optimization that will have less of an effect if you
                //? build a huge castle which takes up the entire chunk.
                //! If you can think of a better way to do this, I would be happy to hear about it. :D

                static const Vec2i[4] DIRECTIONS = [
                    Vec2i(-1, 0),
                    Vec2i(1, 0),
                    Vec2i(0, -1),
                    Vec2i(0, 1)
                ];
                int highPoint = 0;

                foreach (dir; DIRECTIONS) {

                    const int localX = xWorldLocal + dir.x;
                    const int localZ = zWorldLocal + dir.y;

                    // Trying to step out of bounds.
                    if (localX > _xMax || localX < _xMin ||
                        localZ > _zMax || localZ < _zMin) {
                        // writeln("out of bounds");
                        continue;
                    }

                    //? Getting which chunk pointer to use.

                    const int xChunkInCacheHeightmap = ((localX < 0) ? (
                            ((localX + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
                            localX / CHUNK_WIDTH)) - minChunkX;

                    const int zChunkInCacheHeightmap = ((localZ < 0) ? (
                            ((localZ + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
                            localZ / CHUNK_WIDTH)) - minChunkZ;

                    //? Getting the X and Z inside this chunk.

                    const int __tempX = (localX % CHUNK_WIDTH);
                    const int thisXInsideChunkLocal = (__tempX < 0) ? (
                        __tempX + CHUNK_WIDTH) : __tempX;

                    const int __tempZ = (localZ % CHUNK_WIDTH);
                    const int thisZInsideChunkLocal = (__tempZ < 0) ? (
                        __tempZ + CHUNK_WIDTH) : __tempZ;

                    const Chunk* neighborBlockChunk = chunkPointers[xChunkInCacheHeightmap][zChunkInCacheHeightmap];

                    // Can't get data that does not exist.
                    if (neighborBlockChunk is null) {
                        continue;
                    }

                    // +1 to allow the light to flow over the block. Basically, make it so you can see the top of blocks.
                    // The other +1 is because the foreach is exclusive. (subtracts 1)
                    const int neighborTop = neighborBlockChunk
                        .heightmap[thisXInsideChunkLocal][thisZInsideChunkLocal] + 2;

                    if (neighborTop > highPoint) {
                        highPoint = neighborTop;
                    }
                }

                cacheHeightMap[xInBox][zInBox] = highPoint;

                foreach (const yRaw; 0 .. highPoint) {

                    MazeElement* elementPointer = &lightPool[xInBox][zInBox][yRaw];

                    // Do not do corners.
                    // if ((xRaw == minW || xRaw == maxW - 1) &&
                    //     (zRaw == minW || zRaw == maxW - 1) &&
                    //     (yRaw == 0 || yRaw == (CHUNK_HEIGHT - 1))) {
                    //     elementPointer.isAir = false;
                    //     continue;
                    // }

                    // Do not bother if the block is direct sunlight aka above the height map.
                    //! do not enable.
                    // It already has max light level applied.
                    // if (yRaw > getTopAt(xWorldLocal, zWorldLocal)) {
                    //     lightPool[xInBox][zInBox][yRaw].isAir = false;
                    //     continue;
                    // }

                    currentBlockPointer = &thisChunk
                        .data[xInChunkPointer][zInChunkPointer][yRaw];

                    const BlockDefinition* thisDefinition = ultraFastBlockDatabaseAccess + currentBlockPointer
                        .blockID;

                    // Initial binary application.
                    if (thisDefinition.lightPropagates) {

                        // The walls are all light sources or else we'd infinitely be checking the world. Must assume their data is correct.
                        if ((xRaw == minW || xRaw == maxW - 1) ||
                            (zRaw == minW || zRaw == maxW - 1) ||
                            (yRaw == 0 || yRaw == (CHUNK_HEIGHT - 1))) {

                            elementPointer.naturalLightLevel = currentBlockPointer.naturalLightBank;
                            elementPointer.artificialLightLevel = currentBlockPointer
                                .artificialLightBank;
                            elementPointer.isAir = true;

                            cacheVec3i.x = xInBox;
                            cacheVec3i.y = yRaw;
                            cacheVec3i.z = zInBox;

                            sourceQueue.put(cacheVec3i);

                        } else {

                            // This is in the "core" of the box. Can be treated as normal cascade data.

                            const bool isSunlight = currentBlockPointer.isSunlight;

                            const bool isArtificialLightSource = thisDefinition.isLightSource;

                            elementPointer.naturalLightLevel = (isSunlight) ? LIGHT_LEVEL_MAX : 0;

                            elementPointer.artificialLightLevel = (isArtificialLightSource) ? thisDefinition
                                .lightSourceLevel : 0;

                            //? Anything that propagates light "is air" as far as this algorithm is concerned.
                            elementPointer.isAir = true;

                            if (isSunlight) {
                                cacheVec3i.x = xInBox;
                                cacheVec3i.y = yRaw;
                                cacheVec3i.z = zInBox;

                                sourceQueue.put(cacheVec3i);
                            }
                        }
                    } else {
                        elementPointer.isAir = false;
                    }
                }
            }
        }

        const static Vec3i[6] DIRECTIONS = [
            Vec3i(-1, 0, 0),
            Vec3i(1, 0, 0),
            Vec3i(0, -1, 0),
            Vec3i(0, 1, 0),
            Vec3i(0, 0, -1),
            Vec3i(0, 0, 1),
        ];

        //? This is now working within the space of the box.

        // Option!Vec3i sourceResult;
        Vec3i* thisSource;
        LightTraversalNode* thisNode;

        uint count = 0;

        LightTraversalNode cacheTraversalNode;

        SOURCE_LOOP: while (true) {

            // Reached the end of sources.
            if (sourceQueue.empty()) {
                break SOURCE_LOOP;
            }

            //? INITIALIZE CASCADE.
            thisSource = sourceQueue.front();
            sourceQueue.popFront();

            // Start by pushing this light level in.
            cacheTraversalNode.x = thisSource.x;
            cacheTraversalNode.y = thisSource.y;
            cacheTraversalNode.z = thisSource.z;
            cacheTraversalNode.naturalLightLevel = lightPool[thisSource.x][thisSource.z][thisSource
                    .y].naturalLightLevel;

            cacheTraversalNode.artificialLightLevel = lightPool[thisSource.x][thisSource.z][thisSource
                    .y].artificialLightLevel;

            cascadeQueue.put(cacheTraversalNode);

            CASCADE_LOOP: while (true) {

                // Reached the end of this source spread.
                if (cascadeQueue.empty()) {
                    break CASCADE_LOOP;
                }
                count++;

                thisNode = cascadeQueue.front();
                cascadeQueue.popFront();

                // Don't even bother. It'll spread 0.
                if (thisNode.naturalLightLevel <= 1 && thisNode.artificialLightLevel <= 1) {
                    continue CASCADE_LOOP;
                }

                const ubyte downStreamNaturalLightLevel = cast(ubyte)(thisNode.naturalLightLevel - 1);
                const ubyte downStreamArtificialLightLevel = cast(ubyte)(
                    thisNode.artificialLightLevel - 1);

                MazeElement* lookingAtNeighbor;

                DIRECTION_LOOP: foreach (dir; DIRECTIONS) {

                    const int newPosX = thisNode.x + dir.x;
                    const int newPosY = thisNode.y + dir.y;
                    const int newPosZ = thisNode.z + dir.z;

                    // Trying to step out of bounds.
                    //? Also, do not attempt to modify the edges of the box.
                    if (newPosX >= BOUNDARY_BOX_MAX - 1 || newPosX < 1 ||
                        newPosZ >= BOUNDARY_BOX_MAX - 1 || newPosZ < 1 ||
                        newPosY >= CHUNK_HEIGHT || newPosY < 0) {
                        continue DIRECTION_LOOP;
                    }

                    lookingAtNeighbor = &lightPool[newPosX][newPosZ][newPosY];

                    // In non-air. Which light cannot spread to.
                    if (!lookingAtNeighbor.isAir) {
                        continue DIRECTION_LOOP;
                    }

                    // This is already a light source. Or is already at the level it would spread to. Don't need to cascade.
                    if (
                        lookingAtNeighbor.naturalLightLevel >= downStreamNaturalLightLevel
                        && lookingAtNeighbor.artificialLightLevel >=
                        downStreamArtificialLightLevel) {
                        continue DIRECTION_LOOP;
                    }

                    // Everything checks out. Spread light.
                    //! Never else this. It can be both.

                    lookingAtNeighbor.naturalLightLevel = downStreamNaturalLightLevel;

                    cacheTraversalNode.x = newPosX;
                    cacheTraversalNode.y = newPosY;
                    cacheTraversalNode.z = newPosZ;
                    cacheTraversalNode.naturalLightLevel = downStreamNaturalLightLevel;

                    cascadeQueue.put(cacheTraversalNode);
                }
            }
        }

        //? This is kept so if the buffer is ever overflowed it can be tested and retuned.
        // writeln("count:", count);

        //? Now, write back the data into the chunk pointers.
        //? Notice: Not writing the edges. They are not modified.
        //! NOTE: DO NOT +1 THE MAXW!

        foreach (xRaw; (minW + 1) .. maxW) {

            const int xInBox = xRaw + LIGHT_LEVEL_MAX + 1;
            const int xWorldLocal = xInWorld + xRaw;

            const int chunkXInCache = ((xWorldLocal < 0) ? (
                    ((xWorldLocal + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
                    xWorldLocal / CHUNK_WIDTH)) - minChunkX;

            const int ___doNotUseXRawInChunk = (xWorldLocal % CHUNK_WIDTH);
            const int xInChunkPointer = (___doNotUseXRawInChunk < 0) ? (
                ___doNotUseXRawInChunk + CHUNK_WIDTH) : ___doNotUseXRawInChunk;

            foreach (zRaw; (minW + 1) .. maxW) {

                const int zInBox = zRaw + LIGHT_LEVEL_MAX + 1;
                const int zWorldLocal = zInWorld + zRaw;

                const int chunkZInCache = ((zWorldLocal < 0) ? (
                        ((zWorldLocal + 1) - CHUNK_WIDTH) / CHUNK_WIDTH) : (
                        zWorldLocal / CHUNK_WIDTH)) - minChunkZ;

                const int ___doNotUseZRawInChunk = (zWorldLocal % CHUNK_WIDTH);
                const int zInChunkPointer = (___doNotUseZRawInChunk < 0) ? (
                    ___doNotUseZRawInChunk + CHUNK_WIDTH) : ___doNotUseZRawInChunk;

                const int highPoint = cacheHeightMap[xInBox][zInBox];

                Chunk* thisChunk = chunkPointers[chunkXInCache][chunkZInCache];

                foreach (yRaw; 0 .. highPoint) {
                    thisChunk.data[xInChunkPointer][zInChunkPointer][yRaw].naturalLightBank =
                        lightPool[xInBox][zInBox][yRaw].naturalLightLevel;
                }
            }
        }

        writeln("took: ", sw.peek().total!"usecs", "us");
    }

    void worldLoad(Vec2i currentPlayerChunk) {
        foreach (x; currentPlayerChunk.x - 1 .. currentPlayerChunk.x + 2) {
            foreach (z; currentPlayerChunk.y - 1 .. currentPlayerChunk.y + 2) {
                writeln("loading chunk ", x, ",", z); // loadChunk(i);
            }
        }

        // This can get very laggy if old chunks are not unloaded. :)
        unloadOldChunks(currentPlayerChunk);
    }

    bool collideEntityToWorld(ref Vec3d entityPosition, const ref Vec2d entitySize, ref Vec3d entityVelocity,
        CollisionAxis axis) {

        return collision(entityPosition, entitySize, entityVelocity, axis);
    }

    void debugGenerate(int x, int z) {
        loadChunk(Vec2i(x, z));
    }

private: //* BEGIN INTERNAL API.

    void unloadOldChunks(Vec2i currentPlayerChunk) {

        // todo: save the chunks to mongoDB.

        // todo: what IS THIS MESS?!
        Vec2i[] keys = [] ~ database.keys;
        foreach (Vec2i key; keys) {
            // Todo: make this render distance instead of 1.
            if (abs(key.x - currentPlayerChunk.x) > 1 || abs(
                    key.y - currentPlayerChunk.y) > 1) {
                database.remove(key); // todo: save the chunks to sqlite.
                writeln("deleted: " ~ to!string(key));
            }
        }
    }

    void loadChunk(Vec2i chunkPosition) {
        // Already loaded.
        if (chunkPosition in database) {
            return;
        }
        // todo: try to read from mongoDB.
        Chunk newChunk = Chunk();
        generateChunkData(chunkPosition, newChunk);
        database[chunkPosition] = newChunk;
        MapGraphics.generate(
            chunkPosition);
        updateAllNeighbors(chunkPosition);
    }

    // This is only used when generating a new chunk.
    void updateAllNeighbors(Vec2i chunkKey) {
        const Vec2i left = Vec2i(chunkKey.x - 1, chunkKey.y);
        const Vec2i right = Vec2i(chunkKey.x + 1, chunkKey.y);
        const Vec2i front = Vec2i(chunkKey.x, chunkKey.y - 1);
        const Vec2i back = Vec2i(chunkKey.x, chunkKey.y + 1);
        if (left in database) {
            MapGraphics.generate(left);
        }
        if (right in database) {
            MapGraphics.generate(right);
        }
        if (front in database) {
            MapGraphics.generate(front);
        }
        if (back in database) {
            MapGraphics.generate(back);
        }
    }

    // I named this like this so it's very obvious when it's used.
    void updateAdjacentNeighborToPositionInChunk(const ref Vec2i chunkKey, const ref Vec2i xzPosInChunk) {
        if (xzPosInChunk.x == 0) {
            const Vec2i left = Vec2i(chunkKey.x - 1, chunkKey
                    .y);
            if (left in database) {
                MapGraphics.generate(left);
            }
        } else if (xzPosInChunk.x == CHUNK_WIDTH - 1) {
            const Vec2i right = Vec2i(chunkKey.x + 1, chunkKey
                    .y);
            if (right in database) {
                MapGraphics.generate(right);
            }
        }

        if (xzPosInChunk.y == 0) {
            const Vec2i front = Vec2i(chunkKey.x, chunkKey.y - 1);
            if (front in database) {
                MapGraphics.generate(front);
            }
        } else if (xzPosInChunk.y == CHUNK_WIDTH - 1) {
            const Vec2i back = Vec2i(chunkKey.x, chunkKey.y + 1);
            if (back in database) {
                MapGraphics.generate(back);
            }
        }
    }

    void generateChunkData(Vec2i chunkPosition, ref Chunk thisChunk) {

        // todo: the chunk should have a biome.
        const(BiomeDefinition*) thisBiome = BiomeDatabase.getBiomeByID(
            0);
        if (thisBiome is null) {
            import std.conv;

            throw new Error("Attempted to get biome " ~ to!string(
                    0) ~ " which does not exist");
        }

        const double baseHeight = 160;

        const int basePositionX = chunkPosition.x * CHUNK_WIDTH;
        const int basePositionZ = chunkPosition.y * CHUNK_WIDTH;

        const(BlockDefinition*) bedrock = BlockDatabase.getBlockByName(
            "bedrock");
        if (bedrock is null) {
            throw new Error(
                "Please do not remove bedrock from the engine.");
        }

        const(BlockDefinition*) stone = BlockDatabase.getBlockByID(
            thisBiome.stoneLayerID);
        if (stone is null) {
            throw new Error(
                "Stone does not exist for biome " ~ thisBiome
                    .name);
        }

        const(BlockDefinition*) dirt = BlockDatabase.getBlockByID(
            thisBiome.dirtLayerID);
        if (dirt is null) {
            throw new Error(
                "Dirt does not exist for biome " ~ thisBiome
                    .name);
        }

        const(BlockDefinition*) grass = BlockDatabase
            .getBlockByID(
                thisBiome.grassLayerID);
        if (grass is null) {
            throw new Error(
                "Grass does not exist for biome " ~ thisBiome
                    .name);
        }

        foreach (x; 0 .. CHUNK_WIDTH) {
            foreach (z; 0 .. CHUNK_WIDTH) {

                const double selectedNoise = fnlGetNoise2D(
                    &noise, x + basePositionX, z + basePositionZ);

                const double noiseScale = 20;

                const int selectedHeight = cast(
                    int) floor(
                    baseHeight + (
                        selectedNoise * noiseScale));

                const int grassLayer = selectedHeight;
                const int dirtLayer = selectedHeight - 3;

                const double bedRockNoise = fnlGetNoise2D(
                    &noise, (x + basePositionX) * 12, (
                        z + basePositionZ) * 12) * 2;
                const int bedRockSelectedHeight = cast(
                    int) round(
                    abs(bedRockNoise));

                thisChunk.heightmap[x][z] = grassLayer;

                foreach (y; 0 .. CHUNK_HEIGHT) {

                    if (
                        y > selectedHeight) {
                        thisChunk.data[x][z][y]
                            .naturalLightBank = 15;
                        thisChunk.data[x][z][y].isSunlight = true;
                    } else {
                        if (y == 0) {
                            thisChunk.data[x][z][y].blockID = bedrock.blockID;
                        } else if (
                            y <= 2) {
                            if (
                                y <= bedRockSelectedHeight) {
                                thisChunk.data[x][z][y].blockID = bedrock.blockID;
                            } else {
                                thisChunk.data[x][z][y].blockID = stone.blockID;
                            }
                        } else if (
                            y < dirtLayer) {
                            thisChunk.data[x][z][y].blockID = stone.blockID;
                        } else if (
                            y < grassLayer) {
                            thisChunk.data[x][z][y].blockID = dirt.blockID;
                        } else if (
                            y == grassLayer) {
                            thisChunk.data[x][z][y].blockID = grass.blockID;
                        }
                    }
                }
            }
        }
    }

    bool collision(ref Vec3d entityPosition, Vec2d entitySize, ref Vec3d entityVelocity, CollisionAxis axis) {

        int oldX = int.min;
        int oldY = int.min;
        int oldZ = int.min;

        int currentX = int.min;
        int currentY = int.min;
        int currentZ = int.min;

        bool hitGround = false;

        // Entity position is on the bottom center of the collisionbox.
        const double entityHalfWidth = entitySize.x * 0.5;

        foreach (double xOnRect; 0 .. ceil(entitySize.x) + 1) {
            double thisXPoint = (
                xOnRect > entitySize.x) ? entitySize.x : xOnRect;
            thisXPoint += entityPosition.x - entityHalfWidth;
            oldX = currentX;
            currentX = cast(int) floor(
                thisXPoint);

            foreach (double zOnRect; 0 .. ceil(entitySize.x) + 1) {
                double thisZPoint = (
                    zOnRect > entitySize
                        .x) ? entitySize.x : zOnRect;
                thisZPoint += entityPosition.z - entityHalfWidth;
                oldZ = currentZ;
                currentZ = cast(int) floor(
                    thisZPoint);

                foreach (
                    double yOnRect; 0 .. ceil(
                        entitySize.y) + 1) {
                    double thisYPoint = (
                        yOnRect > entitySize
                            .y) ? entitySize.y : yOnRect;
                    thisYPoint += entityPosition
                        .y;
                    oldY = currentY;
                    currentY = cast(
                        int) floor(
                        thisYPoint);

                    if (
                        currentY == oldY) {
                        continue;
                    }

                    // debugDrawPoints ~= Vec2d(currentX, currentY);

                    BlockData data = getBlockAtWorldPosition(cast(int) floor(thisXPoint), cast(int) floor(
                            thisYPoint), cast(int) floor(thisZPoint));

                    // todo: if solid block collide.
                    // todo: probably custom blocks one day.

                    // import raylib;

                    // These are literal positions in 3D space.
                    // DrawSphere(Vector3(thisXPoint, thisYPoint, thisZPoint), 0.01, Colors.ORANGE);

                    // These are floored, it will look completely wrong.
                    // I assure you it is correct.
                    // DrawSphere(Vector3(currentX, currentY, currentZ), 0.01, Colors.BLUE);

                    if (
                        data.blockID == 0) {
                        continue;
                    }

                    // todo: this needs to iterate through the block sizes on custom blocks.
                    final switch (
                            axis) {
                    case CollisionAxis.X:

                        Vec3d blockMin = Vec3d(currentX, currentY, currentZ);
                        Vec3d blockMax = Vec3d(
                            currentX + 1, currentY + 1, currentZ + 1);

                        // import raylib;

                        // DrawCube(blockMin.toRaylib(), 0.1, 0.1, 0.1, Colors.DARKPURPLE);

                        CollisionResult result = collideEntityToBlock(
                            entityPosition, entitySize, entityVelocity,
                            blockMin, blockMax, axis);

                        if (
                            result
                            .collides) {
                            entityPosition.x = result
                                .newPosition;
                            entityVelocity.x = 0;
                        }

                        break;
                    case CollisionAxis.Y:
                        // writeln("Y ");

                        Vec3d blockMin = Vec3d(currentX, currentY, currentZ);
                        Vec3d blockMax = Vec3d(
                            currentX + 1, currentY + 1, currentZ + 1);

                        // import raylib;

                        // DrawCube(blockMin.toRaylib(), 0.1, 0.1, 0.1, Colors.DARKPURPLE);

                        CollisionResult result = collideEntityToBlock(
                            entityPosition, entitySize, entityVelocity,
                            blockMin, blockMax, axis);

                        if (
                            result
                            .collides) {
                            entityPosition.y = result
                                .newPosition;
                            entityVelocity.y = 0;
                            hitGround = result
                                .hitGround;
                        }
                        break;
                    case CollisionAxis.Z:

                        Vec3d blockMin = Vec3d(currentX, currentY, currentZ);
                        Vec3d blockMax = Vec3d(
                            currentX + 1, currentY + 1, currentZ + 1);

                        // import raylib;

                        // DrawCube(blockMin.toRaylib(), 0.1, 0.1, 0.1, Colors.DARKPURPLE);

                        CollisionResult result = collideEntityToBlock(
                            entityPosition, entitySize, entityVelocity,
                            blockMin, blockMax, axis);

                        if (
                            result
                            .collides) {
                            entityPosition.z = result
                                .newPosition;
                            entityVelocity.z = 0;
                        }

                        break;
                    }
                }
            }
        }

        return hitGround;
    }

}
