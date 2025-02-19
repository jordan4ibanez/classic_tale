import graphics.camera_handler;
import graphics.model_handler;
import graphics.texture_handler;
import math.vec2d;
import math.vec3d;
import raylib;
import std.bitmanip;
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

void main() {
	// call this before using raylib
	SetTraceLogLevel(TraceLogLevel.LOG_ERROR);
	validateRaylibBinding();

	InitWindow(1000, 1000, "Classic Fable Prototyping");
	scope (exit) {
		CloseWindow();
	}
	SetTargetFPS(60);

	CameraHandler.initialize();
	scope (exit) {
		CameraHandler.terminate();
	}

	TextureHandler.initialize();
	scope (exit) {
		TextureHandler.terminate();
	}

	ModelHandler.initialize();
	scope (exit) {
		ModelHandler.terminate();
	}

	rlDisableBackfaceCulling();

	float[] vertices;
	float[] textureCoordinates;

	// Maybe this can have a numeric AA or array to hash this in immediate mode?
	void makeCube(const Vec3d position, Vec3d min, Vec3d max, FaceGeneration faceGeneration, string[6] textures) {

		// assert(min.x >= 0 && min.y >= 0 && min.z >= 0, "min is out of bounds");
		// assert(max.x <= 1 && max.y <= 1 && max.z <= 1, "max is out of bounds");
		// assert(max.x >= min.x && max.y >= min.y && max.z >= min.z, "Inverse axis");

		// immutable Vec3d originalMin = min;
		// immutable Vec3d originalMax = max;

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

			TexPoints points = TextureHandler.getPoints(textures[0]);

			immutable Vec2d textureSize = TextureHandler.getSize(textures[0]);

			immutable double bottomTrim = min.y * textureSize.y;
			immutable double topTrim = (1.0 - max.y) * textureSize.y;

			// These are flipped in application because you're looking at them from the front.
			immutable double leftTrim = min.x * textureSize.x;
			immutable double rightTrim = (1.0 - max.x) * textureSize.x;

			textureCoordinates ~= [
				points.topLeft.x + rightTrim, points.topLeft.y + topTrim,
				points.bottomLeft.x + rightTrim, points.bottomLeft.y - bottomTrim,
				points.bottomRight.x - leftTrim, points.bottomRight.y - bottomTrim,
				points.bottomRight.x - leftTrim, points.bottomRight.y - bottomTrim,
				points.topRight.x - leftTrim, points.topRight.y + topTrim,
				points.topLeft.x + rightTrim, points.topLeft.y + topTrim,
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
		}

		// Left.
		if (faceGeneration.left) {
			makeQuad(
				Vec3d(chunkPositionMin.x, chunkPositionMax.y, chunkPositionMin.z),
				Vec3d(chunkPositionMin.x, chunkPositionMin.y, chunkPositionMin.z),
				Vec3d(chunkPositionMin.x, chunkPositionMin.y, chunkPositionMax.z),
				Vec3d(chunkPositionMin.x, chunkPositionMax.y, chunkPositionMax.z)
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
		}
	}

	string[6] tex = "testing.png";
	makeCube(Vec3d(0, 0, 0), Vec3d(0, 0, 0), Vec3d(1, 1, 1), AllFaces, tex);

	// float[] textureCoordinates = [
	// 	// Front.
	// 	blah.topLeft.x, blah.topLeft.y, // 0
	// 	blah.bottomLeft.x, blah.bottomLeft.y, // 1
	// 	blah.bottomRight.x, blah.bottomRight.y, // 2

	// 	blah.bottomRight.x, blah.bottomRight.y, // 2
	// 	blah.topRight.x, blah.topRight.y, // 3
	// 	blah.topLeft.x, blah.topLeft.y, // 0

	// 	// Back.
	// 	blah.topLeft.x, blah.topLeft.y, // 0
	// 	blah.bottomLeft.x, blah.bottomLeft.y, // 1
	// 	blah.bottomRight.x, blah.bottomRight.y, // 2

	// 	blah.bottomRight.x, blah.bottomRight.y, // 2
	// 	blah.topRight.x, blah.topRight.y, // 3
	// 	blah.topLeft.x, blah.topLeft.y, // 0

	// 	// Left.
	// 	blah.topLeft.x, blah.topLeft.y, // 0
	// 	blah.bottomLeft.x, blah.bottomLeft.y, // 1
	// 	blah.bottomRight.x, blah.bottomRight.y, // 2

	// 	blah.bottomRight.x, blah.bottomRight.y, // 2
	// 	blah.topRight.x, blah.topRight.y, // 3
	// 	blah.topLeft.x, blah.topLeft.y, // 0

	// 	// Right.
	// 	blah.topLeft.x, blah.topLeft.y, // 0
	// 	blah.bottomLeft.x, blah.bottomLeft.y, // 1
	// 	blah.bottomRight.x, blah.bottomRight.y, // 2

	// 	blah.bottomRight.x, blah.bottomRight.y, // 2
	// 	blah.topRight.x, blah.topRight.y, // 3
	// 	blah.topLeft.x, blah.topLeft.y, // 0

	// 	// Top.
	// 	blah.topLeft.x, blah.topLeft.y, // 0
	// 	blah.bottomLeft.x, blah.bottomLeft.y, // 1
	// 	blah.bottomRight.x, blah.bottomRight.y, // 2

	// 	blah.bottomRight.x, blah.bottomRight.y, // 2
	// 	blah.topRight.x, blah.topRight.y, // 3
	// 	blah.topLeft.x, blah.topLeft.y, // 0

	// 	// Bottom.
	// 	blah.topLeft.x, blah.topLeft.y, // 0
	// 	blah.bottomLeft.x, blah.bottomLeft.y, // 1
	// 	blah.bottomRight.x, blah.bottomRight.y, // 2

	// 	blah.bottomRight.x, blah.bottomRight.y, // 2
	// 	blah.topRight.x, blah.topRight.y, // 3
	// 	blah.topLeft.x, blah.topLeft.y, // 0
	// ];

	ModelHandler.newModelFromMesh("triangle", vertices, textureCoordinates);

	while (!WindowShouldClose()) {
		BeginDrawing();
		ClearBackground(Colors.RAYWHITE);

		DrawText("Hello, World!", 10, 10, 28, Colors.BLACK);

		CameraHandler.begin();

		{

			ModelHandler.draw("triangle", Vec3d(0, 0, 0));

			DrawCube(Vector3(0, 0, 0), 0.1, 0.1, 0.1, Colors.RED);
		}

		CameraHandler.end();
		EndDrawing();
	}

}
