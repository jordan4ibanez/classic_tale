module math.ray;

import hashset;
import math.aabb;
import math.vec3d;
import math.vec3i;
import raylib;
import std.datetime.stopwatch;
import std.math;
import std.stdio;

void ray(const Vec3d startingPoint, Vec3d endingPoint) {

    //? This might be one of the strangest and overcomplicated collision voxel raycasting algorithms ever created.

    // https://www.geeksforgeeks.org/bresenhams-algorithm-for-3-d-line-drawing/
    // http://www.cse.yorku.ca/~amana/research/grid.pdf
    // https://en.wikipedia.org/wiki/Bresenham's_line_algorithm
    // https://stackoverflow.com/a/28786538
    // https://deepnight.net/tutorial/bresenham-magic-raycasting-line-of-sight-pathfinding/
    // https://gdbooks.gitbooks.io/3dcollisions/content/Chapter3/raycast_aabb.html

    Vec3d start = startingPoint;
    Vec3d end = endingPoint;

    // Bump it out of strange floating point issues.
    if (start.x % 1.0 == 0) {
        // writeln("bump 1");
        start.x += 0.00001;
    }
    if (start.y % 1.0 == 0) {
        // writeln("bump 2");
        start.y += 0.00001;
    }
    if (start.z % 1.0 == 0) {
        // writeln("bump 3");
        start.z += 0.00001;
    }

    if (end.x % 1.0 == 0) {
        // writeln("bump 4");
        end.x += 0.00001;
    }
    if (end.y % 1.0 == 0) {
        // writeln("bump 5");
        end.y += 0.00001;
    }
    if (end.z % 1.0 == 0) {
        // writeln("bump 6");
        end.z += 0.00001;
    }

    double distance = vec3dDistance(start, end);

    auto sw = StopWatch(AutoStart.yes);

    start = vec3dFloor(start);
    end = vec3dFloor(end);

    immutable Vec3d direction = vec3dNormalize(vec3dSubtract(end, start));

    static immutable Vec3i[7] dirs = [

        // Include self.
        Vec3i(0, 0, 0),

        Vec3i(-1, 0, 0),
        Vec3i(1, 0, 0),

        Vec3i(0, -1, 0),
        Vec3i(0, 1, 0),

        Vec3i(0, 0, -1),
        Vec3i(0, 0, 1),
    ];

    HashSet!Vec3i points;

    double thisDistance = 0.01;

    while (thisDistance < distance) {

        Vec3d floatingPosition = vec3dAdd(vec3dMultiply(direction, Vec3d(thisDistance, thisDistance, thisDistance)),
            start);

        Vec3i thisPosition = Vec3i(
            cast(int) floor(floatingPosition.x),
            cast(int) floor(floatingPosition.y),
            cast(int) floor(floatingPosition.z)
        );

        double pointDistance = vec3dDistance(Vec3d(thisPosition.x, thisPosition.y, thisPosition.z), endingPoint);

        foreach (Vec3i key; dirs) {
            Vec3i thisLocal = vec3iAdd(thisPosition, key);

            double localDistance = vec3dDistance(Vec3d(thisLocal.x, thisLocal.y, thisLocal.z), endingPoint);
            if (localDistance > pointDistance) {
                continue;
            }

            points.insert(thisLocal);
        }

        thisDistance += 1.0;
    }

    foreach (Vec3i key; points) {

        AABB thisBox = AABB(
            key.x, key.y, key.z,
            key.x + 1.0, key.y + 1.0, key.z + 1.0
        );

        if (raycastBool(start, direction, thisBox)) {

            // DrawCube(Vec3d(cast(float) key.x + 0.5, cast(float) key.y + 0.5, cast(float) key.z + 0.5)
            //         .toRaylib(), 1, 1, 1, Colors.ORANGE);

            DrawCubeWires(Vec3d(cast(float) key.x + 0.5, cast(float) key.y + 0.5, cast(float) key.z + 0.5)
                    .toRaylib(), 1, 1, 1, Colors.BLACK);
        }

    }

    //? Ultra wideband.

    HashSet!Vec3d testedPoints;

    import raylib;

    DrawLine3D(start.toRaylib(), end.toRaylib(), Colors.BLUE);

    writeln("took: ", cast(double) sw.peek().total!"usecs", " usecs");
}

import std.algorithm;

// https://gdbooks.gitbooks.io/3dcollisions/content/Chapter3/raycast_aabb.html 
bool raycastBool(Vec3d origin, const ref Vec3d dir, const ref AABB aabb) {
    immutable float t1 = (aabb.min.x - origin.x) / dir.x;
    immutable float t2 = (aabb.max.x - origin.x) / dir.x;
    immutable float t3 = (aabb.min.y - origin.y) / dir.y;
    immutable float t4 = (aabb.max.y - origin.y) / dir.y;
    immutable float t5 = (aabb.min.z - origin.z) / dir.z;
    immutable float t6 = (aabb.max.z - origin.z) / dir.z;

    immutable float tmin = max(max(min(t1, t2), min(t3, t4)), min(t5, t6));
    immutable float tmax = min(min(max(t1, t2), max(t3, t4)), max(t5, t6));

    // if tmax < 0, ray (line) is intersecting AABB, but whole AABB is behing us
    if (tmax < 0) {
        return false;
    }
    // if tmin > tmax, ray doesn't intersect AABB
    if (tmin > tmax) {
        return false;
    }

    return true;
}
