module math.ray;

import hashset;
import math.aabb;
import math.vec3d;
import math.vec3i;
import raylib;
import std.algorithm;
import std.datetime.stopwatch;
import std.math;
import std.stdio;

private static HashSet!Vec3i old;

private static HashSet!Vec3i wideBandPoints;

void ray(const Vec3d startingPoint, const Vec3d endingPoint) {

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

    //? Ultra wideband.

    wideBandPoints.clear();

    double distance = vec3dDistance(start, end);

    auto sw = StopWatch(AutoStart.yes);

    immutable Vec3d direction = vec3dNormalize(vec3dSubtract(end, start));

    double thisDistance = 0.01;

    Vec3i thisPosition;
    Vec3d floatingPosition;
    Vec3i thisLocal;
    double pointDistX;
    double pointDistY;
    double pointDistZ;
    double pointDistance;
    double localDistX;
    double localDistY;
    double localDistZ;
    double localDistance;

    static immutable Vec3i[26] dirs = [
        Vec3i(-1, -1, -1),
        Vec3i(-1, -1, 0),
        Vec3i(-1, -1, 1),
        Vec3i(-1, 0, -1),
        Vec3i(-1, 0, 0),
        Vec3i(-1, 0, 1),
        Vec3i(-1, 1, -1),
        Vec3i(-1, 1, 0),
        Vec3i(-1, 1, 1),
        Vec3i(0, -1, -1),
        Vec3i(0, -1, 0),
        Vec3i(0, -1, 1),
        Vec3i(0, 0, -1),
        Vec3i(0, 0, 1),
        Vec3i(0, 1, -1),
        Vec3i(0, 1, 0),
        Vec3i(0, 1, 1),
        Vec3i(1, -1, -1),
        Vec3i(1, -1, 0),
        Vec3i(1, -1, 1),
        Vec3i(1, 0, -1),
        Vec3i(1, 0, 0),
        Vec3i(1, 0, 1),
        Vec3i(1, 1, -1),
        Vec3i(1, 1, 0),
        Vec3i(1, 1, 1),
    ];

    while (thisDistance < (distance + 0.01)) {

        floatingPosition.x = (direction.x * thisDistance) + start.x;
        floatingPosition.y = (direction.y * thisDistance) + start.y;
        floatingPosition.z = (direction.z * thisDistance) + start.z;

        thisPosition.x = cast(int) floor(floatingPosition.x);
        thisPosition.y = cast(int) floor(floatingPosition.y);
        thisPosition.z = cast(int) floor(floatingPosition.z);

        pointDistX = endingPoint.x - thisPosition.x;
        pointDistY = endingPoint.y - thisPosition.y;
        pointDistZ = endingPoint.z - thisPosition.z;
        pointDistance = sqrt(
            pointDistX * pointDistX + pointDistY * pointDistY + pointDistZ * pointDistZ);

        foreach (const ref dir; dirs) {

            thisLocal.x = thisPosition.x + dir.x;
            thisLocal.y = thisPosition.y + dir.y;
            thisLocal.z = thisPosition.z + dir.z;

            localDistX = endingPoint.x - thisPosition.x;
            localDistY = endingPoint.y - thisPosition.y;
            localDistZ = endingPoint.z - thisPosition.z;
            localDistance = sqrt(
                localDistX * localDistX + localDistY * localDistY + localDistZ * localDistZ);

            if (localDistance < pointDistance) {
                wideBandPoints.insert(thisLocal);
            }
        }

        thisDistance += 1.0;
    }

    AABB thisBox = AABB();
    foreach (const key; wideBandPoints) {

        thisBox.min.x = key.x;
        thisBox.min.y = key.y;
        thisBox.min.z = key.z;

        thisBox.max.x = key.x + 1.0;
        thisBox.max.y = key.y + 1.0;
        thisBox.max.z = key.z + 1.0;

        // key.x, key.y, key.z,
        // key.x + 1.0, key.y + 1.0, key.z + 1.0
        // );

        if (raycastBool(start, direction, thisBox)) {

            // DrawCube(Vec3d(cast(double) key.x + 0.5, cast(double) key.y + 0.5, cast(double) key.z + 0.5)
            //         .toRaylib(), 1, 1, 1, Colors.ORANGE);

            // DrawCubeWires(Vec3d(cast(double) key.x + 0.5, cast(double) key.y + 0.5, cast(double) key.z + 0.5)
            //         .toRaylib(), 1, 1, 1, Colors.BLACK);
        }

    }

    // HashSet!Vec3d testedPoints;

    // import raylib;

    // DrawLine3D(startingPoint.toRaylib(), endingPoint.toRaylib(), Colors.BLUE);

    writeln("took: ", cast(double) sw.peek().total!"usecs", " usecs");
}

// https://gdbooks.gitbooks.io/3dcollisions/content/Chapter3/raycast_aabb.html 
bool raycastBool(const ref Vec3d origin, const ref Vec3d dir, const ref AABB aabb) {
    immutable double t1 = (aabb.min.x - origin.x) / dir.x;
    immutable double t2 = (aabb.max.x - origin.x) / dir.x;
    immutable double t3 = (aabb.min.y - origin.y) / dir.y;
    immutable double t4 = (aabb.max.y - origin.y) / dir.y;
    immutable double t5 = (aabb.min.z - origin.z) / dir.z;
    immutable double t6 = (aabb.max.z - origin.z) / dir.z;

    immutable double tmin = max(max(min(t1, t2), min(t3, t4)), min(t5, t6));
    immutable double tmax = min(min(max(t1, t2), max(t3, t4)), max(t5, t6));

    // if tmax < 0, ray (line) is intersecting AABB, but whole AABB is behind us
    if (tmax < 0) {
        return false;
    }
    // if tmin > tmax, ray doesn't intersect AABB
    if (tmin > tmax) {
        return false;
    }

    return true;
}
