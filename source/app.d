import controls.keyboard;
import controls.mouse;
import game.block_database;
import game.map;
import game.map_graphics;
import game.player;
import graphics.camera_handler;
import graphics.model_handler;
import graphics.texture_handler;
import math.aabb;
import math.vec2d;
import math.vec2i;
import math.vec3d;
import math.vec3i;
import mods.api;
import raylib;
import std.conv;
import std.format;
import std.random;
import std.stdio;
import std.string;
import utility.garbage_collector;
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

	Mouse.lock();

	immutable int renderDistance = 16;
	foreach (immutable x; -renderDistance .. renderDistance) {
		foreach (immutable z; -renderDistance .. renderDistance) {
			if (vec2dDistance(Vec2d(), Vec2d(x, z)) <= renderDistance) {
				Map.debugGenerate(x, z);
			}
		}
	}

	auto rand = Random(unpredictableSeed());

	bool drawWorld = true;

	while (Window.shouldStayOpen()) {

		if (Keyboard.isPressed(KeyboardKey.KEY_F1)) {
			Window.toggleMaximize();
		}
		if (Keyboard.isPressed(KeyboardKey.KEY_F2)) {
			Mouse.toggleLock();
		}

		if (Keyboard.isPressed(KeyboardKey.KEY_F3)) {
			drawWorld = !drawWorld;

		}

		// foreach (_; 0 .. uniform(1_000, 100_000, rand)) {
		// 	Vec3d target;
		// 	target.x = uniform(0.0, 48.0, rand);
		// 	target.z = uniform(0.0, 16.0, rand);
		// 	target.y = uniform(0.0, 256.0, rand);

		// 	int blockID = uniform(0, 5, rand);

		// 	Map.setBlockAtWorldPositionByID(target, blockID);
		// }

		if (Mouse.isLocked()) {
			CameraHandler.firstPersonControls();
		}

		Player.doControls();
		CameraHandler.updateToPlayerPosition();
		Player.move();

		const Vec3i playerBlockSelection = Player.getBlockSelection();

		// Primitive digging prototype.
		if (playerBlockSelection.y != -1) {
			if (Mouse.isButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
				Map.setBlockAtWorldPositionByID(Vec3d(playerBlockSelection.x, playerBlockSelection.y, playerBlockSelection
						.z), 0);
			}
		}

		BeginDrawing();
		ClearBackground(Colors.RAYWHITE);
		CameraHandler.begin();
		{
			if (drawWorld) {
				Map.draw();
			}
			// Player.draw();

			if (playerBlockSelection.y != -1) {
				DrawCubeWires(vec3dAdd(Vec3d(playerBlockSelection.x, playerBlockSelection.y, playerBlockSelection
						.z), Vec3d(0.5, 0.5, 0.5)).toRaylib(), 1.01, 1.01, 1.01, Colors.BLACK);
			}

		}
		CameraHandler.end();

		// TODO: MAKE THAT FONT LIBRARY FUNCTION AGAIN OR SO HELP ME
		DrawText(toStringz("FPS:" ~ to!string(GetFPS())), 10, 10, 30, Colors.BLACK);
		DrawText(toStringz("FPS:" ~ to!string(GetFPS())), 11, 11, 30, Colors.BLUE);

		const double gcHeapTotal = GarbageCollector.getHeapInfo();
		DrawText(toStringz("Heap:" ~ format("%.2f", gcHeapTotal) ~ "mb"), 10, 40, 30, Colors.BLACK);
		DrawText(toStringz("Heap:" ~ format("%.2f", gcHeapTotal) ~ "mb"), 11, 41, 30, Colors.BLUE);
		Vec3d pos = Player.getPosition();
		DrawText(toStringz("X:" ~ format("%.2f", pos.x)), 10, 70, 30, Colors.BLACK);
		DrawText(toStringz("X:" ~ format("%.2f", pos.x)), 11, 71, 30, Colors.BLUE);
		DrawText(toStringz("Y:" ~ format("%.2f", pos.y)), 10, 100, 30, Colors.BLACK);
		DrawText(toStringz("Y:" ~ format("%.2f", pos.y)), 11, 101, 30, Colors.BLUE);
		DrawText(toStringz("Z:" ~ format("%.2f", pos.z)), 10, 130, 30, Colors.BLACK);
		DrawText(toStringz("Z:" ~ format("%.2f", pos.z)), 11, 131, 30, Colors.BLUE);
		EndDrawing();
	}

}
