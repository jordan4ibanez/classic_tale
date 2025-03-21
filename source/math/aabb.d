module math.aabb;

import math.vec2d;
import math.vec3d;
import std.math.traits : sgn;
import std.stdio;

//? Note: Entities position is at the bottom center of the collision box.

/*
          <------> width applied from center (half width)(entity X width / 2.0)

          <------|-----> total width (entity X width)
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

    /// Generic constructor.
    this(double minX, double minY, double minZ, double maxX, double maxY, double maxZ) {
        this.min.x = minX;
        this.min.y = minY;
        this.min.z = minZ;

        this.max.x = maxX;
        this.max.y = maxY;
        this.max.z = maxZ;
    }

    /// Entity constructor.
    this(const Vec3d position, const Vec2d size) {
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
    // "the entity knows where it is because it knows where it isn't"
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
    Y,
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

CollisionResult collideEntityToBlock(Vec3d entityPosition, Vec2d entitySize, Vec3d entityVelocity,
    Vec3d blockMin, Vec3d blockMax, CollisionAxis axis) {

    CollisionResult result;

    immutable int dir = () {
        final switch (axis) {
        case (CollisionAxis.X):
            return cast(int) sgn(entityVelocity.x);
        case (CollisionAxis.Y):
            return cast(int) sgn(entityVelocity.y);
        case (CollisionAxis.Z):
            return cast(int) sgn(entityVelocity.z);
        }
    }();

    // Entity position is on the bottom center of the collisionbox.
    immutable double entityHalfWidth = entitySize.x * 0.5;

    result.newPosition = () {
        final switch (axis) {
        case (CollisionAxis.X):
            return entityPosition.x;
        case (CollisionAxis.Y):
            return entityPosition.y;
        case (CollisionAxis.Z):
            return entityPosition.z;
        }
    }();

    // This thing isn't moving.
    if (dir == 0) {
        return result;
    }

    immutable AABB entityAABB = AABB(entityPosition, entitySize);
    immutable AABB blockAABB = AABB(blockMin, blockMax);

    if (aabbCollision(entityAABB, blockAABB)) {

        result.collides = true;

        //? X and Z doesn't kick out in a specific direction on dir 0 because the Y axis check will kick entity up as a safety.

        final switch (axis) {
        case CollisionAxis.X:
            if (dir > 0) {
                // Kick left.
                result.newPosition = blockAABB.min.x - entityHalfWidth - magicAdjustment;
            } else if (dir < 0) {
                // Kick right.
                result.newPosition = blockAABB.max.x + entityHalfWidth + magicAdjustment;
            }
            break;
        case CollisionAxis.Y:
            if (dir <= 0) {
                // Kick up. This is the safety default.
                result.newPosition = blockAABB.max.y + magicAdjustment;
                result.hitGround = true;
            } else {
                // Kick down.
                result.newPosition = blockAABB.min.y - entitySize.y - magicAdjustment;
            }
            break;
        case CollisionAxis.Z:
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
