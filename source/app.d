import game.map;
import game.map_graphics;
import graphics.camera_handler;
import graphics.model_handler;
import graphics.texture_handler;
import math.vec2d;
import math.vec2i;
import math.vec3d;
import mods.api;
import raylib;
import std.conv;
import std.stdio;
import std.string;
import utility.window;

void main() {

	SetTraceLogLevel(TraceLogLevel.LOG_ERROR);

	Window.initialize();
	scope (exit) {
		Window.terminate();
	}

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

	Api.initialize();

	// FaceTextures tex = "testing.png";
	// FaceGeneration faces = AllFaces;
	// MapGraphics.makeCube(vertices, textureCoordinates, Vec3d(0, 0, 0), Vec3d(0, 0, 0), Vec3d(1, 1, 1), faces, tex);

	// ModelHandler.newModelFromMesh("triangle", vertices, textureCoordinates);

	Map.debugGenerate(0, 0);
	Vec2i blah = Vec2i(0, 0);
	MapGraphics.generate(blah);

	while (Window.shouldStayOpen()) {

		BeginDrawing();
		ClearBackground(Colors.RAYWHITE);

		// writeln(ModelHandler.modelExists("Chunk:0|0"));

		DrawText(toStringz("FPS:" ~ to!string(GetFPS())), 10, 10, 30, Colors.BLACK);

		CameraHandler.begin();

		{

			ModelHandler.draw("Chunk:0|0", Vec3d(0, 0, 0));

			// ModelHandler.draw("triangle", Vec3d(0, 0, 0));

			// DrawCube(Vector3(0, 0, 0), 0.1, 0.1, 0.1, Colors.RED);
		}

		CameraHandler.end();
		EndDrawing();
	}

}
