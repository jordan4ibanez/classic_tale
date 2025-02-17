import graphics.camera_handler;
import raylib;
import std.stdio;

void main() {
	// call this before using raylib
	validateRaylibBinding();
	InitWindow(800, 600, "Hello, Raylib-D!");
	SetTargetFPS(60);

	CameraHandler.initialize();

	rlDisableBackfaceCulling();

	while (!WindowShouldClose()) {
		BeginDrawing();
		ClearBackground(Colors.RAYWHITE);

		CameraHandler.begin();

		{
			DrawText("Hello, World!", 400, 300, 28, Colors.BLACK);

			DrawCube(Vector3(0, 0, 0), 1, 1, 1, Colors.RED);
		}

		CameraHandler.end();
		EndDrawing();
	}
	CloseWindow();
}
