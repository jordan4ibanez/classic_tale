module math.aabb;

import math.vec2d;
import math.vec3d;

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
