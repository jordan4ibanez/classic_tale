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

	float[] vertices = [
		0.0, 1.0, 0.0, // 0
		0.0, 0.0, 0.0, // 1
		1.0, 0.0, 0.0, // 2

		1.0, 0.0, 0.0, // 2
		1.0, 1.0, 0.0, // 3
		0.0, 1.0, 0.0, // 0
	];

	TexPoints blah = TextureHandler.getPoints("default_dirt.png");

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

			// DrawCube(Vector3(0, 0, 0), 1, 1, 1, Colors.RED);
		}

		CameraHandler.end();
		EndDrawing();
	}

}
