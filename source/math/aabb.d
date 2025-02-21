module math.aabb;

import math.vec2d;
import math.vec3d;
import std.math.traits : sgn;
import std.stdio;

//? Note: Entities position is at the bottom center of the collision box.

/*
          <------> width applied from center (half width)

          <------|-----> total width
          |------|-----|< AABB Max
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

struct AABB {
    Vec3d min;
    Vec3d max;

    /// Block constructor.
    this(const ref Vec3d min, const ref Vec3d max) {
        this.min = min;
        this.max = max;
    }

    /// Entity constructor.
    this(const ref Vec3d position, const ref Vec2d size) {
        this.min.x = position.x - size.x / 2;
        this.min.y = position.y;
        this.min.z = position.z - size.x / 2;

        this.max.x = position.x + size.x / 2;
        this.max.y = position.y + size.y;
        this.max.z = position.z + size.x / 2;
    }
}

pragma(inline)
bool aabbCollision(AABB a, AABB b) {
    // Inverted exclusion detection because I'm weird.
    if (a.max.x < b.min.x || a.min.x > b.max.x) {
        return false;
    }
    if (a.max.y < b.min.y || a.min.y > b.max.y) {
        return false;
    }
    if (a.max.z < b.min.z || a.min.z > b.max.z) {
        return false;
    }
    return true;
}

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
    Vec3d blockMin, Vec3d blockMax, CollisionAxis axis) {

    // TODO: Use AABB to construct a box every iteration.
    // TODO: This should probably just be part of the AABB module?

    CollisionResult result;

    immutable dir = (axis == CollisionAxis.X) ? cast(int) sgn(entityVelocity.x) : cast(
        int) sgn(entityVelocity.z);

    // Entity position is on the bottom center of the collisionbox.
    immutable double entityHalfWidth = entitySize.x * 0.5;

    result.newPosition = (axis == CollisionAxis.X) ? entityPosition.x : entityPosition.z;

    // This thing isn't moving.
    if (dir == 0) {
        return result;
    }

    immutable AABB entityAABB = AABB(entityPosition, entitySize);
    immutable AABB blockAABB = AABB(blockMin, blockMax);

    if (aabbCollision(entityAABB, blockAABB)) {

        result.collides = true;

        // This doesn't kick out in a specific direction on dir 0 because the Y axis check will kick them up as a safety.

        if (axis == CollisionAxis.X) {
            if (dir > 0) {
                // Kick left.
                result.newPosition = blockAABB.min.x - entityHalfWidth - magicAdjustment;
            } else if (dir < 0) {
                // Kick right.
                result.newPosition = blockAABB.max.x + entityHalfWidth + magicAdjustment;
            }
        } else {
            //? Remember: -Z is forwards.
            if (dir > 0) {
                // Kick forward.
                result.newPosition = blockAABB.min.z - entityHalfWidth - magicAdjustment;
            } else if (dir < 0) {
                // Kick backward.
                result.newPosition = blockAABB.max.z + entityHalfWidth + magicAdjustment;
            }
        }
    }

    return result;

}

CollisionResult collideYToBlock(Vec3d entityPosition, Vec3d entitySize, Vec3d entityVelocity,
    Vec3d blockPosition, Vec3d blockSize) {

    CollisionResult result;
    // result.newPosition = entityPosition.y;

    // int dir = cast(int) sgn(entityVelocity.y);

    // // This thing isn't moving.
    // if (dir == 0) {
    //     return result;
    // }

    // // Entity position is on the bottom center of the collisionbox.
    // immutable double entityHalfWidth = entitySize.x * 0.5;
    // immutable Rect entityRectangle = Rect(entityPosition.x - entityHalfWidth, entityPosition.y,
    //     entitySize.x, entitySize.y);

    // immutable Rect blockRectangle = Rect(blockPosition.x, blockPosition.y, blockSize.x, blockSize.y);

    // if (checkCollisionRecs(entityRectangle, blockRectangle)) {

    //     result.collides = true;
    //     if (dir <= 0) {
    //         // Kick up. This is the safety default.
    //         result.newPosition = blockPosition.y + blockSize.y + magicAdjustment;
    //         result.hitGround = true;
    //     } else {
    //         // Kick down.
    //         result.newPosition = blockPosition.y - entitySize.y - magicAdjustment;
    //     }
    // }

    return result;
}
