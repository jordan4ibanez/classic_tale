module game.map_graphics;

import core.memory;
import game.block_database;
import game.map;
import graphics.model_handler;
import graphics.texture_handler;
import linked_hash_queue;
import math.vec2d;
import math.vec2i;
import math.vec3d;
import std.array;
import std.bitmanip;
import std.conv;
import std.datetime.stopwatch;
import std.meta;
import std.stdio;

// immutable ulong averager = 200;
// double[averager] timer = 0;
// ulong timerIndex = 0;

private static immutable enum Normal : Vec3d {
    Front = Vec3d(0, 0, -1),
    Back = Vec3d(0, 0, 1),
    Left = Vec3d(-1, 0, 0),
    Right = Vec3d(1, 0, 0),
    Top = Vec3d(0, 1, 0),
    Bottom = Vec3d(0, -1, 0)
}

struct FaceGeneration {
    mixin(bitfields!(
            bool, "front", 1,
            bool, "back", 1,
            bool, "left", 1,
            bool, "right", 1,
            bool, "top", 1,
            bool, "bottom", 1,
            ubyte, "lightLevelFront", 4,
            ubyte, "lightLevelBack", 4,
            ubyte, "lightLevelLeft", 4,
            ubyte, "lightLevelRight", 4,
            ubyte, "lightLevelTop", 4,
            ubyte, "lightLevelBottom", 4,
            bool, "", 2,
    ));

    this(bool input) {
        this.front = input;
        this.back = input;
        this.left = input;
        this.right = input;
        this.top = input;
        this.bottom = input;
    }

    this(bool front, bool back, bool left, bool right, bool top, bool bottom) {
        this.front = front;
        this.back = back;
        this.left = left;
        this.right = right;
        this.top = top;
        this.bottom = bottom;
    }
}

alias AllFaces = Alias!(FaceGeneration(true));
alias NoFaces = Alias!(FaceGeneration(false));

struct FaceTextures {
    int front = -1;
    int back = -1;
    int left = -1;
    int right = -1;
    int top = -1;
    int bottom = -1;

    this(int allFaces) {
        foreach (ref component; this.tupleof) {
            component = allFaces;
        }
    }

    void update(const int* newTextures) {
        this.front = newTextures[0];
        this.back = newTextures[1];
        this.left = newTextures[2];
        this.right = newTextures[3];
        this.top = newTextures[4];
        this.bottom = newTextures[5];
    }
}

private struct PopResult {
    bool exists = false;
    Vec2i data;
}

static final const class MapGraphics {
static:
private:

    LinkedHashQueue!Vec2i generationQueue;
    // How many chunks can generate per frame.
    int generationLevel = 1;

public:

    void generate(const ref Vec2i chunkToGenerate) {
        generationQueue.pushBack(chunkToGenerate);
    }

    void __update() {

        foreach (_; 0 .. generationLevel) {
            Option!Vec2i thisResult = generationQueue.popFront();

            if (thisResult.isNone()) {
                return;
            }
            // writeln(thisResult.unwrap);
            createChunkMesh(thisResult.unwrap);
        }
    }

private:

    void createChunkMesh(Vec2i chunkKey) {
        const(Chunk*) thisChunk = Map.getChunkPointer(chunkKey);

        if (thisChunk is null) {
            writeln("aborting, chunk " ~ to!string(chunkKey.x) ~ " " ~ to!string(
                    chunkKey.y) ~ " does not exist.");
            return;
        }

        // writeln("Generating chunk mesh " ~ to!string(chunkKey.x) ~ " " ~ to!string(chunkKey.y));

        FaceTextures faceTextures;

        auto sw = StopWatch(AutoStart.yes);

        ulong allocation = 0;

        // Neighbor chunks.
        const(Chunk*) neighborFront = Map.getChunkPointer(chunkKey.x, chunkKey.y - 1);
        const(Chunk*) neighborBack = Map.getChunkPointer(chunkKey.x, chunkKey.y + 1);
        const(Chunk*) neighborLeft = Map.getChunkPointer(chunkKey.x - 1, chunkKey.y);
        const(Chunk*) neighborRight = Map.getChunkPointer(chunkKey.x + 1, chunkKey.y);

        // Preallocation.
        foreach (immutable x; 0 .. CHUNK_WIDTH) {
            foreach (immutable z; 0 .. CHUNK_WIDTH) {
                foreach (immutable y; 0 .. CHUNK_HEIGHT) {

                    // todo: undo this worst case scenario prototyping.
                    const BlockData* thisData = &thisChunk.data[x][z][y];

                    if (thisData.blockID == 0) {
                        continue;
                    }
                    // Todo: this needs a visual check.
                    // Todo: this needs a neighbor check.

                    // Front.
                    if (z - 1 < 0) {
                        if (neighborFront) {
                            if (neighborFront.data[x][CHUNK_WIDTH - 1][y].blockID == 0) {
                                allocation++;
                                // vertexAllocation += 18;
                                // textureCoordAllocation += 12;
                            }
                        }
                    } else if (thisChunk.data[x][z - 1][y].blockID == 0) {
                        allocation++;
                        // vertexAllocation += 18;
                        // textureCoordAllocation += 12;
                    }

                    // Back.
                    if (z + 1 >= CHUNK_WIDTH) {
                        if (neighborBack) {
                            if (neighborBack.data[x][0][y].blockID == 0) {
                                allocation++;
                                // vertexAllocation += 18;
                                // textureCoordAllocation += 12;
                            }
                        }
                    } else if (thisChunk.data[x][z + 1][y].blockID == 0) {
                        allocation++;
                        // vertexAllocation += 18;
                        // textureCoordAllocation += 12;
                    }

                    // Left.
                    if (x - 1 < 0) {
                        if (neighborLeft) {
                            if (neighborLeft.data[CHUNK_WIDTH - 1][z][y].blockID == 0) {
                                allocation++;
                                // vertexAllocation += 18;
                                // textureCoordAllocation += 12;
                            }
                        }
                    } else if (thisChunk.data[x - 1][z][y].blockID == 0) {
                        allocation++;
                        // vertexAllocation += 18;
                        // textureCoordAllocation += 12;
                    }

                    // Right.
                    if (x + 1 >= CHUNK_WIDTH) {
                        if (neighborRight) {
                            if (neighborRight.data[0][z][y].blockID == 0) {
                                allocation++;
                                // vertexAllocation += 18;
                                // textureCoordAllocation += 12;
                            }
                        }
                    } else if (thisChunk.data[x + 1][z][y].blockID == 0) {
                        allocation++;
                        // vertexAllocation += 18;
                        // textureCoordAllocation += 12;
                    }

                    // Top.
                    if (y + 1 >= CHUNK_HEIGHT) {
                        // Draw it, that's the top of the map.
                        allocation++;
                        // vertexAllocation += 18;
                        // textureCoordAllocation += 12;
                    } else if (thisChunk.data[x][z][y + 1].blockID == 0) {
                        allocation++;
                        // vertexAllocation += 18;
                        // textureCoordAllocation += 12;
                    }

                    // Bottom.
                    if (y - 1 < 0) {
                        // Do not draw the bottom of the world.
                        // The player should never fall out the bottom of the world.
                    } else if (thisChunk.data[x][z][y - 1].blockID == 0) {
                        allocation++;
                        // vertexAllocation += 18;
                        // textureCoordAllocation += 12;
                    }

                    // 3 [xyz], 6 [2 tris], 6 faces
                    // vertexAllocation += 108;

                    // 2 [xy], 6 [2 tris], 6 faces
                    // textureCoordAllocation += 72;

                }
            }
        }

        // Vertices and normals are synced. The normal is the direction of the vertex.
        float* vertices = cast(float*) GC.malloc(float.sizeof * (allocation * 18));
        float* normals = cast(float*) GC.malloc(float.sizeof * (allocation * 18));

        ubyte* colors = cast(ubyte*) GC.malloc(ubyte.sizeof * (allocation * 24));

        float* textureCoordinates = cast(float*) GC.malloc(float.sizeof * (allocation * 12));

        ulong vertIndex = 0;
        ulong textIndex = 0;
        ulong colorIndex = 0;

        FaceGeneration faceGen = AllFaces;

        Vec3d pos;
        Vec3d min = Vec3d(0, 0, 0);
        Vec3d max = Vec3d(1, 1, 1);

        foreach (immutable x; 0 .. CHUNK_WIDTH) {
            foreach (immutable z; 0 .. CHUNK_WIDTH) {
                foreach (immutable y; 0 .. CHUNK_HEIGHT) {

                    const BlockData* thisData = &thisChunk.data[x][z][y];

                    if (thisData.blockID == 0) {
                        continue;
                    }

                    const BlockDefinition* thisDefinition = BlockDatabase.getBlockByID(
                        thisData.blockID);

                    faceTextures.update(thisDefinition.textureIDs.ptr);

                    faceGen.front = false;
                    faceGen.back = false;
                    faceGen.left = false;
                    faceGen.right = false;
                    faceGen.top = false;
                    faceGen.bottom = false;

                    // Front.
                    if (z - 1 < 0) {
                        if (neighborFront) {
                            if (neighborFront.data[x][CHUNK_WIDTH - 1][y].blockID == 0) {
                                faceGen.front = true;
                                faceGen.lightLevelFront = neighborFront.data[x][CHUNK_WIDTH - 1][y]
                                    .naturalLightBank;
                            }
                        }
                    } else if (thisChunk.data[x][z - 1][y].blockID == 0) {
                        faceGen.front = true;
                        faceGen.lightLevelFront = thisChunk.data[x][z - 1][y].naturalLightBank;
                    }

                    // Back.
                    if (z + 1 >= CHUNK_WIDTH) {
                        if (neighborBack) {
                            if (neighborBack.data[x][0][y].blockID == 0) {
                                faceGen.back = true;
                                faceGen.lightLevelBack = neighborBack
                                    .data[x][0][y].naturalLightBank;
                            }
                        }
                    } else if (thisChunk.data[x][z + 1][y].blockID == 0) {
                        faceGen.back = true;
                        faceGen.lightLevelBack = thisChunk.data[x][z + 1][y].naturalLightBank;
                    }

                    // Left.
                    if (x - 1 < 0) {
                        if (neighborLeft) {
                            if (neighborLeft.data[CHUNK_WIDTH - 1][z][y].blockID == 0) {
                                faceGen.left = true;
                                faceGen.lightLevelLeft = neighborLeft.data[CHUNK_WIDTH - 1][z][y]
                                    .naturalLightBank;
                            }
                        }
                    } else if (thisChunk.data[x - 1][z][y].blockID == 0) {
                        faceGen.left = true;
                        faceGen.lightLevelLeft = thisChunk.data[x - 1][z][y].naturalLightBank;
                    }

                    // Right.
                    if (x + 1 >= CHUNK_WIDTH) {
                        if (neighborRight) {
                            if (neighborRight.data[0][z][y].blockID == 0) {
                                faceGen.right = true;
                                faceGen.lightLevelRight = neighborRight
                                    .data[0][z][y].naturalLightBank;
                            }
                        }
                    } else if (thisChunk.data[x + 1][z][y].blockID == 0) {
                        faceGen.right = true;
                        faceGen.lightLevelRight = thisChunk.data[x + 1][z][y].naturalLightBank;
                    }

                    // Top.
                    if (y + 1 >= CHUNK_HEIGHT) {
                        // Draw it, that's the top of the map.
                        faceGen.top = true;
                    } else if (thisChunk.data[x][z][y + 1].blockID == 0) {
                        faceGen.top = true;
                        faceGen.lightLevelTop = thisChunk.data[x][z][y + 1].naturalLightBank;
                    }

                    // Bottom.
                    if (y - 1 < 0) {
                        // Do not draw the bottom of the world.
                        // The player should never fall out the bottom of the world.
                    } else if (thisChunk.data[x][z][y - 1].blockID == 0) {
                        faceGen.bottom = true;
                        faceGen.lightLevelBottom = thisChunk.data[x][z][y - 1].naturalLightBank;
                    }

                    pos.x = x;
                    pos.y = y;
                    pos.z = z;

                    makeCube(vertIndex, textIndex, colorIndex, vertices, textureCoordinates, normals, colors, pos, min,
                        max, &faceGen, &faceTextures);

                }
            }
        }

        // timer[timerIndex] = cast(double) sw.peek().total!"msecs";
        // double total = 0;
        // foreach (size; timer) {
        //     total += size;
        // }
        // total /= averager;
        // timerIndex++;
        // if (timerIndex >= averager) {
        //     timerIndex = 0;
        // }
        // writeln("took: ", total, "ms average");

        // writeln("took: ", sw.peek().total!"usecs", "us");

        if (ModelHandler.modelExists(thisChunk.meshKey)) {
            ModelHandler.destroy(thisChunk.meshKey);
        }

        // writeln("does not exist, creating");
        ModelHandler.newModelFromMeshPointers(thisChunk.meshKey, vertices, allocation * 18, textureCoordinates,
            normals, colors);
    }

    // Maybe this can have a numeric AA or array to hash this in immediate mode?
    // pragma(inline)
    void makeCube(ref ulong vertIndex, ref ulong textIndex, ref ulong colorIndex, float* vertices,
        float* textureCoordinates, float* normals, ubyte* colors, const ref Vec3d position, const ref Vec3d min,
        const ref Vec3d max, FaceGeneration* faceGeneration, const FaceTextures* textures,) {

        // assert(min.x >= 0 && min.y >= 0 && min.z >= 0, "min is out of bounds");
        // assert(max.x <= 1 && max.y <= 1 && max.z <= 1, "max is out of bounds");
        // assert(max.x >= min.x && max.y >= min.y && max.z >= min.z, "inverted axis");

        // Allow flat faces to be optimized.
        immutable double width = max.x - min.x;
        immutable double height = max.y - min.y;
        immutable double depth = max.z - min.z;

        // assert(width > 0 || height > 0 || depth > 0, "this cube is nothing!");

        if (width == 0) {
            // writeln("squishing on X axis");
            faceGeneration.front = false;
            faceGeneration.back = false;
            faceGeneration.top = false;
            faceGeneration.bottom = false;
        } else if (height == 0) {
            // writeln("squishing on Y axis");
            faceGeneration.front = false;
            faceGeneration.back = false;
            faceGeneration.left = false;
            faceGeneration.right = false;
        } else if (depth == 0) {
            // writeln("squishing on Z axis");
            faceGeneration.left = false;
            faceGeneration.right = false;
            faceGeneration.top = false;
            faceGeneration.bottom = false;
        }

        // Shift into position.
        immutable Vec3d chunkPositionMin = vec3dAdd(position, min);
        immutable Vec3d chunkPositionMax = vec3dAdd(position, max);

        void makeQuad(
            const Vec3d topLeft, /*0*/
            const Vec3d bottomLeft, /*1*/
            const Vec3d bottomRight, /*2*/
            const Vec3d topRight, /*3*/
            const Normal thisNormal,
            const ubyte lightValue) {

            // Done like this to attempt to improve cache performance.

            // Tri 1 vertices.

            // 0
            vertices[vertIndex] = topLeft.x;
            vertices[vertIndex + 1] = topLeft.y;
            vertices[vertIndex + 2] = topLeft.z;

            // 1
            vertices[vertIndex + 3] = bottomLeft.x;
            vertices[vertIndex + 4] = bottomLeft.y;
            vertices[vertIndex + 5] = bottomLeft.z;

            // 2
            vertices[vertIndex + 6] = bottomRight.x;
            vertices[vertIndex + 7] = bottomRight.y;
            vertices[vertIndex + 8] = bottomRight.z;

            // Tri 2 vertices.

            // 2
            vertices[vertIndex + 9] = bottomRight.x;
            vertices[vertIndex + 10] = bottomRight.y;
            vertices[vertIndex + 11] = bottomRight.z;

            // 3
            vertices[vertIndex + 12] = topRight.x;
            vertices[vertIndex + 13] = topRight.y;
            vertices[vertIndex + 14] = topRight.z;

            // 0
            vertices[vertIndex + 15] = topLeft.x;
            vertices[vertIndex + 16] = topLeft.y;
            vertices[vertIndex + 17] = topLeft.z;

            // Tri 1 normals.

            // 0
            normals[vertIndex] = thisNormal.x;
            normals[vertIndex + 1] = thisNormal.y;
            normals[vertIndex + 2] = thisNormal.z;

            // 1
            normals[vertIndex + 3] = thisNormal.x;
            normals[vertIndex + 4] = thisNormal.y;
            normals[vertIndex + 5] = thisNormal.z;

            // 2
            normals[vertIndex + 6] = thisNormal.x;
            normals[vertIndex + 7] = thisNormal.y;
            normals[vertIndex + 8] = thisNormal.z;

            // Tri 2 normals.

            // 2
            normals[vertIndex + 9] = thisNormal.x;
            normals[vertIndex + 10] = thisNormal.y;
            normals[vertIndex + 11] = thisNormal.z;

            // 3
            normals[vertIndex + 12] = thisNormal.x;
            normals[vertIndex + 13] = thisNormal.y;
            normals[vertIndex + 14] = thisNormal.z;

            // 0
            normals[vertIndex + 15] = thisNormal.x;
            normals[vertIndex + 16] = thisNormal.y;
            normals[vertIndex + 17] = thisNormal.z;

            // Tri 1 colors.

            const ubyte outputColor = cast(ubyte)(lightValue * cast(ubyte)16);

            // 0
            colors[colorIndex] = outputColor;
            colors[colorIndex + 1] = outputColor;
            colors[colorIndex + 2] = outputColor;
            colors[colorIndex + 3] = 255;

            // 1
            colors[colorIndex + 4] = outputColor;
            colors[colorIndex + 5] = outputColor;
            colors[colorIndex + 6] = outputColor;
            colors[colorIndex + 7] = 255;

            // 2
            colors[colorIndex + 8] = outputColor;
            colors[colorIndex + 9] = outputColor;
            colors[colorIndex + 10] = outputColor;
            colors[colorIndex + 11] = 255;

            // Tri 2 colors.

            // 2
            colors[colorIndex + 12] = outputColor;
            colors[colorIndex + 13] = outputColor;
            colors[colorIndex + 14] = outputColor;
            colors[colorIndex + 15] = 255;

            // 3
            colors[colorIndex + 16] = outputColor;
            colors[colorIndex + 17] = outputColor;
            colors[colorIndex + 18] = outputColor;
            colors[colorIndex + 19] = 255;

            // 0
            colors[colorIndex + 20] = outputColor;
            colors[colorIndex + 21] = outputColor;
            colors[colorIndex + 22] = outputColor;
            colors[colorIndex + 23] = 255;

            vertIndex += 18;
            colorIndex += 24;

        }

        void makeTextureQuad(
            const Vec2d topLeft,
            const Vec2d bottomLeft,
            const Vec2d bottomRight,
            const Vec2d topRight,
        ) {

            // Tri 1.

            // 0
            textureCoordinates[textIndex] = topLeft.x;
            textureCoordinates[textIndex + 1] = topLeft.y;

            //1
            textureCoordinates[textIndex + 2] = bottomLeft.x;
            textureCoordinates[textIndex + 3] = bottomLeft.y;

            //2
            textureCoordinates[textIndex + 4] = bottomRight.x;
            textureCoordinates[textIndex + 5] = bottomRight.y;

            // Tri 2.

            // 2
            textureCoordinates[textIndex + 6] = bottomRight.x;
            textureCoordinates[textIndex + 7] = bottomRight.y;

            //3
            textureCoordinates[textIndex + 8] = topRight.x;
            textureCoordinates[textIndex + 9] = topRight.y;

            // 0
            textureCoordinates[textIndex + 10] = topLeft.x;
            textureCoordinates[textIndex + 11] = topLeft.y;

            textIndex += 12;
        }

        /*
		This is kind of weird.

		Right handed means that you're looking forwards pointing at -Z.
		Left is -X, right is +x.

		But the math is using actual player coordinates so that means that Z is technically inverted.
		But we math that right out and pretend it's normal.

		So the chunk will generate behind you and to your right when your yaw is at 0 (facing forwards).
		*/

        // Front.
        if (faceGeneration.front) {
            makeQuad(
                Vec3d(chunkPositionMax.x, chunkPositionMax.y, chunkPositionMin.z),
                Vec3d(chunkPositionMax.x, chunkPositionMin.y, chunkPositionMin.z),
                Vec3d(chunkPositionMin.x, chunkPositionMin.y, chunkPositionMin.z),
                Vec3d(chunkPositionMin.x, chunkPositionMax.y, chunkPositionMin.z),
                Normal.Front,
                faceGeneration.lightLevelFront
            );

            TexPoints points = TextureHandler.getPointsByID(textures.front);
            const(Vec2d*) textureSize = TextureHandler.getSizeByID(textures.front);

            immutable double bottomTrim = min.y * textureSize.y;
            immutable double topTrim = (1.0 - max.y) * textureSize.y;
            // These are flipped in application because you're looking at them from the front.
            immutable double leftTrim = min.x * textureSize.x;
            immutable double rightTrim = (1.0 - max.x) * textureSize.x;

            makeTextureQuad(
                Vec2d(points.topLeft.x + rightTrim, points.topLeft.y + topTrim),
                Vec2d(points.bottomLeft.x + rightTrim, points.bottomLeft.y - bottomTrim),
                Vec2d(points.bottomRight.x - leftTrim, points.bottomRight.y - bottomTrim),
                Vec2d(points.topRight.x - leftTrim, points.topRight.y + topTrim),
            );
        }

        // Back.
        if (faceGeneration.back) {
            makeQuad(
                Vec3d(chunkPositionMin.x, chunkPositionMax.y, chunkPositionMax.z),
                Vec3d(chunkPositionMin.x, chunkPositionMin.y, chunkPositionMax.z),
                Vec3d(chunkPositionMax.x, chunkPositionMin.y, chunkPositionMax.z),
                Vec3d(chunkPositionMax.x, chunkPositionMax.y, chunkPositionMax.z),
                Normal.Back,
                faceGeneration.lightLevelBack
            );

            TexPoints points = TextureHandler.getPointsByID(textures.back);
            const(Vec2d*) textureSize = TextureHandler.getSizeByID(textures.back);

            immutable double bottomTrim = min.y * textureSize.y;
            immutable double topTrim = (1.0 - max.y) * textureSize.y;

            immutable double leftTrim = min.x * textureSize.x;
            immutable double rightTrim = (1.0 - max.x) * textureSize.x;

            makeTextureQuad(
                Vec2d(points.topLeft.x + leftTrim, points.topLeft.y + topTrim),
                Vec2d(points.bottomLeft.x + leftTrim, points.bottomLeft.y - bottomTrim),
                Vec2d(points.bottomRight.x - rightTrim, points.bottomRight.y - bottomTrim),
                Vec2d(points.topRight.x - rightTrim, points.topRight.y + topTrim),
            );
        }

        // Left.
        if (faceGeneration.left) {
            makeQuad(
                Vec3d(chunkPositionMin.x, chunkPositionMax.y, chunkPositionMin.z),
                Vec3d(chunkPositionMin.x, chunkPositionMin.y, chunkPositionMin.z),
                Vec3d(chunkPositionMin.x, chunkPositionMin.y, chunkPositionMax.z),
                Vec3d(chunkPositionMin.x, chunkPositionMax.y, chunkPositionMax.z),
                Normal.Left,
                faceGeneration.lightLevelLeft
            );

            TexPoints points = TextureHandler.getPointsByID(textures.left);
            const(Vec2d*) textureSize = TextureHandler.getSizeByID(textures.left);

            // Z axis gets kind of weird since it's inverted.

            immutable double bottomTrim = min.y * textureSize.y;
            immutable double topTrim = (1.0 - max.y) * textureSize.y;

            immutable double backTrim = min.z * textureSize.x;
            immutable double frontTrim = (1.0 - max.z) * textureSize.x;

            makeTextureQuad(
                Vec2d(points.topLeft.x + backTrim, points.topLeft.y + topTrim),
                Vec2d(points.bottomLeft.x + backTrim, points.bottomLeft.y - bottomTrim),
                Vec2d(points.bottomRight.x - frontTrim, points.bottomRight.y - bottomTrim),
                Vec2d(points.topRight.x - frontTrim, points.topRight.y + topTrim),
            );
        }

        // Right.
        if (faceGeneration.right) {
            makeQuad(
                Vec3d(chunkPositionMax.x, chunkPositionMax.y, chunkPositionMax.z),
                Vec3d(chunkPositionMax.x, chunkPositionMin.y, chunkPositionMax.z),
                Vec3d(chunkPositionMax.x, chunkPositionMin.y, chunkPositionMin.z),
                Vec3d(chunkPositionMax.x, chunkPositionMax.y, chunkPositionMin.z),
                Normal.Right,
                faceGeneration.lightLevelRight
            );

            TexPoints points = TextureHandler.getPointsByID(textures.right);
            const(Vec2d*) textureSize = TextureHandler.getSizeByID(textures.right);

            immutable double bottomTrim = min.y * textureSize.y;
            immutable double topTrim = (1.0 - max.y) * textureSize.y;

            immutable double backTrim = min.z * textureSize.x;
            immutable double frontTrim = (1.0 - max.z) * textureSize.x;

            makeTextureQuad(
                Vec2d(points.topLeft.x + frontTrim, points.topLeft.y + topTrim),
                Vec2d(points.bottomLeft.x + frontTrim, points.bottomLeft.y - bottomTrim),
                Vec2d(points.bottomRight.x - backTrim, points.bottomRight.y - bottomTrim),
                Vec2d(points.topRight.x - backTrim, points.topRight.y + topTrim),
            );
        }

        // Top of top points towards -Z.
        // Top.
        if (faceGeneration.top) {
            makeQuad(
                Vec3d(chunkPositionMin.x, chunkPositionMax.y, chunkPositionMin.z),
                Vec3d(chunkPositionMin.x, chunkPositionMax.y, chunkPositionMax.z),
                Vec3d(chunkPositionMax.x, chunkPositionMax.y, chunkPositionMax.z),
                Vec3d(chunkPositionMax.x, chunkPositionMax.y, chunkPositionMin.z),
                Normal.Top,
                faceGeneration.lightLevelTop
            );

            TexPoints points = TextureHandler.getPointsByID(textures.top);
            const(Vec2d*) textureSize = TextureHandler.getSizeByID(textures.top);

            immutable double leftTrim = min.x * textureSize.x;
            immutable double rightTrim = (1.0 - max.x) * textureSize.x;

            immutable double backTrim = min.z * textureSize.y;
            immutable double frontTrim = (1.0 - max.z) * textureSize.y;

            makeTextureQuad(
                Vec2d(points.topLeft.x + leftTrim, points.topLeft.y + backTrim),
                Vec2d(points.bottomLeft.x + leftTrim, points.bottomLeft.y - frontTrim),
                Vec2d(points.bottomRight.x - rightTrim, points.bottomRight.y - frontTrim),
                Vec2d(points.topRight.x - rightTrim, points.topRight.y + backTrim),
            );

        }

        // Top of bottom points towards -Z.
        // Bottom.
        if (faceGeneration.bottom) {
            makeQuad(
                Vec3d(chunkPositionMax.x, chunkPositionMin.y, chunkPositionMin.z),
                Vec3d(chunkPositionMax.x, chunkPositionMin.y, chunkPositionMax.z),
                Vec3d(chunkPositionMin.x, chunkPositionMin.y, chunkPositionMax.z),
                Vec3d(chunkPositionMin.x, chunkPositionMin.y, chunkPositionMin.z),
                Normal.Bottom,
                faceGeneration.lightLevelBottom
            );

            // This face is extremely confusing to visualize because one axis is inverted,
            // and the the whole thing is upside down.

            TexPoints points = TextureHandler.getPointsByID(textures.bottom);
            const(Vec2d*) textureSize = TextureHandler.getSizeByID(textures.bottom);

            immutable double leftTrim = min.x * textureSize.x;
            immutable double rightTrim = (1.0 - max.x) * textureSize.x;

            immutable double backTrim = min.z * textureSize.y;
            immutable double frontTrim = (1.0 - max.z) * textureSize.y;

            makeTextureQuad(
                Vec2d(points.topLeft.x + rightTrim, points.topLeft.y + backTrim),
                Vec2d(points.bottomLeft.x + rightTrim, points.bottomLeft.y - frontTrim),
                Vec2d(points.bottomRight.x - leftTrim, points.bottomRight.y - frontTrim),
                Vec2d(points.topRight.x - leftTrim, points.topRight.y + backTrim),
            );
        }
    }
}
