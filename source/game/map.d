module game.map;

public import utility.collision_functions : CollisionAxis;
import fast_noise;
import game.biome_database;
import game.block_database;
import game.map_graphics;
import graphics.camera_handler;
import graphics.render;
import graphics.texture_handler;
import math.rect;
import math.vec2i;
import math.vec3d;
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

struct BlockData {
    int blockID = 0;
}

final class Chunk {
    // Y, Z, X
    BlockData[CHUNK_HEIGHT][CHUNK_WIDTH][CHUNK_WIDTH] data;
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
    }

    const(Chunk*) getChunkPointer(Vec2i key) {
        return key in database;
    }

    const(Chunk*) getChunkPointer(immutable int keyX, immutable int keyZ) {
        return Vec2i(keyX, keyZ) in database;
    }

    double getGravity() {
        return gravity;
    }

    double getTop(Vec3d position) {
        // todo: this should probably just use a heightmap.
        Vec2i chunkID = calculateChunkAtWorldPosition(position);
        Vec2i posInChunk = getXZInChunk(position);

        if (chunkID !in database) {
            return 0;
        }

        Chunk thisChunk = database[chunkID];

        foreach_reverse (y; 0 .. CHUNK_HEIGHT) {
            if (thisChunk.data[posInChunk.x][posInChunk.y][y].blockID != 0) {
                return y + 1;
            }
        }
        return 0;
    }

    Vec2i calculateChunkAtWorldPosition(Vec3d position) {
        return Vec2i(
            cast(int) floor(position.x / CHUNK_WIDTH),
            cast(int) floor(position.z / CHUNK_WIDTH),
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

    BlockData getBlockAtWorldPosition(Vec3d position) {
        Vec2i chunkID = calculateChunkAtWorldPosition(position);

        if (chunkID !in database) {
            return BlockData();
        }

        Vec2i xzPosInChunk = getXZInChunk(position);

        int yPosInChunk = cast(int) floor(position.y);

        // Out of bounds.
        if (yPosInChunk < 0 || yPosInChunk >= CHUNK_HEIGHT) {
            writeln("WARNING! trying to read out of bounds! " ~ to!string(yPosInChunk));
            return BlockData();
        }

        return database[chunkID].data[xzPosInChunk.x][xzPosInChunk.y][yPosInChunk];
    }

    void setBlockAtWorldPositionByID(Vec3d position, int blockID) {
        if (!BlockDatabase.hasBlockID(blockID)) {
            throw new Error("Cannot set to block ID " ~ to!string(blockID) ~ ", ID does not exist.");
        }

        Vec2i chunkID = calculateChunkAtWorldPosition(position);

        if (chunkID !in database) {
            // todo: maybe unload the chunk after?
            // loadChunk(chunkID);
        }

        Vec2i xzPosInChunk = getXZInChunk(position);

        int yPosInChunk = cast(int) floor(position.y);

        // Out of bounds.
        if (yPosInChunk < 0 || yPosInChunk >= CHUNK_HEIGHT) {
            writeln("WARNING! trying to write out of bounds! " ~ to!string(yPosInChunk));
            return;
        }

        database[chunkID].data[xzPosInChunk.x][xzPosInChunk.y][yPosInChunk].blockID = blockID;

        // This gets put into a HashSetQueue so it can keep doing it over and over.
        MapGraphics.generate(chunkID);
    }

    void setBlockAtWorldPositionByName(Vec3d position, string name) {

        Vec2i chunkID = calculateChunkAtWorldPosition(position);

        if (chunkID !in database) {
            // todo: maybe unload the chunk after?
            // loadChunk(chunkID);
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

        database[chunkID].data[xzPosInChunk.x][xzPosInChunk.y][yPosInChunk].blockID = thisBlock.id;

        // This gets put into a HashSetQueue so it can keep doing it over and over.
        MapGraphics.generate(chunkID);
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

    // bool collideEntityToWorld(ref Vec2d entityPosition, Vec2d entitySize, ref Vec2d entityVelocity,
    //     CollisionAxis axis) {

    //     return collision(entityPosition, entitySize, entityVelocity, axis);
    // }

    void debugGenerate(int x, int z) {
        loadChunk(Vec2i(x, z));
    }

private: //* BEGIN INTERNAL API.

    // bool collision(ref Vec2d entityPosition, Vec2d entitySize, ref Vec2d entityVelocity, CollisionAxis axis) {
    //     import utility.collision_functions;

    //     int oldX = int.min;
    //     int oldY = int.min;
    //     int currentX = int.min;
    //     int currentY = int.min;

    //     // debugDrawPoints = [];

    //     bool hitGround = false;

    //     foreach (double xOnRect; 0 .. ceil(entitySize.x) + 1) {
    //         double thisXPoint = (xOnRect > entitySize.x) ? entitySize.x : xOnRect;
    //         thisXPoint += entityPosition.x - (entitySize.x * 0.5);
    //         oldX = currentX;
    //         currentX = cast(int) floor(thisXPoint);

    //         if (oldX == currentX) {
    //             // writeln("skip X ", currentY);
    //             continue;
    //         }

    //         foreach (double yOnRect; 0 .. ceil(entitySize.y) + 1) {
    //             double thisYPoint = (yOnRect > entitySize.y) ? entitySize.y : yOnRect;
    //             thisYPoint += entityPosition.y;

    //             oldY = currentY;
    //             currentY = cast(int) floor(thisYPoint);

    //             if (currentY == oldY) {
    //                 // writeln("skip Y ", currentY);
    //                 continue;
    //             }

    //             // debugDrawPoints ~= Vec2d(currentX, currentY);

    //             ChunkData data = getBlockAtWorldPosition(Vec2d(currentX, currentY));

    //             // todo: if solid block collide.
    //             // todo: probably custom blocks one day.

    //             if (data.blockID == 0) {
    //                 continue;
    //             }

    //             if (axis == CollisionAxis.X) {
    //                 CollisionResult result = collideXToBlock(entityPosition, entitySize, entityVelocity,
    //                     Vec2d(currentX, currentY), Vec2d(1, 1));

    //                 if (result.collides) {
    //                     entityPosition.x = result.newPosition;
    //                     entityVelocity.x = 0;
    //                 }
    //             } else {

    //                 CollisionResult result = collideYToBlock(entityPosition, entitySize, entityVelocity,
    //                     Vec2d(currentX, currentY), Vec2d(1, 1));

    //                 if (result.collides) {
    //                     entityPosition.y = result.newPosition;
    //                     entityVelocity.y = 0;
    //                     if (result.hitGround) {
    //                         hitGround = true;
    //                     }
    //                 }
    //             }
    //         }
    //     }

    //     return hitGround;
    // }

    void unloadOldChunks(Vec2i currentPlayerChunk) {

        // todo: save the chunks to mongoDB.

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
        Chunk newChunk = new Chunk();
        generateChunkData(chunkPosition, newChunk);
        database[chunkPosition] = newChunk;
        MapGraphics.generate(chunkPosition);
    }

    void generateChunkData(Vec2i chunkPosition, ref Chunk thisChunk) {

        // todo: the chunk should have a biome.
        const(BiomeDefinition*) thisBiome = BiomeDatabase.getBiomeByID(0);
        if (thisBiome is null) {
            import std.conv;

            throw new Error("Attempted to get biome " ~ to!string(0) ~ " which does not exist");
        }

        immutable double baseHeight = 160;

        immutable int basePositionX = chunkPosition.x * CHUNK_WIDTH;
        immutable int basePositionZ = chunkPosition.y * CHUNK_WIDTH;

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

                immutable double selectedNoise = fnlGetNoise2D(&noise, x + basePositionX, z + basePositionZ);

                immutable double noiseScale = 20;

                immutable int selectedHeight = cast(int) floor(
                    baseHeight + (selectedNoise * noiseScale));

                immutable int grassLayer = selectedHeight;
                immutable int dirtLayer = selectedHeight - 3;

                immutable double bedRockNoise = fnlGetNoise2D(&noise, (x + basePositionX) * 12, (
                        z + basePositionZ) * 12) * 2;
                immutable int bedRockSelectedHeight = cast(int) round(abs(bedRockNoise));

                yStack: foreach (y; 0 .. CHUNK_HEIGHT) {

                    if (y > selectedHeight) {
                        break yStack;
                    }

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
