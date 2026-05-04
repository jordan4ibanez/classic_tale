module game.light;

import game.block_database;
import game.chunk;
import game.map;
import game.map_graphics;
import math.vec2i;
import math.vec3i;
import std.bitmanip;
import std.stdio;
import utility.circular_buffer;

private struct MazeElement {
    // bool isAir = false;
    // ubyte naturalLightLevel = 0;
    // ubyte artificialLightLevel = 0;
    mixin(bitfields!(
            bool, "isAir", 1,
            ubyte, "naturalLightLevel", 4,
            ubyte, "artificialLightLevel", 4,
            bool, "", 7
    ));
}

private struct LightTraversalNode {
    // int x = 0;
    // int y = 0;
    // int z = 0;
    // ubyte naturalLightLevel = 0;
    // ubyte artificialLightLevel = 0;

    mixin(bitfields!(
            int, "x", 16,
            int, "y", 16,
            int, "z", 16,
            ubyte, "naturalLightLevel", 4,
            ubyte, "artificialLightLevel", 4,
            bool, "", 8
    ));
}

static final const class Light {
static:
private:

    immutable BOUNDARY_BOX_MAX = ((LIGHT_LEVEL_MAX + 1) * 2) + 1;
    immutable minW = -(LIGHT_LEVEL_MAX + 1);
    immutable maxW = LIGHT_LEVEL_MAX + 1;

    float globalAmbientLightLevel = 1.0;
    int ambientLightLevelUniformLocation = -1000;

    immutable Vec2i[4] CHUNK_DIRECTIONS = [
        Vec2i(-1, 0),
        Vec2i(1, 0),
        Vec2i(0, -1),
        Vec2i(0, 1)
    ];

    // Y Z X
    MazeElement[CHUNK_HEIGHT][BOUNDARY_BOX_MAX][BOUNDARY_BOX_MAX] lightPool;
    Chunk*[3][3] chunkPointers;
    CircularBuffer!Vec3i sourceQueue;
    CircularBuffer!LightTraversalNode cascadeQueue;
    int[BOUNDARY_BOX_MAX][BOUNDARY_BOX_MAX] cacheHeightMap;

    // todo: ?MAYBE? accumulate the x and z min and max and reallocate this to utilize the box of that + max light level to do it in one shot.

    static this() {
        // ~2.1 MB.
        sourceQueue = CircularBuffer!(Vec3i)(10_000);
        cascadeQueue = CircularBuffer!(LightTraversalNode)(150_000);
    }

public:

    immutable ubyte LIGHT_LEVEL_MAX = 15;

    immutable float GLOBAL_LIGHT_MIN = 0.0;
    immutable float GLOBAL_LIGHT_MAX = 1.0;

    void initialize() {
        import graphics.shader_handler;

        ambientLightLevelUniformLocation = ShaderHandler.getUniformLocation("chunk", "globalLightLevel");
    }

    float getCurrentLightLevel() {
        return globalAmbientLightLevel;
    }

    void setCurrentLightLevel(float newValue) {
        import graphics.shader_handler;
        import std.algorithm;

        globalAmbientLightLevel = clamp(newValue, GLOBAL_LIGHT_MIN, GLOBAL_LIGHT_MAX);

        ShaderHandler.setUniformFloat("chunk", ambientLightLevelUniformLocation, globalAmbientLightLevel);
    }

    void cascadeNaturalLight(int xInWorld, int zInWorld) {
        // import std.datetime.stopwatch;
        // import std.math.algebraic;

        // long totalTime = 0;

        // writeln("---------");

        // auto sw = StopWatch(AutoStart.yes);

        // void swPrint(string text) {
        //     long currTime = sw.peek().total!"usecs";
        //     totalTime += currTime;
        //     writeln(text, " took: ", currTime, "us");
        //     sw.reset();
        // }

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
        foreach (x; minChunkX .. maxChunkX + 1) {
            foreach (z; minChunkZ .. maxChunkZ + 1) {
                Vec2i cacheKey = Vec2i(x, z);
                chunkPointers[x - minChunkX][z - minChunkZ] = Map.getChunkPointerMutable(
                    cacheKey); //cacheKey in database;
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

            foreach (x; updateMinChunkX .. updateMaxChunkX + 1) {
                foreach (z; updateMinChunkZ .. updateMaxChunkZ + 1) {
                    Vec2i cacheKey = Vec2i(x, z);
                    MapGraphics.generate(cacheKey);
                }
            }
        }

        const(BlockDefinition*) ultraFastBlockDatabaseAccess = BlockDatabase.getUltraFastAccess();

        // swPrint("init");

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

                int highPoint = 0;

                foreach (dir; CHUNK_DIRECTIONS) {

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
                        .data[positionToIndex(xInChunkPointer, yRaw, zInChunkPointer)];

                    const BlockDefinition* thisDefinition = ultraFastBlockDatabaseAccess + currentBlockPointer
                        .blockID;

                    // Initial binary application.
                    if (thisDefinition.lightPropagates) {

                        // The walls are all light sources or else we'd infinitely be checking the world. Must assume their data is correct.
                        if ((xRaw == minW || xRaw == maxW - 1) ||
                            (zRaw == minW || zRaw == maxW - 1) ||
                            (yRaw == 0 || yRaw == (CHUNK_HEIGHT - 1))) {

                            elementPointer.naturalLightLevel = currentBlockPointer
                                .naturalLightBank;
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

                            const bool isArtificialLightSource = thisDefinition
                                .isLightSource;

                            elementPointer.naturalLightLevel = (isSunlight) ? LIGHT_LEVEL_MAX : 0;

                            elementPointer.artificialLightLevel = (isArtificialLightSource) ? thisDefinition
                                .lightSourceLevel : 0;

                            //? Anything that propagates light "is air" as far as this algorithm is concerned.
                            elementPointer.isAir = true;

                            if (isSunlight || isArtificialLightSource) {
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

        // swPrint("stage 1");

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

                const ubyte downStreamNaturalLightLevel = (thisNode.naturalLightLevel == 0) ? 0 : cast(
                    ubyte)(thisNode.naturalLightLevel - 1);

                const ubyte downStreamArtificialLightLevel = (
                    thisNode.artificialLightLevel == 0) ? 0 : cast(
                    ubyte)(
                    thisNode.artificialLightLevel - 1);

                // writeln(downStreamArtificialLightLevel);

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

                    if (lookingAtNeighbor.naturalLightLevel < downStreamNaturalLightLevel) {
                        lookingAtNeighbor.naturalLightLevel = downStreamNaturalLightLevel;
                    }

                    if (
                        lookingAtNeighbor.artificialLightLevel < downStreamArtificialLightLevel) {
                        lookingAtNeighbor.artificialLightLevel = downStreamArtificialLightLevel;
                    }

                    cacheTraversalNode.x = newPosX;
                    cacheTraversalNode.y = newPosY;
                    cacheTraversalNode.z = newPosZ;

                    cacheTraversalNode.naturalLightLevel = downStreamNaturalLightLevel;
                    cacheTraversalNode.artificialLightLevel = downStreamArtificialLightLevel;

                    cascadeQueue.put(cacheTraversalNode);
                }
            }
        }

        // swPrint("stage 2");

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
                    BlockData* thisBlockData = &thisChunk
                        .data[positionToIndex(xInChunkPointer, yRaw, zInChunkPointer)];

                    MazeElement* thisMazeElement = &lightPool[xInBox][zInBox][yRaw];

                    thisBlockData.naturalLightBank = thisMazeElement.naturalLightLevel;

                    thisBlockData.artificialLightBank = thisMazeElement
                        .artificialLightLevel;
                }
            }
        }

        // swPrint("stage 3");

        // writeln("total time: ", totalTime, "us");
        // writeln("---------");
    }
}
