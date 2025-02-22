module math.vec3i;

import std.math;

struct Vec3i {
    int x = 0;
    int y = 0;
    int z = 0;
}

// Add two vectors
Vec3i vec3iAdd(Vec3i v1, Vec3i v2) {
    return Vec3i(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
}

// Calculate distance between two vectors
double vec3iDistance(Vec3i v1, Vec3i v2) {
    double result = 0.0;

    double dx = v2.x - v1.x;
    double dy = v2.y - v1.y;
    double dz = v2.z - v1.z;
    result = sqrt(dx * dx + dy * dy + dz * dz);

    return result;
}
