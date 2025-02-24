import controls.keyboard;
import controls.mouse;
import game.block_database;
import game.map;
import game.map_graphics;
import game.player;
import graphics.camera_handler;
import graphics.gui;
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

		// Primitive placing prototype.
		if (Mouse.isButtonPressed(MouseButton.MOUSE_BUTTON_RIGHT)) {
			const Vec3i playerBlockSelectionAbove = Player.getBlockSelectionAbove();
			if (playerBlockSelectionAbove.y != -1) {
				Vec3d blockSelectionABove = Vec3d(playerBlockSelectionAbove.x, playerBlockSelectionAbove.y,
					playerBlockSelectionAbove.z);
				if (Map.getBlockAtWorldPosition(blockSelectionABove).blockID == 0) {
					// Do not allow the player to be in the new collisionbox.
					AABB possiblePositionBox = AABB(blockSelectionABove.x, blockSelectionABove.y, blockSelectionABove
							.z, blockSelectionABove.x + 1.0, blockSelectionABove.y + 1.0, blockSelectionABove
							.z + 1.0);
					AABB playerCollisionBox = AABB(Player.getPosition, Player.getSize);
					DrawCubeWires(blockSelectionABove.toRaylib(), 0.05, 0.05, 0.05, Colors.RED);
					if (!aabbCollision(possiblePositionBox, playerCollisionBox)) {

						Map.setBlockAtWorldPositionByName(blockSelectionABove, "bedrock");
					}
				}

			}
		}

		//! Raycast after everything or the selectionbox will be outdated by 1 frame.
		//? Keep this last.
		Player.raycast();

		BeginDrawing();

		ClearBackground(Color(120, 166, 255, 255));

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

		{ // Draw the crosshair.

			Vec2d windowCenter = vec2dMultiply(Window.getSize(), Vec2d(0.5, 0.5));

			double guiScale = GUI.getGUIScale();

			// Size horizontal.
			//? 40, 4
			const double shx = 400.0 * guiScale;
			// Size vertical.
			const double shy = 40.0 * guiScale;
			// Half width.
			const double hx = shx * 0.5;
			// Half height.
			const double hy = shy * 0.5;
			Vector2 start, end;

			const double a = windowCenter.x - hx;
			const double b = windowCenter.y - hy;
			const double c = windowCenter.x - hy;
			const double d = windowCenter.y - hx;
			const double e = windowCenter.x + hy;
			const double f = windowCenter.x + hx;
			const double g = windowCenter.y + hy;
			const double h = windowCenter.y + hx;

			//? First pass uses subtractive blend mode.
			//? This causes issues when looking at gray things like stone.
			BeginBlendMode(BlendMode.BLEND_SUBTRACT_COLORS);
			// Horizontal.
			start.x = a;
			start.y = b;
			end.x = shx;
			end.y = shy;
			DrawRectangleV(start, end, Colors.WHITE);

			// Vertical.
			start.x = c;
			start.y = d;
			end.x = shy;
			end.y = shx;
			DrawRectangleV(start, end, Colors.WHITE);

			// Center.
			start.x = c;
			start.y = b;
			end.x = shy;
			end.y = shy;
			DrawRectangleV(start, end, Colors.WHITE);
			EndBlendMode();

			//? Second pass layers on lightness to make it stand out more.
			static immutable ULTRA_DARK_GRAY = Color(55, 55, 55, 255);
			BeginBlendMode(BlendMode.BLEND_ADD_COLORS);

			// Left
			start.x = a;
			start.y = b;
			end.x = hx - hy;
			end.y = shy;
			DrawRectangleV(start, end, ULTRA_DARK_GRAY);

			// Right
			start.x = e;
			start.y = b;
			end.x = hx - hy;
			end.y = shy;
			DrawRectangleV(start, end, ULTRA_DARK_GRAY);
			// Vertical.
			start.x = c;
			start.y = d;
			end.x = shy;
			end.y = shx;
			DrawRectangleV(start, end, ULTRA_DARK_GRAY);

			EndBlendMode();

			//? Third pass draws an outline on the cursor.

			// This starts at the top left of the vertical bar then wraps around clockwise.

			static immutable debugColor = Colors.BLACK;

			start.x = a;
			start.y = b;
			end.x = c;
			end.y = b;
			DrawLineV(start, end, debugColor);
			start.x = c;
			start.y = b;
			end.x = c;
			end.y = d;
			DrawLineV(start, end, debugColor);
			start.x = c;
			start.y = d;
			end.x = e;
			end.y = d;
			DrawLineV(start, end, debugColor);
			start.x = e;
			start.y = d;
			end.x = e;
			end.y = b;
			DrawLineV(start, end, debugColor);
			start.x = e;
			start.y = b;
			end.x = f;
			end.y = b;
			DrawLineV(start, end, debugColor);
			start.x = f;
			start.y = b;
			end.x = f;
			end.y = g;
			DrawLineV(start, end, debugColor);
			start.x = f;
			start.y = g;
			end.x = e;
			end.y = g;
			DrawLineV(start, end, debugColor);
			start.x = e;
			start.y = g;
			end.x = e;
			end.y = h;
			DrawLineV(start, end, debugColor);
			start.x = e;
			start.y = h;
			end.x = c;
			end.y = h;
			DrawLineV(start, end, debugColor);
			start.x = c;
			start.y = h;
			end.x = c;
			end.y = g;
			DrawLineV(start, end, debugColor);
			start.x = c;
			start.y = g;
			end.x = a;
			end.y = g;
			DrawLineV(start, end, debugColor);
			start.x = a;
			start.y = g;
			end.x = a;
			end.y = b;
			DrawLineV(start, end, debugColor);
		}

		EndDrawing();
	}

}
