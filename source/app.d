import controls.keyboard;
import controls.mouse;
import game.block_database;
import game.map;
import game.map_graphics;
import game.player;
import graphics.camera_handler;
import graphics.crosshair;
import graphics.gui;
import graphics.model_handler;
import graphics.shader_handler;
import graphics.texture_handler;
import math.aabb;
import math.rect;
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

	SetTraceLogLevel(TraceLogLevel.LOG_WARNING);

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

	Crosshair.initialize();

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

	//! BEGIN DEBUG DRAWING TORCH.
	// {
	// 	Camera3D cam;
	// 	cam.fovy = 55;
	// 	cam.position = Vector3(0, 3, 3);
	// 	cam.target = Vector3(0, 0, 0);
	// 	cam.up = Vector3(0, 1, 0);
	// 	cam.projection = CameraProjection.CAMERA_PERSPECTIVE;

	// 	ulong torchModel = ModelHandler.getIDFromName("torch_wall.glb");

	// 	while (Window.shouldStayOpen()) {

	// 		// UpdateCamera(&cam, CameraMode.CAMERA_ORBITAL);

	// 		// ModelHandler.

	// 		BeginDrawing();
	// 		ClearBackground(Colors.BLACK);

	// 		BeginMode3D(cam);
	// 		{

	// 			DrawCube(Vector3(0, 0.5, -0.5), 1, 1, 1, Colors.RED);
	// 			DrawCubeWires(Vector3(0, 0.5, -0.5), 1, 1, 1, Colors.BLACK);

	// 			DrawCube(Vector3(0, 0.5, -0.5), 1, 1, 1, Colors.RED);
	// 			DrawCubeWires(Vector3(0, 0.5, -0.5), 1, 1, 1, Colors.BLACK);

	// 			// Rotation 0 faces -Z, clockwise, 4 position states

	// 			ModelHandler.draw(torchModel, Vec3d(0, 0, 0.5), Vec3d(0, (PI / -2.0) * 0, 0));

	// 		}
	// 		EndMode3D();

	// 		EndDrawing();
	// 	}

	// }
	//! END DEBUG DRAWING TORCH.

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

		// if (Keyboard.isPressed(KeyboardKey.KEY_E)) {
		// 	resetDebug();
		// }

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

				if (Map.getBlockAtWorldPosition(playerBlockSelectionAbove.x, playerBlockSelectionAbove.y, playerBlockSelectionAbove
						.z).blockID == 0) {
					// Do not allow the player to be in the new collisionbox.
					AABB possiblePositionBox = AABB(blockSelectionABove.x, blockSelectionABove.y, blockSelectionABove
							.z, blockSelectionABove.x + 1.0, blockSelectionABove.y + 1.0, blockSelectionABove
							.z + 1.0);
					AABB playerCollisionBox = AABB(Player.getPosition, Player.getSize);
					DrawCubeWires(blockSelectionABove.toRaylib(), 0.05, 0.05, 0.05, Colors.RED);
					if (!aabbCollision(possiblePositionBox, playerCollisionBox)) {

						Map.setBlockAtWorldPositionByName(blockSelectionABove, "torch");

						Vec3d aboveAbove = blockSelectionABove;
						aboveAbove.x += 0.5;
						aboveAbove.y += 1.5;
						aboveAbove.z += 0.5;
					}
				}

			}
		}

		//! Raycast after everything or the selectionbox will be outdated by 1 frame.
		//? Keep this last.
		Player.raycast();

		BeginDrawing();

		ClearBackground(Color(120, 166, 255, 255));
		// ClearBackground(Color(0, 1, 25, 255));

		CameraHandler.begin();
		{
			if (drawWorld) {
				Map.draw();
			}
			// Player.draw();

			// debugDraw();

			if (playerBlockSelection.y != -1) {
				DrawCubeWires(vec3dAdd(Vec3d(playerBlockSelection.x, playerBlockSelection.y, playerBlockSelection
						.z), Vec3d(0.5, 0.5, 0.5)).toRaylib(), 1.0001, 1.0001, 1.0001, Colors.BLACK);
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

		ubyte lightLevel = 0;
		Vec3i blockSelection = Player.getBlockSelectionAbove();
		if (blockSelection.y != -1) {
			const(const BlockData*) thisBlock = Map.getBlockPointerAtWorldPosition(
				blockSelection.x, blockSelection.y, blockSelection.z);
			if (thisBlock) {
				lightLevel = thisBlock.naturalLightBank;
			}

			DrawText(toStringz("Light:" ~ to!string(lightLevel)), 10, 160, 30, Colors.BLACK);
			DrawText(toStringz("Light:" ~ to!string(lightLevel)), 11, 161, 30, Colors.BLUE);

		}

		Crosshair.draw();

		EndDrawing();
	}

}
