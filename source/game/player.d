module game.player;

import controls.keyboard;
import game.map;
import graphics.camera_handler;
import graphics.colors;
import graphics.render;
import graphics.texture_handler;
import math.constants;
import math.rect;
import math.vec2d;
import math.vec3d;
import raylib : DEG2RAD, PI, RAD2DEG;
import std.math.algebraic : abs;
import std.math.rounding;
import std.math.traits : sgn;
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
    Vec3d position = Vec3d(0, 170, 0);
    Vec3d velocity = Vec3d(0, 0, 0);

    double eyeHeight = 1.625;
    int inChunk = int.max;
    bool firstGen = true;
    bool jumpQueued = false;
    bool inJump = false;
    double rotation = 0;
    bool moving = false;
    bool skidding = false;

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

    void doControls() {
        immutable double delta = Delta.getDelta();
        immutable double yaw = CameraHandler.getYaw();

        static immutable double speed = 10.0;

        // velocity.x = 0;
        // velocity.y = 0;
        // velocity.z = 0;

        if (Keyboard.isDown(KeyboardKey.KEY_W)) {
            immutable double dirX = cos(yaw);
            immutable double dirZ = sin(yaw);
            velocity.x += dirX * delta * speed;
            velocity.z += dirZ * delta * speed;
        }
        if (Keyboard.isDown(KeyboardKey.KEY_S)) {
            immutable double dirX = cos(yaw + PI);
            immutable double dirZ = sin(yaw + PI);
            velocity.x += dirX * delta * speed;
            velocity.z += dirZ * delta * speed;
        }
        if (Keyboard.isDown(KeyboardKey.KEY_A)) {
            immutable double dirX = cos(yaw - HALF_PI);
            immutable double dirZ = sin(yaw - HALF_PI);
            velocity.x += dirX * delta * speed;
            velocity.z += dirZ * delta * speed;
        }
        if (Keyboard.isDown(KeyboardKey.KEY_D)) {
            immutable double dirX = cos(yaw + HALF_PI);
            immutable double dirZ = sin(yaw + HALF_PI);
            velocity.x += dirX * delta * speed;
            velocity.z += dirZ * delta * speed;
        }

        if (Keyboard.isDown(KeyboardKey.KEY_LEFT_SHIFT)) {
            velocity.y -= delta * speed;
        }
        if (Keyboard.isDown(KeyboardKey.KEY_SPACE)) {
            velocity.y += delta * speed;
        }
    }

    void move() {
        double delta = Delta.getDelta();

        position.y += velocity.y * delta;

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
