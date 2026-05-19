module game.entity.local_player;

import controls.keyboard;
import game.entity.mob;
import game.map;
import graphics.camera_handler;
import graphics.colors;
import graphics.render;
import graphics.texture_handler;
import math.constants;
import math.ray;
import math.rect;
import math.vec2d;
import math.vec3d;
import math.vec3i;
import raylib : DEG2RAD, PI, RAD2DEG;
import std.concurrency;
import std.math.algebraic : abs;
import std.math.rounding;
import std.math.traits : isFinite, sgn;
import std.math.trigonometry;
import std.stdio;
import utility.delta;
import utility.drawing_functions;

final class LocalPlayer : Mob {
private:

    static LocalPlayer _instance;

    Vec3i blockSelection = Vec3i(0, -1, 0);
    Vec3i blockSelectionAbove = Vec3i(0, -1, 0);

public:

    static LocalPlayer getInstance() {
        if (_instance is null) {
            _instance = new LocalPlayer();
        }
        return _instance;
    }

    static void terminateInstance() {
        writeln("Terminating the local player.");
    }

    void draw() {
        import raylib;

        Vec3d collisionBoxLocation = position;
        collisionBoxLocation.y += size.y / 2.0;

        DrawCubeWires(collisionBoxLocation.toRaylib(), size.x, size.y, size.x, Colors.BLACK);

        DrawSphere(position.toRaylib(), 0.01, Colors.RED);
    }

    void raycast() {
        // import std.datetime.stopwatch;

        const Vec3d start = CameraHandler.getPosition();
        const Vec3d cameraDir = CameraHandler.getLookVector();
        const Vec3d end = vec3dAdd(vec3dMultiply(cameraDir, Vec3d(130, 130, 130)), start);

        const RayResult result = rayCast(start, end);

        // auto sw = StopWatch(AutoStart.yes);

        double thisPositionX;
        double thisPositionY;
        double thisPositionZ;

        double thisPositionAboveX;
        double thisPositionAboveY;
        double thisPositionAboveZ;

        for (ulong i = 0; i < result.arrayLength; i++) {

            thisPositionX = (result.pointsArray + i).blockPosition.x;
            thisPositionY = (result.pointsArray + i).blockPosition.y;
            thisPositionZ = (result.pointsArray + i).blockPosition.z;

            const(const BlockData*) blockData = Map.getBlockPointerAtWorldPosition(
                cast(int) floor(thisPositionX),
                cast(int) floor(thisPositionY),
                cast(int) floor(thisPositionZ)
            );

            if (blockData && blockData.blockID != 0) {

                thisPositionAboveX = thisPositionX + (result.pointsArray + i).faceDirection.x;
                thisPositionAboveY = thisPositionY + (result.pointsArray + i).faceDirection.y;
                thisPositionAboveZ = thisPositionZ + (result.pointsArray + i).faceDirection.z;

                blockSelection.x = cast(int) floor(thisPositionX);
                blockSelection.y = cast(int) floor(thisPositionY);
                blockSelection.z = cast(int) floor(thisPositionZ);

                blockSelectionAbove.x = cast(int) floor(thisPositionAboveX);
                blockSelectionAbove.y = cast(int) floor(thisPositionAboveY);
                blockSelectionAbove.z = cast(int) floor(thisPositionAboveZ);

                // writeln("took: ", cast(double) sw.peek().total!"hnsecs", " hnsecs");
                return;
            }
        }

        // writeln("took: ", cast(double) sw.peek().total!"usecs", " usecs");

        blockSelection.x = 0;
        blockSelection.y = -1;
        blockSelection.z = 0;

        blockSelectionAbove.x = 0;
        blockSelectionAbove.y = -1;
        blockSelectionAbove.z = 0;
    }

    Vec3i getBlockSelection() {
        return blockSelection;
    }

    Vec3i getBlockSelectionAbove() {
        return blockSelectionAbove;
    }

    void doControls() {
        immutable double delta = Delta.getDelta();
        immutable double yaw = CameraHandler.getYaw();

        // This is just to move this into a sane scale.
        static immutable double magicAdjustment = 10.0;

        //? For now, this code will assume every block has friction coefficient of 1.
        immutable double friction = 1.0;
        //? Same with maxSpeed. Maybe some blocks can get creative with this in mods.
        immutable double maxSpeed = 3.0;

        moving = false;

        if (Keyboard.isDown(KeyboardKey.KEY_W)) {
            immutable double dirX = cos(yaw);
            immutable double dirZ = sin(yaw);
            velocity.x += dirX * delta * magicAdjustment * friction;
            velocity.z += dirZ * delta * magicAdjustment * friction;
            moving = true;
        }
        if (Keyboard.isDown(KeyboardKey.KEY_S)) {
            immutable double dirX = cos(yaw + PI);
            immutable double dirZ = sin(yaw + PI);
            velocity.x += dirX * delta * magicAdjustment * friction;
            velocity.z += dirZ * delta * magicAdjustment * friction;
            moving = true;
        }
        if (Keyboard.isDown(KeyboardKey.KEY_A)) {
            immutable double dirX = cos(yaw - HALF_PI);
            immutable double dirZ = sin(yaw - HALF_PI);
            velocity.x += dirX * delta * magicAdjustment * friction;
            velocity.z += dirZ * delta * magicAdjustment * friction;
            moving = true;
        }
        if (Keyboard.isDown(KeyboardKey.KEY_D)) {
            immutable double dirX = cos(yaw + HALF_PI);
            immutable double dirZ = sin(yaw + HALF_PI);
            velocity.x += dirX * delta * magicAdjustment * friction;
            velocity.z += dirZ * delta * magicAdjustment * friction;
            moving = true;
        }

        // Friction.
        if (!moving) {
            Vec2d horizontalMovement = Vec2d(velocity.x, velocity.z);
            double horizontalSpeed = vec2dLength(horizontalMovement);
            horizontalSpeed -= friction * delta * magicAdjustment;
            if (horizontalSpeed < 0) {
                horizontalSpeed = 0;
            }
            if (!isFinite(horizontalSpeed)) {
                horizontalSpeed = 0.0;
            }
            horizontalMovement = vec2dMultiply(vec2dNormalize(horizontalMovement),
                Vec2d(horizontalSpeed, horizontalSpeed));

            if (!isFinite(horizontalMovement.x)) {
                horizontalMovement.x = 0.0;
            }
            if (!isFinite(horizontalMovement.y)) {
                horizontalMovement.y = 0.0;
            }
            velocity.x = horizontalMovement.x;
            velocity.z = horizontalMovement.y;
            // writeln("slowing down ", horizontalSpeed);
        }

        // Speed limit.
        {
            Vec2d horizontalMovement = Vec2d(velocity.x, velocity.z);
            double horizontalSpeed = vec2dLength(horizontalMovement);
            // writeln(horizontalSpeed);

            if (horizontalSpeed > maxSpeed) {
                horizontalMovement = vec2dMultiply(vec2dNormalize(horizontalMovement),
                    Vec2d(maxSpeed, maxSpeed));
                if (!isFinite(horizontalMovement.x)) {
                    horizontalMovement.x = 0.0;
                }
                if (!isFinite(horizontalMovement.y)) {
                    horizontalMovement.y = 0.0;
                }
                velocity.x = horizontalMovement.x;
                velocity.z = horizontalMovement.y;
            }
        }

        // Jumping things.

        // I don't really know if I should put gravity into the controls or move().
        // It is here for now, but if you read this and you have an opinion on it,
        // tell me in the Discord.

        velocity.y -= Map.getGravity() * delta;

        //? The following logic is ordered like this with very specific intent to maximize
        //? the fun/satisfying nature of jumping around the map. Please do not reorder this.
        //? This allows you to jump right before you hit the ground and gives a less rigid
        //? feeling to the implementation.

        // Do not want the player hitting space 3 blocks off the ground and jumping when they hit it.
        // The jump window is 1/20th of a second from hitting space.
        if (jumpQueued) {
            jumpQueueTimeout -= delta;
            if (jumpQueueTimeout <= 0) {
                jumpQueued = false;
            }
        }

        // This can go multiple frames without hitting the ground at very
        // high FPS. The jump must be queued. But it is also possible it happens immediately.
        if (Keyboard.isDown(KeyboardKey.KEY_SPACE)) {
            jumpQueued = true;
            static immutable double jumpTimeout = 1.0 / 20.0;
            jumpQueueTimeout = jumpTimeout;
        }

        if (onGround && jumpQueued) {
            velocity.y = 7;
            jumpQueued = false;
        }

        // todo: sneaking, somehow. Can probably just check if the player begins to fall through
        // todo: the current block face or something, not sure.

        // if (Keyboard.isDown(KeyboardKey.KEY_LEFT_SHIFT)) {
        //     velocity.y -= delta * magicAdjustment;
        // }
        // if (Keyboard.isDown(KeyboardKey.KEY_SPACE)) {
        //     velocity.y += delta * magicAdjustment;
        // }
    }

    void move() {
        double delta = Delta.getDelta();

        position.x += velocity.x * delta;
        Map.collideEntityToWorld(position, size, velocity, CollisionAxis.X);

        position.z += velocity.z * delta;
        Map.collideEntityToWorld(position, size, velocity, CollisionAxis.Z);

        position.y += velocity.y * delta;
        onGround = Map.collideEntityToWorld(position, size, velocity, CollisionAxis.Y);
    }

private:

}
