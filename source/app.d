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

	// static immutable Vec3d topLeftBack = Vec3d(0, 1, 0);
	// static immutable Vec3d topRightBack = Vec3d(1, 1, 0);
	// static immutable Vec3d topLeftFront = Vec3d(0, 1, 1);
	// static immutable Vec3d topRightFront = Vec3d(1, 1, 1);

	float[] vertices = [

	];

	void makeQuad(
		const ref Vec3d topLeft, /*0*/
		const ref Vec3d bottomLeft, /*1*/
		const ref Vec3d bottomRight, /*2*/
		const ref Vec3d topRight /*3*/ ) {
		// Tri 1.
		vertices ~= topLeft.toFloatArray(); // 0
		vertices ~= bottomLeft.toFloatArray(); // 1
		vertices ~= bottomRight.toFloatArray(); // 2
		// Tri 2.
		vertices ~= bottomRight.toFloatArray(); // 2
		vertices ~= topRight.toFloatArray(); // 3
		vertices ~= topLeft.toFloatArray(); // 0

	}

	// 0.0, 1.0, 0.0, // 0
	// 	0.0, 0.0, 0.0, // 1
	// 	1.0, 0.0, 0.0, // 2

	// 	1.0, 0.0, 0.0, // 2
	// 	1.0, 1.0, 0.0, // 3
	// 	0.0, 1.0, 0.0, // 0

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
