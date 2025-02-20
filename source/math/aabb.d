module math.aabb;

import math.vec3d;

struct AABB {
    Vec3d min;
    Vec3d max;
}

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
