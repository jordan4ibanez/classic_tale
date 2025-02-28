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
import std.conv;
import std.math.algebraic;
import std.math.rounding;
import std.random;
import std.stdio;
import utility.window;

// Width is for X and Z.
immutable public int CHUNK_WIDTH = 16;
immutable public int CHUNK_HEIGHT = 256;

pragma(inline, true)
private string generateKey(const ref Vec2i input) {
    return "Chunk:" ~ to!string(input.x) ~ "|" ~ to!string(input.y);
}

struct BlockData {
    int blockID = 0;
    // Uses banked lighting. 
    //~ The banked lighting is blended together in the shader.
    //? Sun light (and moon light). Basically exposed to open sky straight upwards.
    ubyte naturalLightBank = 0;
    //? Artificial light sources like torches or camp fire.
    // ubyte artificialLightBank = 0;
    bool isSunlight = false;
}

struct Chunk {
    string meshKey = null;
    // Y, Z, X
    BlockData[CHUNK_HEIGHT][CHUNK_WIDTH][CHUNK_WIDTH] data;
    // Z, X
    int[CHUNK_WIDTH][CHUNK_WIDTH] heightmap;

    this(const string meshKey) {
        this.meshKey = meshKey;
    }
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

    void draw() {
        // todo: this should probably order by distance. Lucky D has that built in. :D

        Vec3d position;

        foreach (const chunkPos, const ref thisChunk; database) {
            position.x = chunkPos.x * CHUNK_WIDTH;
            position.z = chunkPos.y * CHUNK_WIDTH;

            const double maxX = position.x + CHUNK_WIDTH;
            const double maxY = position.y + CHUNK_HEIGHT;
            const double maxZ = position.z + CHUNK_WIDTH;

            if (CameraHandler.aabbInFrustum(position.x, position.y, position.z, maxX, maxY, maxZ)) {
                ModelHandler.drawIgnoreMissing(thisChunk.meshKey, position);
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

    BlockData getBlockAtWorldPosition(Vec3d position) {
        Vec2i chunkID = calculateChunkAtWorldPosition(position);

        Chunk* thisChunk = chunkID in database;

        if (thisChunk is null) {
            return BlockData();
        }

        Vec2i xzPosInChunk = getXZInChunk(position);

        int yPosInChunk = cast(int) floor(position.y);

        // Out of bounds.
        if (yPosInChunk < 0 || yPosInChunk >= CHUNK_HEIGHT) {
            writeln("WARNING! trying to read out of bounds! " ~ to!string(yPosInChunk));
            return BlockData();
        }

        return thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][yPosInChunk];
    }

    BlockData getBlockAtWorldPosition(double x, double y, double z) {
        Vec2i chunkID = calculateChunkAtWorldPosition(x, z);

        Chunk* thisChunk = chunkID in database;

        if (thisChunk is null) {
            return BlockData();
        }

        Vec2i xzPosInChunk = getXZInChunk(x, z);

        int yPosInChunk = cast(int) floor(y);

        // Out of bounds.
        if (yPosInChunk < 0 || yPosInChunk >= CHUNK_HEIGHT) {
            writeln("WARNING! trying to read out of bounds! " ~ to!string(yPosInChunk));
            return BlockData();
        }

        return thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][yPosInChunk];
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
            writeln("WARNING! trying to read out of bounds! " ~ to!string(y));
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
            writeln("WARNING! trying to read out of bounds! " ~ to!string(y));
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
            writeln("WARNING! trying to read out of bounds! " ~ to!string(position.y));
            return null;
        }

        return &thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][position.y];
    }

    void setBlockAtWorldPositionByID(Vec3d position, int blockID) {
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
            writeln("WARNING! trying to write out of bounds! " ~ to!string(yPosInChunk));
            return;
        }

        thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][yPosInChunk].blockID = blockID;
        thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][yPosInChunk].naturalLightBank = 0;

        updateHeightMap(thisChunk, xzPosInChunk.x, yPosInChunk, xzPosInChunk.y, blockID,
            cast(int) position.x, cast(int) position.z);

        cascadeNaturalLight(cast(int) floor(position.x), cast(int) floor(position.y), cast(int) floor(
                position.z));

        // This gets put into a HashSetQueue so it can keep doing it over and over.
        MapGraphics.generate(chunkID);
        updateAdjacentNeighborToPositionInChunk(chunkID, xzPosInChunk);
    }

    void setBlockAtWorldPositionByID(int x, int y, int z, int blockID) {
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
        thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][y].naturalLightBank = 0;

        updateHeightMap(thisChunk, xzPosInChunk.x, y, xzPosInChunk.y, blockID, x, z);

        cascadeNaturalLight(x, y, z);

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

        thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][yPosInChunk].blockID = thisBlock.id;
        thisChunk.data[xzPosInChunk.x][xzPosInChunk.y][yPosInChunk].naturalLightBank = 0;

        updateHeightMap(thisChunk, xzPosInChunk.x, yPosInChunk, xzPosInChunk.y, thisBlock.id,
            cast(int) position.x, cast(int) position.z);

        cascadeNaturalLight(cast(int) floor(position.x), cast(int) floor(position.y), cast(int) floor(
                position.z));

        // This gets put into a HashSetQueue so it can keep doing it over and over.
        MapGraphics.generate(chunkID);
        updateAdjacentNeighborToPositionInChunk(chunkID, xzPosInChunk);
    }

    /// x y z inside of the chunk.
    void updateHeightMap(Chunk* thisChunk, int xInChunk, int yInChunk, int zInChunk, int newID,
        int worldPositionX, int worldPositionZ) {

        const int height = thisChunk.heightmap[xInChunk][zInChunk];
        // ID was set to air. (removed/dug)
        if (newID == 0) {
            // If it was the top, have to scan down.
            //? Note: Subtractive update. Slightly more expensive. Has to scan down.
            if (height == yInChunk) {
                foreach_reverse (yScan; 0 .. yInChunk) {
                    // Found it. That's it.
                    if (thisChunk.data[xInChunk][zInChunk][yScan].blockID != 0) {
                        thisChunk.heightmap[xInChunk][zInChunk] = yScan;
                    } else {
                        thisChunk.data[xInChunk][zInChunk][yScan].isSunlight = true;
                        // thisChunk.data[xInChunk][zInChunk][yScan].blockID = 1;
                    }
                }
            }

            // This is a Y striping non-update fix. 0, 1, 0 1 -> top. If this is not triggered it will leave outdated lights.
            return cascadeNaturalLight(worldPositionX, yInChunk, worldPositionZ);
        }  // todo: set this to check block definition database for replaceable or airlike, not too sure how this should be handled with complex block types.
        // Else it was set to not air.
        else {
            // If it's taller, it's the top.
            // This portion of the heightmap has shifted up.
            //? Note: Additive update.
            if (yInChunk > height) {
                writeln("heightmap update");
                thisChunk.heightmap[xInChunk][zInChunk] = yInChunk;
                foreach (yScan; height .. yInChunk) {
                    thisChunk.data[xInChunk][zInChunk][yScan].isSunlight = false;
                    // thisChunk.data[xInChunk][zInChunk][yScan].blockID = 2;
                }
            }
        }
    }

    void cascadeNaturalLight(int x, int y, int z) {
        import linked_hash_queue;
        import utility.queue;

        Queue!Vec3i sourceQueue;
        Queue!Vec3i searchQueue;

        const Vec3i origin = Vec3i(x, y, z);

        searchQueue.push(origin);

        // Get all light sources. (sunlight)
        while (true) {
            Option!Vec3i positionResult = searchQueue.pop();

            if (positionResult.isNone()) {
                writeln("breaking");
                break;
            }

            const Vec3i thisPosition = positionResult.unwrap();

            const BlockData* thisBlock = getBlockPointerAtWorldPosition(thisPosition);

            // Not air.
            if (thisBlock.blockID != 0) {
                continue;
            }

            if (thisBlock.isSunlight) {
                sourceQueue.push(thisPosition);
            }

            searchQueue.push(Vec3i(thisPosition.x - 1, thisPosition.y, thisPosition.z));
            searchQueue.push(Vec3i(thisPosition.x + 1, thisPosition.y, thisPosition.z));
        }

        while (true) {
            Option!Vec3i positionResult = sourceQueue.pop();

            if (positionResult.isNone()) {
                writeln("breaking");
                break;
            }

            writeln("found: ", positionResult.unwrap);
        }

        /*
        Cascade down, then out.
        If nothing below, move outwards.

        so if y - 1 is an air block, trigger another cascade.
        if it's not, trigger a horizontal cascade.
        */

        // Went under the world.
        // if (y < 0) {
        //     writeln("cascaded under the map.");
        //     return;
        // }

        // BlockData* thisBlock = getBlockPointerAtWorldPosition(x, y, z);

        // Whoops, went into unloaded area.
        // if (thisBlock is null) {
        //     writeln("cascaded into unloaded area.");
        //     return;
        // }

        // writeln(thisBlock.blockID);

        // // Todo: this needs to be able to flow through clear blocks like glass.
        // if (thisBlock.blockID == 0) {
        //     // writeln("enter");
        //     // This means that now it is direct sunlight.
        //     if (getTopAt(x, z) <= y) {

        //         thisBlock.naturalLightBank = 15;
        //         cascadeNaturalLight(x, y - 1, z);
        //         // BlockData* leftBlock = getBlockPointerAtWorldPosition(x - 1, y, z);

        //         // Todo: check if natural light next to is less than 14 and flow into it if so.
        //     } else {
        //         // This means it is now under a block. Check surroundings to find local natural light level.
        //         ubyte maxOutputNeighbors = 0;
        //         bool spreadFront = false;
        //         bool spreadBack = false;
        //         bool spreadLeft = false;
        //         bool spreadRight = false;

        //         static const Vec3i[5] directions = [
        //             Vec3i(-1, 0, 0),
        //             Vec3i(1, 0, 0),
        //             Vec3i(0, 1, 0),
        //             // Vec3i(0, 0, -1),
        //             // Vec3i(0, 0, 1),
        //         ];

        //         foreach (dir; directions) {
        //             const BlockData* neighbor = getBlockPointerAtWorldPosition(x + dir.x, y + dir.y, z + dir
        //                     .z);

        //             if (neighbor && neighbor.blockID == 0) {
        //                 maxOutputNeighbors = max(maxOutputNeighbors, neighbor.naturalLightBank);
        //             }
        //         }

        //         if (maxOutputNeighbors > 0) {
        //             maxOutputNeighbors -= 1;
        //         }

        //         thisBlock.naturalLightBank = maxOutputNeighbors;

        //         // if ()

        //         cascadeNaturalLight(x, y - 1, z);
        //     }
        // }

    }

    void worldLoad(Vec2i currentPlayerChunk) {
        foreach (x; currentPlayerChunk.x - 1 .. currentPlayerChunk.x + 2) {
            foreach (z; currentPlayerChunk.y - 1 .. currentPlayerChunk.y + 2) {
                writeln("loading chunk ", x, ",", z);
                // loadChunk(i);
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
            if (abs(key.x - currentPlayerChunk.x) > 1 || abs(key.y - currentPlayerChunk.y) > 1) {
                database.remove(key);
                // todo: save the chunks to sqlite.
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
        Chunk newChunk = Chunk(generateKey(chunkPosition));
        generateChunkData(chunkPosition, newChunk);
        database[chunkPosition] = newChunk;

        MapGraphics.generate(chunkPosition);
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
            const Vec2i left = Vec2i(chunkKey.x - 1, chunkKey.y);
            if (left in database) {
                MapGraphics.generate(left);
            }
        } else if (xzPosInChunk.x == CHUNK_WIDTH - 1) {
            const Vec2i right = Vec2i(chunkKey.x + 1, chunkKey.y);
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
        const(BiomeDefinition*) thisBiome = BiomeDatabase.getBiomeByID(0);
        if (thisBiome is null) {
            import std.conv;

            throw new Error("Attempted to get biome " ~ to!string(0) ~ " which does not exist");
        }

        const double baseHeight = 160;

        const int basePositionX = chunkPosition.x * CHUNK_WIDTH;
        const int basePositionZ = chunkPosition.y * CHUNK_WIDTH;

        const(BlockDefinition*) bedrock = BlockDatabase.getBlockByName("bedrock");
        if (bedrock is null) {
            throw new Error("Please do not remove bedrock from the engine.");
        }

        const(BlockDefinition*) stone = BlockDatabase.getBlockByID(
            thisBiome.stoneLayerID);
        if (stone is null) {
            throw new Error("Stone does not exist for biome " ~ thisBiome.name);
        }

        const(BlockDefinition*) dirt = BlockDatabase.getBlockByID(
            thisBiome.dirtLayerID);
        if (dirt is null) {
            throw new Error("Dirt does not exist for biome " ~ thisBiome.name);
        }

        const(BlockDefinition*) grass = BlockDatabase.getBlockByID(
            thisBiome.grassLayerID);
        if (grass is null) {
            throw new Error("Grass does not exist for biome " ~ thisBiome.name);
        }

        foreach (x; 0 .. CHUNK_WIDTH) {
            foreach (z; 0 .. CHUNK_WIDTH) {

                const double selectedNoise = fnlGetNoise2D(&noise, x + basePositionX, z + basePositionZ);

                const double noiseScale = 20;

                const int selectedHeight = cast(int) floor(
                    baseHeight + (selectedNoise * noiseScale));

                const int grassLayer = selectedHeight;
                const int dirtLayer = selectedHeight - 3;

                const double bedRockNoise = fnlGetNoise2D(&noise, (x + basePositionX) * 12, (
                        z + basePositionZ) * 12) * 2;
                const int bedRockSelectedHeight = cast(int) round(abs(bedRockNoise));

                thisChunk.heightmap[x][z] = grassLayer;

                foreach (y; 0 .. CHUNK_HEIGHT) {

                    if (y > selectedHeight) {
                        thisChunk.data[x][z][y].naturalLightBank = 15;
                        thisChunk.data[x][z][y].isSunlight = true;
                    } else {
                        if (y == 0) {
                            thisChunk.data[x][z][y].blockID = bedrock.id;
                        } else if (y <= 2) {
                            if (y <= bedRockSelectedHeight) {
                                thisChunk.data[x][z][y].blockID = bedrock.id;
                            } else {
                                thisChunk.data[x][z][y].blockID = stone.id;
                            }
                        } else if (y < dirtLayer) {
                            thisChunk.data[x][z][y].blockID = stone.id;
                        } else if (y < grassLayer) {
                            thisChunk.data[x][z][y].blockID = dirt.id;
                        } else if (y == grassLayer) {
                            thisChunk.data[x][z][y].blockID = grass.id;
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
            double thisXPoint = (xOnRect > entitySize.x) ? entitySize.x : xOnRect;
            thisXPoint += entityPosition.x - entityHalfWidth;
            oldX = currentX;
            currentX = cast(int) floor(thisXPoint);

            foreach (double zOnRect; 0 .. ceil(entitySize.x) + 1) {
                double thisZPoint = (zOnRect > entitySize.x) ? entitySize.x : zOnRect;
                thisZPoint += entityPosition.z - entityHalfWidth;
                oldZ = currentZ;
                currentZ = cast(int) floor(thisZPoint);

                foreach (double yOnRect; 0 .. ceil(entitySize.y) + 1) {
                    double thisYPoint = (yOnRect > entitySize.y) ? entitySize.y : yOnRect;
                    thisYPoint += entityPosition.y;
                    oldY = currentY;
                    currentY = cast(int) floor(thisYPoint);

                    if (currentY == oldY) {
                        continue;
                    }

                    // debugDrawPoints ~= Vec2d(currentX, currentY);

                    BlockData data = getBlockAtWorldPosition(Vec3d(thisXPoint, thisYPoint, thisZPoint));

                    // todo: if solid block collide.
                    // todo: probably custom blocks one day.

                    // import raylib;

                    // These are literal positions in 3D space.
                    // DrawSphere(Vector3(thisXPoint, thisYPoint, thisZPoint), 0.01, Colors.ORANGE);

                    // These are floored, it will look completely wrong.
                    // I assure you it is correct.
                    // DrawSphere(Vector3(currentX, currentY, currentZ), 0.01, Colors.BLUE);

                    if (data.blockID == 0) {
                        continue;
                    }

                    // todo: this needs to iterate through the block sizes on custom blocks.
                    final switch (axis) {
                    case CollisionAxis.X:

                        Vec3d blockMin = Vec3d(currentX, currentY, currentZ);
                        Vec3d blockMax = Vec3d(currentX + 1, currentY + 1, currentZ + 1);

                        // import raylib;

                        // DrawCube(blockMin.toRaylib(), 0.1, 0.1, 0.1, Colors.DARKPURPLE);

                        CollisionResult result = collideEntityToBlock(entityPosition, entitySize, entityVelocity,
                            blockMin, blockMax, axis);

                        if (result.collides) {
                            entityPosition.x = result.newPosition;
                            entityVelocity.x = 0;
                        }

                        break;
                    case CollisionAxis.Y:
                        // writeln("Y ");

                        Vec3d blockMin = Vec3d(currentX, currentY, currentZ);
                        Vec3d blockMax = Vec3d(currentX + 1, currentY + 1, currentZ + 1);

                        // import raylib;

                        // DrawCube(blockMin.toRaylib(), 0.1, 0.1, 0.1, Colors.DARKPURPLE);

                        CollisionResult result = collideEntityToBlock(entityPosition, entitySize, entityVelocity,
                            blockMin, blockMax, axis);

                        if (result.collides) {
                            entityPosition.y = result.newPosition;
                            entityVelocity.y = 0;
                            hitGround = result.hitGround;
                        }
                        break;
                    case CollisionAxis.Z:

                        Vec3d blockMin = Vec3d(currentX, currentY, currentZ);
                        Vec3d blockMax = Vec3d(currentX + 1, currentY + 1, currentZ + 1);

                        // import raylib;

                        // DrawCube(blockMin.toRaylib(), 0.1, 0.1, 0.1, Colors.DARKPURPLE);

                        CollisionResult result = collideEntityToBlock(entityPosition, entitySize, entityVelocity,
                            blockMin, blockMax, axis);

                        if (result.collides) {
                            entityPosition.z = result.newPosition;
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
