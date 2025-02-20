import core.memory;
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
import std.format;
import std.random;
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

	// rlDisableBackfaceCulling();

	// FaceTextures tex = "testing.png";
	// FaceGeneration faces = AllFaces;
	// MapGraphics.makeCube(vertices, textureCoordinates, Vec3d(0, 0, 0), Vec3d(0, 0, 0), Vec3d(1, 1, 1), faces, tex);

	// ModelHandler.newModelFromMesh("triangle", vertices, textureCoordinates);

	Map.debugGenerate(0, 0);
	Vec2i blah = Vec2i(0, 0);
	MapGraphics.generate(blah);

	auto rand = Random(unpredictableSeed());

	immutable ulong averager = 200;
	double[averager] GCcollection = 0;
	ulong index = 0;

	while (Window.shouldStayOpen()) {

		BeginDrawing();
		ClearBackground(Colors.RAYWHITE);

		// writeln(ModelHandler.modelExists("Chunk:0|0"));

		foreach (_; 0 .. uniform(1_000, 100_000, rand)) {
			Vec3d target;
			target.x = uniform(0.0, 16.0, rand);
			target.z = uniform(0.0, 16.0, rand);
			target.y = uniform(0.0, 256.0, rand);

			int blockID = uniform(0, 5, rand);

			Map.setBlockAtWorldPositionByID(target, blockID);
		}

		MapGraphics.generate(blah);

		CameraHandler.begin();
		{

			ModelHandler.draw("Chunk:0|0", Vec3d(0, 0, 0));

			// ModelHandler.draw("triangle", Vec3d(0, 0, 0));

			// DrawCube(Vector3(0, 0, 0), 0.1, 0.1, 0.1, Colors.RED);
		}
		CameraHandler.end();

		DrawText(toStringz("FPS:" ~ to!string(GetFPS())), 10, 10, 30, Colors.BLACK);
		DrawText(toStringz("FPS:" ~ to!string(GetFPS())), 11, 11, 30, Colors.BLUE);

		GCcollection[index] = cast(double) GC.stats().usedSize / 1_000_000.0;

		double total = 0;
		foreach (size; GCcollection) {
			total += size;
		}
		total /= averager;

		DrawText(toStringz("Heap:" ~ format("%.2f", total) ~ "mb"), 10, 40, 30, Colors.BLACK);
		DrawText(toStringz("Heap:" ~ format("%.2f", total) ~ "mb"), 11, 41, 30, Colors.BLUE);

		index++;
		if (index >= averager) {
			index = 0;
		}
		// GC.disable();

		EndDrawing();
	}

}
