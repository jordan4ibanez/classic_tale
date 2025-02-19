module game.map_graphics;

import graphics.texture_handler;
import hashset;
import math.vec2d;
import math.vec2i;
import math.vec3d;
import std.bitmanip;
import std.meta;

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
    string front = null;
    string back = null;
    string left = null;
    string right = null;
    string top = null;
    string bottom = null;

    this(string allFaces) {
        foreach (ref component; this.tupleof) {
            component = allFaces;
        }
    }
}

private struct PopResult {
    bool exists = false;
    Vec2i data;
}

static final const class MapGraphics {
static:
private:

    HashSet!Vec2i generationQueue;

public:

    void generate(Vec2i chunkToGenerate) {
        generationQueue.insert(chunkToGenerate);
    }

private:

    PopResult pop() {
        PopResult result;
        foreach (Vec2i key; generationQueue) {
            result.data = key;
            result.exists = true;
            break;
        }
        if (result.exists) {
            generationQueue.erase(result.data);
        }
        return result;
    }

    // Maybe this can have a numeric AA or array to hash this in immediate mode?
    void makeCube(ref float[] vertices, ref float[] textureCoordinates, const Vec3d position, Vec3d min, Vec3d max,
        FaceGeneration faceGeneration, FaceTextures textures) {

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

        pragma(inline, true)
        void makeQuad(
            const Vec3d topLeft, /*0*/
            const Vec3d bottomLeft, /*1*/
            const Vec3d bottomRight, /*2*/
            const Vec3d topRight /*3*/ ) {
            // Tri 1.
            vertices ~= topLeft.toFloatArray(); // 0
            vertices ~= bottomLeft.toFloatArray(); // 1
            vertices ~= bottomRight.toFloatArray(); // 2
            // Tri 2.
            vertices ~= bottomRight.toFloatArray(); // 2
            vertices ~= topRight.toFloatArray(); // 3
            vertices ~= topLeft.toFloatArray(); // 0
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

            TexPoints points = TextureHandler.getPoints(textures.front);
            immutable Vec2d textureSize = TextureHandler.getSize(textures.front);

            immutable double bottomTrim = min.y * textureSize.y;
            immutable double topTrim = (1.0 - max.y) * textureSize.y;
            // These are flipped in application because you're looking at them from the front.
            immutable double leftTrim = min.x * textureSize.x;
            immutable double rightTrim = (1.0 - max.x) * textureSize.x;

            textureCoordinates ~= [
                points.topLeft.x + rightTrim, points.topLeft.y + topTrim, // 0
                points.bottomLeft.x + rightTrim, points.bottomLeft.y - bottomTrim, // 1
                points.bottomRight.x - leftTrim, points.bottomRight.y - bottomTrim, // 2
                points.bottomRight.x - leftTrim, points.bottomRight.y - bottomTrim, // 2
                points.topRight.x - leftTrim, points.topRight.y + topTrim, // 3
                points.topLeft.x + rightTrim, points.topLeft.y + topTrim, // 0
            ];

        }

        // Back.
        if (faceGeneration.back) {
            makeQuad(
                Vec3d(chunkPositionMin.x, chunkPositionMax.y, chunkPositionMax.z),
                Vec3d(chunkPositionMin.x, chunkPositionMin.y, chunkPositionMax.z),
                Vec3d(chunkPositionMax.x, chunkPositionMin.y, chunkPositionMax.z),
                Vec3d(chunkPositionMax.x, chunkPositionMax.y, chunkPositionMax.z)
            );

            TexPoints points = TextureHandler.getPoints(textures.back);
            immutable Vec2d textureSize = TextureHandler.getSize(textures.back);

            immutable double bottomTrim = min.y * textureSize.y;
            immutable double topTrim = (1.0 - max.y) * textureSize.y;

            immutable double leftTrim = min.x * textureSize.x;
            immutable double rightTrim = (1.0 - max.x) * textureSize.x;

            textureCoordinates ~= [
                points.topLeft.x + leftTrim, points.topLeft.y + topTrim, // 0
                points.bottomLeft.x + leftTrim, points.bottomLeft.y - bottomTrim, // 1
                points.bottomRight.x - rightTrim, points.bottomRight.y - bottomTrim, // 2
                points.bottomRight.x - rightTrim, points.bottomRight.y - bottomTrim, // 2
                points.topRight.x - rightTrim, points.topRight.y + topTrim, // 3
                points.topLeft.x + leftTrim, points.topLeft.y + topTrim, // 0
            ];
        }

        // Left.
        if (faceGeneration.left) {
            makeQuad(
                Vec3d(chunkPositionMin.x, chunkPositionMax.y, chunkPositionMin.z),
                Vec3d(chunkPositionMin.x, chunkPositionMin.y, chunkPositionMin.z),
                Vec3d(chunkPositionMin.x, chunkPositionMin.y, chunkPositionMax.z),
                Vec3d(chunkPositionMin.x, chunkPositionMax.y, chunkPositionMax.z)
            );

            TexPoints points = TextureHandler.getPoints(textures.left);
            immutable Vec2d textureSize = TextureHandler.getSize(textures.left);

            // Z axis gets kind of weird since it's inverted.

            immutable double bottomTrim = min.y * textureSize.y;
            immutable double topTrim = (1.0 - max.y) * textureSize.y;

            immutable double backTrim = min.z * textureSize.x;
            immutable double frontTrim = (1.0 - max.z) * textureSize.x;

            textureCoordinates ~= [
                points.topLeft.x + backTrim, points.topLeft.y + topTrim, // 0
                points.bottomLeft.x + backTrim, points.bottomLeft.y - bottomTrim, // 1
                points.bottomRight.x - frontTrim, points.bottomRight.y - bottomTrim, // 2
                points.bottomRight.x - frontTrim, points.bottomRight.y - bottomTrim, // 2
                points.topRight.x - frontTrim, points.topRight.y + topTrim, // 3
                points.topLeft.x + backTrim, points.topLeft.y + topTrim, // 0
            ];
        }

        // Right.
        if (faceGeneration.right) {
            makeQuad(
                Vec3d(chunkPositionMax.x, chunkPositionMax.y, chunkPositionMax.z),
                Vec3d(chunkPositionMax.x, chunkPositionMin.y, chunkPositionMax.z),
                Vec3d(chunkPositionMax.x, chunkPositionMin.y, chunkPositionMin.z),
                Vec3d(chunkPositionMax.x, chunkPositionMax.y, chunkPositionMin.z)
            );

            TexPoints points = TextureHandler.getPoints(textures.right);
            immutable Vec2d textureSize = TextureHandler.getSize(textures.right);

            immutable double bottomTrim = min.y * textureSize.y;
            immutable double topTrim = (1.0 - max.y) * textureSize.y;

            immutable double backTrim = min.z * textureSize.x;
            immutable double frontTrim = (1.0 - max.z) * textureSize.x;

            textureCoordinates ~= [
                points.topLeft.x + frontTrim, points.topLeft.y + topTrim, // 0
                points.bottomLeft.x + frontTrim, points.bottomLeft.y - bottomTrim, // 1
                points.bottomRight.x - backTrim, points.bottomRight.y - bottomTrim, // 2
                points.bottomRight.x - backTrim, points.bottomRight.y - bottomTrim, // 2
                points.topRight.x - backTrim, points.topRight.y + topTrim, // 3
                points.topLeft.x + frontTrim, points.topLeft.y + topTrim, // 0
            ];
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

            TexPoints points = TextureHandler.getPoints(textures.top);
            immutable Vec2d textureSize = TextureHandler.getSize(textures.top);

            immutable double leftTrim = min.x * textureSize.x;
            immutable double rightTrim = (1.0 - max.x) * textureSize.x;

            immutable double backTrim = min.z * textureSize.y;
            immutable double frontTrim = (1.0 - max.z) * textureSize.y;

            textureCoordinates ~= [
                points.topLeft.x + leftTrim, points.topLeft.y + backTrim, // 0
                points.bottomLeft.x + leftTrim, points.bottomLeft.y - frontTrim, // 1
                points.bottomRight.x - rightTrim, points.bottomRight.y - frontTrim, // 2

                points.bottomRight.x - rightTrim, points.bottomRight.y - frontTrim, // 2
                points.topRight.x - rightTrim, points.topRight.y + backTrim, // 3
                points.topLeft.x + leftTrim, points.topLeft.y + backTrim, // 0
            ];

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

            TexPoints points = TextureHandler.getPoints(textures.bottom);
            immutable Vec2d textureSize = TextureHandler.getSize(textures.bottom);

            immutable double leftTrim = min.x * textureSize.x;
            immutable double rightTrim = (1.0 - max.x) * textureSize.x;

            immutable double backTrim = min.z * textureSize.y;
            immutable double frontTrim = (1.0 - max.z) * textureSize.y;

            textureCoordinates ~= [
                points.topLeft.x + rightTrim, points.topLeft.y + backTrim, // 0
                points.bottomLeft.x + rightTrim, points.bottomLeft.y - frontTrim, // 1
                points.bottomRight.x - leftTrim, points.bottomRight.y - frontTrim, // 2
                points.bottomRight.x - leftTrim, points.bottomRight.y - frontTrim, // 2
                points.topRight.x - leftTrim, points.topRight.y + backTrim, // 3
                points.topLeft.x + rightTrim, points.topLeft.y + backTrim, // 0
            ];
        }
    }
}
