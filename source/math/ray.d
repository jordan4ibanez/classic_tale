module math.ray;

import core.memory;
import math.aabb;
import math.vec3d;
import math.vec3i;
import std.algorithm;
import std.algorithm.sorting;
import std.math;
import std.range;
import std.stdio;

// import raylib;
import std.datetime.stopwatch;

// private static HashSet!Vec3i old;
// private static HashSet!Vec3i wideBandPoints;
private static bool[Vec3i] wideBandPoints;
private static Vec3i* rayPoints;

struct RayResult {
    const(const Vec3i*) pointsArray;
    const ulong arrayLength;
}

RayResult rayCast(const Vec3d startingPoint, const Vec3d endingPoint) {

    //? This might be one of the strangest and overcomplicated collision voxel raycasting algorithms ever created.

    // https://www.geeksforgeeks.org/bresenhams-algorithm-for-3-d-line-drawing/
    // http://www.cse.yorku.ca/~amana/research/grid.pdf
    // https://en.wikipedia.org/wiki/Bresenham's_line_algorithm
    // https://stackoverflow.com/a/28786538
    // https://deepnight.net/tutorial/bresenham-magic-raycasting-line-of-sight-pathfinding/
    // https://gdbooks.gitbooks.io/3dcollisions/content/Chapter3/raycast_aabb.html

    if (rayPoints is null) {
        // ~6KB data roughly.
        rayPoints = cast(Vec3i*) GC.malloc(Vec3i.sizeof * 512);
    }

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

    // Why are you trying to cast this far?! 
    assert(distance < 256);

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

    const double divisorDirectionX = 1.0 / directionX;
    const double divisorDirectionY = 1.0 / directionY;
    const double divisorDirectionZ = 1.0 / directionZ;

    ulong currentIndex = 0;

    bool hit = false;

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

                if (cache in wideBandPoints) {
                    continue;
                }

                //? Broadphase check.
                // Cyrus-Beck clipping
                // https://gdbooks.gitbooks.io/3dcollisions/content/Chapter3/raycast_aabb.html 

                double sizeX = 1.0;
                double sizeY = 1.0;
                double sizeZ = 1.0;

                const double xMin = thisLocalX;
                const double xMax = thisLocalX + sizeX;
                const double yMin = thisLocalY;
                const double yMax = thisLocalY + sizeY;
                const double zMin = thisLocalZ;
                const double zMax = thisLocalZ + sizeZ;

                const double xMinLocal = (thisLocalX - startX) * divisorDirectionX;
                const double xMaxLocal = (thisLocalX + sizeX - startX) * divisorDirectionX;
                const double yMinLocal = (thisLocalY - startY) * divisorDirectionY;
                const double yMaxLocal = (thisLocalY + sizeY - startY) * divisorDirectionY;
                const double zMinLocal = (thisLocalZ - startZ) * divisorDirectionZ;
                const double zMaxLocal = (thisLocalZ + sizeZ - startZ) * divisorDirectionZ;

                const double aMin = fmin(xMinLocal, xMaxLocal);
                const double aMax = fmax(xMinLocal, xMaxLocal);
                const double bMin = fmin(yMinLocal, yMaxLocal);
                const double bMax = fmax(yMinLocal, yMaxLocal);
                const double cMin = fmin(zMinLocal, zMaxLocal);
                const double cMax = fmax(zMinLocal, zMaxLocal);
                const double eMin = fmin(aMax, bMax);
                const double eMax = fmax(aMin, bMin);

                const double tmin = fmax(eMax, cMin);
                const double tmax = fmin(eMin, cMax);

                // if tmax < 0, ray (line) is intersecting AABB, but whole AABB is behind us.
                // if tmin > tmax, ray doesn't intersect AABB.
                if (tmax < 0 || tmin > tmax) {
                    continue;
                }

                double result = (tmin < tmax) ? tmax : tmin;

                import game.map;

                Vec3d inSpace = Vec3d(thisLocalX, thisLocalY, thisLocalZ);

                if (!hit && Map.getBlockAtWorldPosition(inSpace).blockID != 0) {

                    import raylib;

                    // https://stackoverflow.com/a/26930963 https://creativecommons.org/licenses/by-sa/3.0/

                    //? X min.
                    {
                        const double normalX = -1.0;
                        const double normalY = 0.0;
                        const double normalZ = 0.0;
                        const double x = xMin;
                        const double y = yMin;
                        const double z = zMin;
                        const double distanceNormal = normalX * x + normalY * y + normalZ * z;
                        const double dirX = directionX;
                        const double dirY = directionY;
                        const double dirZ = directionZ;
                        const double s = normalX * dirX + normalY * dirY + normalZ * dirZ;
                        const double rayOriginX = startX;
                        const double rayOriginY = startY;
                        const double rayOriginZ = startZ;

                        // todo: use all the collision distances and check which one is the lowest then save that collision point.
                        const double collisionDistance = (distanceNormal - (
                                normalX * rayOriginX + normalY * rayOriginY + normalZ * rayOriginZ)) * (
                            1.0 / s);

                        Vec3d collisionPoint = Vec3d(rayOriginX + dirX * collisionDistance,
                            rayOriginY + dirY * collisionDistance, rayOriginZ + dirZ * collisionDistance);

                        DrawCubeWires(collisionPoint.toRaylib(), 0.05, 0.05, 0.05, Colors
                                .RED);
                    }

                    //? X max.
                    {
                        const double normalX = 1.0;
                        const double normalY = 0.0;
                        const double normalZ = 0.0;
                        const double x = xMax;
                        const double y = yMin;
                        const double z = zMin;
                        const double distanceNormal = normalX * x + normalY * y + normalZ * z;
                        const double dirX = directionX;
                        const double dirY = directionY;
                        const double dirZ = directionZ;
                        const double s = normalX * dirX + normalY * dirY + normalZ * dirZ;
                        const double rayOriginX = startX;
                        const double rayOriginY = startY;
                        const double rayOriginZ = startZ;

                        const double collisionDistance = (distanceNormal - (
                                normalX * rayOriginX + normalY * rayOriginY + normalZ * rayOriginZ)) * (
                            1.0 / s);

                        Vec3d collisionPoint = Vec3d(rayOriginX + dirX * collisionDistance,
                            rayOriginY + dirY * collisionDistance, rayOriginZ + dirZ * collisionDistance);

                        DrawCubeWires(collisionPoint.toRaylib(), 0.05, 0.05, 0.05, Colors
                                .RED);
                    }

                    hit = true;
                }

                wideBandPoints[cache] = false;

                (rayPoints + currentIndex).x = thisLocalX;
                (rayPoints + currentIndex).y = thisLocalY;
                (rayPoints + currentIndex).z = thisLocalZ;
                currentIndex++;

            }
        }

        thisDistance += 1.0;
    }

    rayPoints[0 .. currentIndex].sort!((const ref Vec3i a, const ref Vec3i b) {
        double aDistX = endingPoint.x - a.x;
        double aDistY = endingPoint.y - a.y;
        double aDistZ = endingPoint.z - a.z;

        const aDist = sqrt(
            aDistX * aDistX + aDistY * aDistY + aDistZ * aDistZ);

        double bDistX = endingPoint.x - b.x;
        double bDistY = endingPoint.y - b.y;
        double bDistZ = endingPoint.z - b.z;

        const bDist = sqrt(
            bDistX * bDistX + bDistY * bDistY + bDistZ * bDistZ);

        return aDist > bDist;
    });

    // How to iterate.
    // for (ulong i = 0; i < currentIndex; i++) {

    //     thisLocalX = (rayPoints + i).x;
    //     thisLocalY = (rayPoints + i).y;
    //     thisLocalZ = (rayPoints + i).z;

    // if (i == 0) {
    //     writeln(thisLocalX, " ", thisLocalY, " ", thisLocalZ);
    // }

    // DrawCube(Vec3d(cast(double) thisLocalX + 0.5, cast(double) thisLocalY + 0.5, cast(
    //         double) thisLocalZ + 0.5).toRaylib(), 1, 1, 1, Colors.ORANGE);

    // DrawCubeWires(Vec3d(cast(double) thisLocalX + 0.5, cast(double) thisLocalY + 0.5, cast(
    //         double) thisLocalZ + 0.5).toRaylib(), 1, 1, 1, Colors.BLACK);
    // }

    // This seems to reduce the average time by 2-5 microseconds.
    wideBandPoints.rehash();

    writeln("took: ", cast(double) sw.peek().total!"usecs", " usecs");

    // DrawLine3D(startingPoint.toRaylib(), endingPoint.toRaylib(), Colors.BLUE);

    return RayResult(rayPoints, currentIndex);
}
