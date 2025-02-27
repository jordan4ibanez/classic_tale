module game.player;

import controls.keyboard;
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

static final const class Player {
static:
private:

    //? Note: Entities position is at the bottom center of the collision box.

    /*
    |------------|
    |            |
    |            |
    |            |
    |            |
    |            |
    |            |
    |            |
    |            |
    |------X-----|
           ^
           |-------- Actual position
    */

    Vec2d size = Vec2d(0.6, 1.8);
    Vec3d position = Vec3d(0, 161, 0);
    Vec3d velocity = Vec3d(0, 0, 0);
    Vec3i blockSelection = Vec3i(0, -1, 0);
    Vec3i blockSelectionAbove = Vec3i(0, -1, 0);
    double eyeHeight = 1.625;
    int inChunk = int.max;
    bool firstGen = true;

    // Jump logic.
    bool jumpQueued = false;
    double jumpQueueTimeout = 0.0;

    double rotation = 0;
    bool moving = false;
    bool skidding = false;
    bool onGround = false;

public: //* BEGIN PUBLIC API.

    Vec2d getSize() {
        return size;
    }

    Vec3d getPosition() {
        return position;
    }

    double getWidth() {
        return size.y;
    }

    double getHalfWidth() {
        return size.x * 0.5;
    }

    double getEyeHeight() {
        return eyeHeight;
    }

    Vec3d getVelocity() {
        return velocity;
    }

    void setPosition(const ref Vec3d newPosition) {
        position = newPosition;
    }

    void setVelocity(const ref Vec3d newVelocity) {
        velocity = newVelocity;
    }

    void draw() {
        import raylib;

        Vec3d collisionBoxLocation = position;
        collisionBoxLocation.y += size.y / 2.0;

        DrawCubeWires(collisionBoxLocation.toRaylib(), size.x, size.y, size.x, Colors.BLACK);

        DrawSphere(position.toRaylib(), 0.01, Colors.RED);
    }

    void raycast() {
        import raylib;

        const Vec3d start = CameraHandler.getPosition();
        const Vec3d cameraDir = CameraHandler.getLookVector();
        const Vec3d end = vec3dAdd(vec3dMultiply(cameraDir, Vec3d(30, 30, 30)), start);

        RayResult result = rayCast(start, end);

        for (ulong i = 0; i < result.arrayLength; i++) {

            Vec3d thisPosition;

            thisPosition.x = (result.pointsArray + i).blockPosition.x;
            thisPosition.y = (result.pointsArray + i).blockPosition.y;
            thisPosition.z = (result.pointsArray + i).blockPosition.z;

            const BlockData = Map.getBlockAtWorldPosition(thisPosition);

            Vec3d thisPositionAbove;

            thisPositionAbove.x = thisPosition.x + (result.pointsArray + i).faceDirection.x;
            thisPositionAbove.y = thisPosition.y + (result.pointsArray + i).faceDirection.y;
            thisPositionAbove.z = thisPosition.z + (result.pointsArray + i).faceDirection.z;

            if (BlockData.blockID != 0) {

                blockSelection.x = cast(int) floor(thisPosition.x);
                blockSelection.y = cast(int) floor(thisPosition.y);
                blockSelection.z = cast(int) floor(thisPosition.z);

                blockSelectionAbove.x = cast(int) floor(thisPositionAbove.x);
                blockSelectionAbove.y = cast(int) floor(thisPositionAbove.y);
                blockSelectionAbove.z = cast(int) floor(thisPositionAbove.z);

                return;
            }
        }

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

    // Rect getRectangle() {
    //     Vec2d centeredPosition = centerCollisionboxBottom(position, size);
    //     return Rect(centeredPosition.x, centeredPosition.y, size.x, size.y);
    // }

    // void move() {
    //     double delta = Delta.getDelta();

    //     immutable double acceleration = 20;
    //     immutable double deceleration = 25;

    //     // writeln(velocity.x);

    //     moving = false;
    //     // Skidding is the player trying to slow down.
    //     skidding = false;

    //     //? Controls first.
    //     if (Keyboard.isDown(KeyboardKey.KEY_D)) {
    //         direction = Direction.Right;
    //         moving = true;
    //         if (sgn(velocity.x) < 0) {
    //             skidding = true;
    //             velocity.x += delta * deceleration;
    //         } else {
    //             velocity.x += delta * acceleration;
    //         }
    //     } else if (Keyboard.isDown(KeyboardKey.KEY_A)) {
    //         direction = Direction.Left;
    //         moving = true;
    //         if (sgn(velocity.x) > 0) {
    //             skidding = true;
    //             velocity.x -= delta * deceleration;
    //         } else {
    //             velocity.x -= delta * acceleration;
    //         }
    //     } else {
    //         if (abs(velocity.x) > delta * deceleration) {
    //             double valSign = sgn(velocity.x);
    //             velocity.x = (abs(velocity.x) - (delta * deceleration)) * valSign;
    //         } else {
    //             velocity.x = 0;
    //         }
    //     }

    //     // Speed limiter. 
    //     if (abs(velocity.x) > 5) {
    //         double valSign = sgn(velocity.x);
    //         velocity.x = valSign * 5;
    //     }

    //     velocity.y -= delta * Map.getGravity();

    //     if (!inJump && Keyboard.isDown(KeyboardKey.KEY_SPACE)) {
    //         jumpQueued = true;
    //     }

    //     //? Then apply Y axis.
    //     position.y += velocity.y * delta;

    //     bool hitGround = Map.collideEntityToWorld(position, size, velocity, CollisionAxis.Y);

    //     if (inJump && hitGround) {
    //         inJump = false;
    //     } else if (jumpQueued && hitGround) {
    //         velocity.y = 7;
    //         jumpQueued = false;
    //         inJump = true;
    //     }

    //     //? Finally apply X axis.
    //     position.x += velocity.x * delta;

    //     Map.collideEntityToWorld(position, size, velocity, CollisionAxis.X);

    //     if (velocity.x == 0) {
    //         moving = false;
    //     }

    //     // todo: the void.
    //     // if (position.y <= 0) {
    //     //     position.y = 0;
    //     // }

    //     int oldChunk = inChunk;
    //     int newChunk = Map.calculateChunkAtWorldPosition(position.x);

    //     if (oldChunk != newChunk) {
    //         inChunk = newChunk;
    //         Map.worldLoad(inChunk);

    //         // Move the player to the ground level.
    //         // todo: when mongoDB added, restore old position.
    //         if (firstGen) {
    //             position.y = Map.getTop(position.x);
    //             firstGen = false;

    //             Map.setBlockAtWorldPositionByName(Vec2d(position.x, position.y + 3), "dirt");
    //             Map.setBlockAtWorldPositionByName(Vec2d(position.x + 1, position.y + 3), "dirt");
    //         }
    //     }
    // }

    int inWhichChunk() {
        return inChunk;
    }

private: //* BEGIN INTERNAL API.

}
