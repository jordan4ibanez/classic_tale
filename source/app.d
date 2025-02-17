import raylib;
import std.stdio;

import math.quat;
import math.vec3d;

void main() {
	// call this before using raylib
	validateRaylibBinding();
	InitWindow(800, 600, "Hello, Raylib-D!");
	SetTargetFPS(60);

	Quat blah = Quat();

	writeln(blah);

	Vec3d boof = Vec3d();
	writeln(boof);
	while (!WindowShouldClose()) {
		BeginDrawing();
		ClearBackground(Colors.RAYWHITE);
		DrawText("Hello, World!", 400, 300, 28, Colors.BLACK);
		EndDrawing();
	}
	CloseWindow();
}
