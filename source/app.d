import graphics.camera_handler;
import graphics.model_handler;
import graphics.texture_handler;
import math.vec2d;
import math.vec3d;
import raylib;
import std.stdio;

void main() {
	// call this before using raylib
	validateRaylibBinding();
	InitWindow(800, 600, "Classic Fable Prototyping");
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

	So the chunk will generate behind you and to your right.
	*/

	makeQuad(
		Vec3d(1, 1, 0),
		Vec3d(1, 0, 0),
		Vec3d(0, 0, 0),
		Vec3d(0, 1, 0)
	);

	// static immutable Vec3d topLeftBack = Vec3d(0, 1, 0);
	// static immutable Vec3d topRightBack = Vec3d(1, 1, 0);
	// static immutable Vec3d topLeftFront = Vec3d(0, 1, 1);
	// static immutable Vec3d topRightFront = Vec3d(1, 1, 1);

	// 0.0, 1.0, 0.0, // 0
	// 	0.0, 0.0, 0.0, // 1
	// 	1.0, 0.0, 0.0, // 2
	// 	1.0, 0.0, 0.0, // 2

	TexPoints blah = TextureHandler.getPoints("testing.png");

	float[] textureCoordinates = [
		blah.topLeft.x, blah.topLeft.y, // 0
		blah.bottomLeft.x, blah.bottomLeft.y, // 1
		blah.bottomRight.x, blah.bottomRight.y, // 2

		blah.bottomRight.x, blah.bottomRight.y, // 2
		blah.topRight.x, blah.topRight.y, // 3
		blah.topLeft.x, blah.topLeft.y, // 0
	];

	ModelHandler.newModelFromMesh("triangle", vertices, textureCoordinates);

	while (!WindowShouldClose()) {
		BeginDrawing();
		ClearBackground(Colors.RAYWHITE);

		DrawText("Hello, World!", 10, 10, 28, Colors.BLACK);

		CameraHandler.begin();

		{

			ModelHandler.draw("triangle", Vec3d(0, 0, 0));

			// DrawCube(Vector3(0, 0, -5), 1, 1, 1, Colors.RED);
		}

		CameraHandler.end();
		EndDrawing();
	}

}
