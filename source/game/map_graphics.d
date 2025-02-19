module game.map_graphics;

import game.block_database;
import game.map;
import graphics.model_handler;
import graphics.texture_handler;
import hashset;
import math.vec2d;
import math.vec2i;
import math.vec3d;
import std.array;
import std.bitmanip;
import std.conv;
import std.datetime.stopwatch;
import std.meta;
import std.stdio;

struct FaceGeneration {
    mixin(bitfields!(
            bool, "front", 1,
            bool, "back", 1,
            bool, "left", 1,
            bool, "right", 1,
            bool, "top", 1,
            bool, "bottom", 1,
            bool, "", 2
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

pragma(inline, true)
string generateKey(const ref Vec2i input) {
    return "Chunk:" ~ to!string(input.x) ~ "|" ~ to!string(input.y);
}

static final const class MapGraphics {
static:
private:

    HashSet!Vec2i generationQueue;

public:

    void generate(const ref Vec2i chunkToGenerate) {
        generationQueue.insert(chunkToGenerate);
    }

    void __update() {
        PopResult thisResult = popQueue();
        if (!thisResult.exists) {
            return;
        }
        writeln(thisResult.data);
        createChunkMesh(thisResult.data);
    }

private:

    PopResult popQueue() {
        PopResult result;
        if (generationQueue.length == 0) {
            return result;
        }
        foreach (Vec2i key; generationQueue) {
            result.data = key;
            result.exists = true;
            break;
        }
        generationQueue.erase(result.data);
        return result;
    }

    void createChunkMesh(const ref Vec2i chunkKey) {
        const(Chunk*) thisChunk = Map.getChunkPointer(chunkKey);

        if (thisChunk is null) {
            writeln("aborting, chunk " ~ to!string(chunkKey.x) ~ " " ~ to!string(
                    chunkKey.y) ~ " does not exist.");
            return;
        }

        writeln("Generating chunk mesh " ~ to!string(chunkKey.x) ~ " " ~ to!string(chunkKey.y));

        FaceTextures faceTextures;

        auto sw = StopWatch(AutoStart.yes);

        ulong vertexAllocation = 0;
        ulong textureCoordAllocation = 0;

        // Preallocation.
        foreach (immutable x; 0 .. CHUNK_WIDTH) {
            foreach (immutable z; 0 .. CHUNK_WIDTH) {
                foreach (immutable y; 0 .. CHUNK_HEIGHT) {

                    // todo: undo this worst case scenario prototyping.
                    const BlockData* thisData = &thisChunk.data[x][z][y];

                    if (thisData.blockID == 0) {
                        continue;
                    }

                    // 3 [xyz], 6 [2 tris], 6 faces
                    vertexAllocation += 108;

                    // 2 [xy], 6 [2 tris], 6 faces
                    textureCoordAllocation += 72;

                }
            }
        }

        writeln(vertexAllocation, " ", textureCoordAllocation);

        float[] vertices = uninitializedArray!(float[])(vertexAllocation);
        float[] textureCoordinates = uninitializedArray!(float[])(textureCoordAllocation);

        ulong vertIndex = 0;
        ulong textIndex = 0;

        FaceGeneration faceGen = AllFaces;

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

                    const pos = Vec3d(x, y, z);

                    makeCube(vertIndex, textIndex, vertices.ptr, textureCoordinates.ptr, pos, Vec3d(0, 0, 0),
                        Vec3d(1, 1, 1), &faceGen, &faceTextures);

                }
            }
        }

        writeln("took: ", sw.peek().total!"msecs", "ms");

        const string chunkMeshKey = generateKey(chunkKey);

        if (ModelHandler.modelExists(chunkMeshKey)) {
            writeln("exists");
        } else {
            writeln("does not exist, creating");
            ModelHandler.newModelFromMesh(chunkMeshKey, vertices, textureCoordinates, true);
        }

    }

    // Maybe this can have a numeric AA or array to hash this in immediate mode?
    // pragma(inline)
    void makeCube(ref ulong vertIndex, ref ulong textIndex, float* vertices, float* textureCoordinates,
        const Vec3d position, Vec3d min, Vec3d max, FaceGeneration faceGeneration, FaceTextures textures) {

        assert(min.x >= 0 && min.y >= 0 && min.z >= 0, "min is out of bounds");
        assert(max.x <= 1 && max.y <= 1 && max.z <= 1, "max is out of bounds");
        assert(max.x >= min.x && max.y >= min.y && max.z >= min.z, "inverted axis");

        // Allow flat faces to be optimized.
        immutable double width = max.x - min.x;
        immutable double height = max.y - min.y;
        immutable double depth = max.z - min.z;

        assert(width > 0 || height > 0 || depth > 0, "this cube is nothing!");

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

        // pragma(inline, true)
        void makeQuad(
            const Vec3d topLeft, /*0*/
            const Vec3d bottomLeft, /*1*/
            const Vec3d bottomRight, /*2*/
            const Vec3d topRight /*3*/ ) {
            // Tri 1.

            // 0
            vertices[vertIndex] = topLeft.x;
            vertices[vertIndex + 1] = topLeft.y;
            vertices[vertIndex + 2] = topLeft.z;
            // vertIndex += 3;

            // 1
            vertices[vertIndex + 3] = bottomLeft.x;
            vertices[vertIndex + 4] = bottomLeft.y;
            vertices[vertIndex + 5] = bottomLeft.z;

            // 2
            vertices[vertIndex + 6] = bottomRight.x;
            vertices[vertIndex + 7] = bottomRight.y;
            vertices[vertIndex + 8] = bottomRight.z;

            // Tri 2.

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

            vertIndex += 18;

        }

        // pragma(inline, true)
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
                Vec3d(chunkPositionMin.x, chunkPositionMax.y, chunkPositionMin.z)
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
                Vec3d(chunkPositionMax.x, chunkPositionMax.y, chunkPositionMax.z)
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
                Vec3d(chunkPositionMin.x, chunkPositionMax.y, chunkPositionMax.z)
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
                Vec3d(chunkPositionMax.x, chunkPositionMax.y, chunkPositionMin.z)
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
                Vec3d(chunkPositionMax.x, chunkPositionMax.y, chunkPositionMin.z)
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
                Vec3d(chunkPositionMin.x, chunkPositionMin.y, chunkPositionMin.z)
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
