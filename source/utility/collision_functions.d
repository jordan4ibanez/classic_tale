module utility.collision_functions;

import math.aabb;
import math.vec3d;
import std.math.traits : sgn;
import std.stdio;

//? Note: Entities position is at the bottom center of the collision box.

/*

          |------------|< AABB Max
          |            |
          |            |
          |            |
          |            |
          |            |
          |            |
          |            |
          |            |
AABB Min> |------X-----| 
                 ^
                 |-------- Actual position
*/

enum CollisionAxis {
    X,
    Z
}

struct CollisionResult {
    bool collides = false;
    double newPosition = 0;
    bool hitGround = false;
}

// This basically shoves the entity out of the block.
//? Note: This will have issues extremely far out.
private static immutable double magicAdjustment = 0.0001;

CollisionResult collideXZToBlock(Vec3d entityPosition, Vec3d entitySize, Vec3d entityVelocity,
    Vec3d blockPosition, Vec3d blockSize, CollisionAxis axis) {

    // TODO: Use AABB to construct a box every iteration.
    // TODO: This should probably just be part of the AABB module?

    CollisionResult result;

    if (axis == CollisionAxis.X) {

        result.newPosition = entityPosition.x;

        int dir = cast(int) sgn(entityVelocity.x);

        // This thing isn't moving.
        if (dir == 0) {
            return result;
        }

        // Entity position is on the bottom center of the collisionbox.
        immutable double entityHalfWidth = entitySize.x * 0.5;

        immutable AABB entityAABB = AABB(entityPosition, entitySize);

        immutable AABB blockAABB = AABB(blockPosition.x, blockPosition.y, blockSize.x, blockSize
                .y);

        if (checkCollisionRecs(entityAABB, blockRectangle)) {
            // This doesn't kick out in a specific direction on dir 0 because the Y axis check will kick them up as a safety.
            result.collides = true;
            if (dir > 0) {
                // Kick left.
                result.newPosition = blockPosition.x - entityHalfWidth - magicAdjustment;
            } else if (dir < 0) {
                // Kick right.
                result.newPosition = blockPosition.x + blockSize.x + entityHalfWidth + magicAdjustment;
            }
        }
    } else {

        // result.newPosition = entityPosition.x;

        // int dir = cast(int) sgn(entityVelocity.x);

        // // This thing isn't moving.
        // if (dir == 0) {
        //     return result;
        // }

        // // Entity position is on the bottom center of the collisionbox.
        // immutable double entityHalfWidth = entitySize.x * 0.5;
        // immutable Rect entityRectangle = Rect(entityPosition.x - entityHalfWidth, entityPosition.y,
        //     entitySize.x, entitySize.y);

        // immutable Rect blockRectangle = Rect(blockPosition.x, blockPosition.y, blockSize.x, blockSize
        //         .y);

        // if (checkCollisionRecs(entityRectangle, blockRectangle)) {
        //     // This doesn't kick out in a specific direction on dir 0 because the Y axis check will kick them up as a safety.
        //     result.collides = true;
        //     if (dir > 0) {
        //         // Kick left.
        //         result.newPosition = blockPosition.x - entityHalfWidth - magicAdjustment;
        //     } else if (dir < 0) {
        //         // Kick right.
        //         result.newPosition = blockPosition.x + blockSize.x + entityHalfWidth + magicAdjustment;
        //     }
        // }

    }

    return result;

}

CollisionResult collideYToBlock(Vec3d entityPosition, Vec3d entitySize, Vec3d entityVelocity,
    Vec3d blockPosition, Vec3d blockSize) {

    CollisionResult result;
    result.newPosition = entityPosition.y;

    int dir = cast(int) sgn(entityVelocity.y);

    // This thing isn't moving.
    if (dir == 0) {
        return result;
    }

    // Entity position is on the bottom center of the collisionbox.
    immutable double entityHalfWidth = entitySize.x * 0.5;
    immutable Rect entityRectangle = Rect(entityPosition.x - entityHalfWidth, entityPosition.y,
        entitySize.x, entitySize.y);

    immutable Rect blockRectangle = Rect(blockPosition.x, blockPosition.y, blockSize.x, blockSize.y);

    if (checkCollisionRecs(entityRectangle, blockRectangle)) {

        result.collides = true;
        if (dir <= 0) {
            // Kick up. This is the safety default.
            result.newPosition = blockPosition.y + blockSize.y + magicAdjustment;
            result.hitGround = true;
        } else {
            // Kick down.
            result.newPosition = blockPosition.y - entitySize.y - magicAdjustment;
        }
    }

    return result;
}
