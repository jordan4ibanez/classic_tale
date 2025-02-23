module math.ray;

// import hashset;
import math.aabb;
import math.vec3d;
import math.vec3i;
import raylib;
import std.algorithm;
import std.datetime.stopwatch;
import std.math;
import std.range;
import std.stdio;

// private static HashSet!Vec3i old;
// private static HashSet!Vec3i wideBandPoints;
private static bool[Vec3i] wideBandPoints;
Vec3i* keySet;

void ray(const Vec3d startingPoint, const Vec3d endingPoint) {

    //? This might be one of the strangest and overcomplicated collision voxel raycasting algorithms ever created.

    // https://www.geeksforgeeks.org/bresenhams-algorithm-for-3-d-line-drawing/
    // http://www.cse.yorku.ca/~amana/research/grid.pdf
    // https://en.wikipedia.org/wiki/Bresenham's_line_algorithm
    // https://stackoverflow.com/a/28786538
    // https://deepnight.net/tutorial/bresenham-magic-raycasting-line-of-sight-pathfinding/
    // https://gdbooks.gitbooks.io/3dcollisions/content/Chapter3/raycast_aabb.html

    double startX = startingPoint.x;
    double startY = startingPoint.y;
    double startZ = startingPoint.z;

    double endX = endingPoint.x;
    double endY = endingPoint.y;
    double endZ = endingPoint.z;

    // Bump it out of strange floating point issues.
    if (startX % 1.0 == 0) {
        // writeln("bump 1");
        startX += 0.00001;
    }
    if (startY % 1.0 == 0) {
        // writeln("bump 2");
        startY += 0.00001;
    }
    if (startZ % 1.0 == 0) {
        // writeln("bump 3");
        startZ += 0.00001;
    }

    if (endX % 1.0 == 0) {
        // writeln("bump 4");
        endX += 0.00001;
    }
    if (endY % 1.0 == 0) {
        // writeln("bump 5");
        endY += 0.00001;
    }
    if (endZ % 1.0 == 0) {
        // writeln("bump 6");
        endZ += 0.00001;
    }

    //? Ultra wideband.
    wideBandPoints.clear();

    double distanceCalcX = endX - startX;
    double distanceCalcY = endY - startY;
    double distanceCalcZ = endZ - startZ;

    const double distance = sqrt(
        distanceCalcX * distanceCalcX + distanceCalcY * distanceCalcY + distanceCalcZ * distanceCalcZ);

    double directionX = endX - startX;
    double directionY = endY - startY;
    double directionZ = endZ - startZ;

    double __dirLength = sqrt(
        directionX * directionX + directionY * directionY + directionZ * directionZ);

    if (__dirLength != 0.0) {
        const double iLength = 1.0 / __dirLength;
        directionX *= iLength;
        directionY *= iLength;
        directionZ *= iLength;
    }

    double thisDistance = 0.01;
    double pointDistance;

    int thisPositionX;
    int thisPositionY;
    int thisPositionZ;

    double floatingPositionX;
    double floatingPositionY;
    double floatingPositionZ;

    int thisLocalX;
    int thisLocalY;
    int thisLocalZ;

    double pointDistX;
    double pointDistY;
    double pointDistZ;

    double localDistX;
    double localDistY;
    double localDistZ;

    static const Vec3i[26] dirs = [
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

    Vec3i cache;

    auto sw = StopWatch(AutoStart.yes);

    while (thisDistance < (distance + 0.01)) {

        floatingPositionX = (directionX * thisDistance) + startX;
        floatingPositionY = (directionY * thisDistance) + startY;
        floatingPositionZ = (directionZ * thisDistance) + startZ;

        thisPositionX = cast(int) floor(floatingPositionX);
        thisPositionY = cast(int) floor(floatingPositionY);
        thisPositionZ = cast(int) floor(floatingPositionZ);

        pointDistX = endingPoint.x - thisPositionX;
        pointDistY = endingPoint.y - thisPositionY;
        pointDistZ = endingPoint.z - thisPositionZ;
        pointDistance = sqrt(
            pointDistX * pointDistX + pointDistY * pointDistY + pointDistZ * pointDistZ);

        for (uint i = 0; i < 26; i++) {

            thisLocalX = thisPositionX + (dirs.ptr + i).x;
            thisLocalY = thisPositionY + (dirs.ptr + i).y;
            thisLocalZ = thisPositionZ + (dirs.ptr + i).z;

            localDistX = endingPoint.x - thisPositionX;
            localDistY = endingPoint.y - thisPositionY;
            localDistZ = endingPoint.z - thisPositionZ;

            const localDistance = sqrt(
                localDistX * localDistX + localDistY * localDistY + localDistZ * localDistZ);

            if (localDistance <= pointDistance) {
                cache.x = thisLocalX;
                cache.y = thisLocalY;
                cache.z = thisLocalZ;
                wideBandPoints[cache] = false;
            }
        }

        thisDistance += 1.0;
    }

    // This seems to reduce the average time by 2-5 microseconds.
    wideBandPoints.rehash();

    foreach (const ref key; wideBandPoints.byKey()) {

        // https://gdbooks.gitbooks.io/3dcollisions/content/Chapter3/raycast_aabb.html 
        const double t1 = (key.x - startX) * (1.0 / directionX);
        const double t2 = (key.x + 1.0 - startX) * (1.0 / directionX);
        const double t3 = (key.y - startY) * (1.0 / directionY);
        const double t4 = (key.y + 1.0 - startY) * (1.0 / directionY);
        const double t5 = (key.z - startZ) * (1.0 / directionZ);
        const double t6 = (key.z + 1.0 - startZ) * (1.0 / directionZ);

        const double aMin = min(t1, t2);
        const double aMax = max(t1, t2);
        const double bMin = min(t3, t4);
        const double bMax = max(t3, t4);
        const double cMin = min(t5, t6);
        const double cMax = max(t5, t6);
        const double eMin = min(aMax, bMax);
        const double eMax = max(aMin, bMin);

        const double tmin = max(eMax, cMin);
        const double tmax = min(eMin, cMax);

        // if tmax < 0, ray (line) is intersecting AABB, but whole AABB is behind us.
        // if tmin > tmax, ray doesn't intersect AABB.
        if (tmax < 0 || tmin > tmax) {
            continue;
        }

        DrawCube(Vec3d(cast(double) key.x + 0.5, cast(double) key.y + 0.5, cast(double) key.z + 0.5)
                .toRaylib(), 1, 1, 1, Colors.ORANGE);

        DrawCubeWires(Vec3d(cast(double) key.x + 0.5, cast(double) key.y + 0.5, cast(double) key.z + 0.5)
                .toRaylib(), 1, 1, 1, Colors.BLACK);

    }

    // HashSet!Vec3d testedPoints;

    // import raylib;

    // auto boof = wideBandPoints.byKey();

    // writeln(boof);

    writeln("took: ", cast(double) sw.peek().total!"usecs", " usecs");

    DrawLine3D(startingPoint.toRaylib(), endingPoint.toRaylib(), Colors.BLUE);
}
