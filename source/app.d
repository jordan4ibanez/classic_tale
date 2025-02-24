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
			const Vec2d sh = vec2dMultiply(Vec2d(40, 4), Vec2d(guiScale, guiScale));
			// Size vertical;
			// const Vec2d sv = Vec2d(sh.y, sh.x);
			const double hx = sh.x * 0.5;
			// Half height.
			const double hy = sh.y * 0.5;

			//? First pass uses subtractive blend mode.
			//? This causes issues when looking at gray things like stone.
			BeginBlendMode(BlendMode.BLEND_SUBTRACT_COLORS);
			// Horizontal.
			DrawRectangleV(vec2dSubtract(windowCenter, Vec2d(hx, hy))
					.toRaylib(), sh.toRaylib(), Colors.WHITE);
			// Vertical.
			DrawRectangleV(vec2dSubtract(windowCenter, Vec2d(hy, hx))
					.toRaylib(), Vec2d(sh.y, sh.x).toRaylib(), Colors.WHITE);
			// Center.
			DrawRectangleV(vec2dSubtract(windowCenter, Vec2d(hy, hy))
					.toRaylib(), Vec2d(sh.y, sh.y).toRaylib(), Colors.WHITE);
			EndBlendMode();

			//? Second pass layers on lightness to make it stand out more.
			static immutable ULTRA_DARK_GRAY = Color(55, 55, 55, 255);
			BeginBlendMode(BlendMode.BLEND_ADD_COLORS);
			// Left
			DrawRectangleV(vec2dSubtract(windowCenter, Vec2d(hx, hy))
					.toRaylib(), Vec2d(hx - hy, sh.y).toRaylib(), ULTRA_DARK_GRAY);
			// Right
			DrawRectangleV(Vec2d(windowCenter.x + hy, windowCenter.y - hy)
					.toRaylib(), Vec2d(hx - hy, sh.y).toRaylib(), ULTRA_DARK_GRAY);
			// Vertical.
			DrawRectangleV(Vec2d(windowCenter.x - hy, windowCenter.y - hx)
					.toRaylib(), Vec2d(sh.y, sh.x).toRaylib(), ULTRA_DARK_GRAY);
			EndBlendMode();

			//? Third pass draws an outline on the cursor.

			// This starts at the top left of the vertical bar then wraps around clockwise.

			static immutable debugColor = Colors.BLACK;

			DrawLineV(Vec2d(windowCenter.x - hx, windowCenter.y - hy)
					.toRaylib(), Vec2d(windowCenter.x - hy, windowCenter.y - hy)
					.toRaylib, debugColor);

			DrawLineV(Vec2d(windowCenter.x - hy, windowCenter.y - hy)
					.toRaylib(), Vec2d(windowCenter.x - hy, windowCenter.y - hx)
					.toRaylib, debugColor);

			DrawLineV(Vec2d(windowCenter.x - hy, windowCenter.y - hx)
					.toRaylib(), Vec2d(windowCenter.x + hy, windowCenter.y - hx)
					.toRaylib, debugColor);

			DrawLineV(Vec2d(windowCenter.x + hy, windowCenter.y - hx)
					.toRaylib(), Vec2d(windowCenter.x + hy, windowCenter.y - hy)
					.toRaylib, debugColor);

			DrawLineV(Vec2d(windowCenter.x + hy, windowCenter.y - hy)
					.toRaylib(), Vec2d(windowCenter.x + hx, windowCenter.y - hy)
					.toRaylib, debugColor);

			DrawLineV(Vec2d(windowCenter.x + hx, windowCenter.y - hy)
					.toRaylib(), Vec2d(windowCenter.x + hx, windowCenter.y + hy)
					.toRaylib, debugColor);

			DrawLineV(Vec2d(windowCenter.x + hx, windowCenter.y + hy)
					.toRaylib(), Vec2d(windowCenter.x + hy, windowCenter.y + hy)
					.toRaylib, debugColor);

			DrawLineV(Vec2d(windowCenter.x + hy, windowCenter.y + hy)
					.toRaylib(), Vec2d(windowCenter.x + hy, windowCenter.y + hx)
					.toRaylib, debugColor);

			DrawLineV(Vec2d(windowCenter.x + hy, windowCenter.y + hx)
					.toRaylib(), Vec2d(windowCenter.x - hy, windowCenter.y + hx)
					.toRaylib, debugColor);

			DrawLineV(Vec2d(windowCenter.x - hy, windowCenter.y + hx)
					.toRaylib(), Vec2d(windowCenter.x - hy, windowCenter.y + hy)
					.toRaylib, debugColor);

			DrawLineV(Vec2d(windowCenter.x - hy, windowCenter.y + hy)
					.toRaylib(), Vec2d(windowCenter.x - hx, windowCenter.y + hy)
					.toRaylib, debugColor);

			DrawLineV(Vec2d(windowCenter.x - hx, windowCenter.y + hy)
					.toRaylib(), Vec2d(windowCenter.x - hx, windowCenter.y - hy)
					.toRaylib, debugColor);
		}

		EndDrawing();
	}

}
