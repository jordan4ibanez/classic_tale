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

    //? This might be one of the strangest and overcomplicated collision voxel 
    //? raycasting algorithms ever created.
    //? It has been completely unrolled into pure math and minimal function calls for performance.
    //? It is a 3 phase algorithm and it is very simple but the unrolling of
    //? all the function calls makes it look extremely complex.
    //? The following links are the general "big picture" I read through to understand
    //? how the implementation would need to be designed.

    // https://www.geeksforgeeks.org/bresenhams-algorithm-for-3-d-line-drawing/
    // http://www.cse.yorku.ca/~amana/research/grid.pdf
    // https://en.wikipedia.org/wiki/Bresenham's_line_algorithm
    // https://stackoverflow.com/a/28786538
    // https://deepnight.net/tutorial/bresenham-magic-raycasting-line-of-sight-pathfinding/
    // https://gdbooks.gitbooks.io/3dcollisions/content/Chapter3/raycast_aabb.html
    // https://www.cs.princeton.edu/courses/archive/fall00/cs426/lectures/raycast/sld017.htm
    // https://stackoverflow.com/questions/26920705/ray-plane-intersection

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
    //~ Note: When the mantissa exceeds this magic number on the X or Z
    //~ like when you start trying to do a FarLands exploration
    //~ this will begin to fall apart and it will default back into it's
    //~ original location as it cannot be pushed by this value.
    //todo: look into a way to mantissa bump on any precision level.
    if (startX % 1.0 == 0) {
        startX += 0.00001;
    }
    if (startY % 1.0 == 0) {
        startY += 0.00001;
    }
    if (startZ % 1.0 == 0) {
        startZ += 0.00001;
    }

    if (endX % 1.0 == 0) {
        endX += 0.00001;
    }
    if (endY % 1.0 == 0) {
        endY += 0.00001;
    }
    if (endZ % 1.0 == 0) {
        endZ += 0.00001;
    }

    //? Ultra wideband.
    //? Literally just fire the ray into the air block by block in
    //? the direction it's pointing and collect all block points in
    //? a 3x3 area. It will move into the wideband during this.
    //? You can think of this kind of like an octree, but for logic.

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

    static const Vec3i[27] dirs = [
        // Self first.
        Vec3i(0, 0, 0),
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

        pointDistX = endX - thisPositionX;
        pointDistY = endY - thisPositionY;
        pointDistZ = endZ - thisPositionZ;

        pointDistance = sqrt(
            pointDistX * pointDistX + pointDistY * pointDistY + pointDistZ * pointDistZ);

        for (uint i = 0; i < 27; i++) {

            thisLocalX = thisPositionX + (dirs.ptr + i).x;
            thisLocalY = thisPositionY + (dirs.ptr + i).y;
            thisLocalZ = thisPositionZ + (dirs.ptr + i).z;

            localDistX = endX - thisPositionX;
            localDistY = endY - thisPositionY;
            localDistZ = endZ - thisPositionZ;

            const localDistance = sqrt(
                localDistX * localDistX + localDistY * localDistY + localDistZ * localDistZ);

            if (localDistance <= pointDistance) {
                cache.x = thisLocalX;
                cache.y = thisLocalY;
                cache.z = thisLocalZ;

                if (cache in wideBandPoints) {
                    continue;
                }

                //? Wideband check.
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

                import game.map;

                Vec3d inSpace = Vec3d(thisLocalX, thisLocalY, thisLocalZ);

                if (Map.getBlockAtWorldPosition(inSpace).blockID != 0) {

                    import raylib;

                    // https://stackoverflow.com/a/26930963 https://creativecommons.org/licenses/by-sa/3.0/

                    bool collisionXMin = false;
                    bool collisionXMax = false;
                    bool collisionYMin = false;
                    bool collisionYMax = false;
                    bool collisionZMin = false;
                    bool collisionZMax = false;
                    double collisionXMinDistance = float.max;
                    double collisionXMaxDistance = float.max;
                    double collisionYMinDistance = float.max;
                    double collisionYMaxDistance = float.max;
                    double collisionZMinDistance = float.max;
                    double collisionZMaxDistance = float.max;

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
                                normalX * rayOriginX + normalY * rayOriginY + normalZ * rayOriginZ)) / s;

                        Vec3d collisionPoint = Vec3d(rayOriginX + dirX * collisionDistance,
                            rayOriginY + dirY * collisionDistance, rayOriginZ + dirZ * collisionDistance);

                        if (collisionPoint.y >= yMin && collisionPoint.y <= yMax &&
                            collisionPoint.z >= zMin && collisionPoint.z <= zMax) {
                            DrawCubeWires(collisionPoint.toRaylib(), 0.05, 0.05, 0.05, Colors
                                    .RED);
                            collisionXMin = true;
                        }
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
                                normalX * rayOriginX + normalY * rayOriginY + normalZ * rayOriginZ)) / s;

                        Vec3d collisionPoint = Vec3d(rayOriginX + dirX * collisionDistance,
                            rayOriginY + dirY * collisionDistance, rayOriginZ + dirZ * collisionDistance);

                        if (collisionPoint.y >= yMin && collisionPoint.y <= yMax &&
                            collisionPoint.z >= zMin && collisionPoint.z <= zMax) {
                            DrawCubeWires(collisionPoint.toRaylib(), 0.05, 0.05, 0.05, Colors
                                    .RED);
                            collisionXMax = true;
                        }
                    }

                    //? Y min.
                    {
                        const double normalX = 0.0;
                        const double normalY = -1.0;
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
                                normalX * rayOriginX + normalY * rayOriginY + normalZ * rayOriginZ)) / s;

                        Vec3d collisionPoint = Vec3d(rayOriginX + dirX * collisionDistance,
                            rayOriginY + dirY * collisionDistance, rayOriginZ + dirZ * collisionDistance);

                        if (collisionPoint.x >= xMin && collisionPoint.x <= xMax &&
                            collisionPoint.z >= zMin && collisionPoint.z <= zMax) {
                            DrawCubeWires(collisionPoint.toRaylib(), 0.05, 0.05, 0.05, Colors
                                    .GREEN);
                            collisionYMin = true;
                        }
                    }

                    //? Y max.
                    {
                        const double normalX = 0.0;
                        const double normalY = 1.0;
                        const double normalZ = 0.0;
                        const double x = xMin;
                        const double y = yMax;
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
                                normalX * rayOriginX + normalY * rayOriginY + normalZ * rayOriginZ)) / s;

                        Vec3d collisionPoint = Vec3d(rayOriginX + dirX * collisionDistance,
                            rayOriginY + dirY * collisionDistance, rayOriginZ + dirZ * collisionDistance);

                        if (collisionPoint.x >= xMin && collisionPoint.x <= xMax &&
                            collisionPoint.z >= zMin && collisionPoint.z <= zMax) {
                            DrawCubeWires(collisionPoint.toRaylib(), 0.05, 0.05, 0.05, Colors
                                    .GREEN);
                            collisionYMax = true;
                        }
                    }

                    //? Z min.
                    {
                        const double normalX = 0.0;
                        const double normalY = 0.0;
                        const double normalZ = -1.0;
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
                                normalX * rayOriginX + normalY * rayOriginY + normalZ * rayOriginZ)) / s;

                        Vec3d collisionPoint = Vec3d(rayOriginX + dirX * collisionDistance,
                            rayOriginY + dirY * collisionDistance, rayOriginZ + dirZ * collisionDistance);

                        if (collisionPoint.x >= xMin && collisionPoint.x <= xMax &&
                            collisionPoint.y >= yMin && collisionPoint.y <= yMax) {
                            DrawCubeWires(collisionPoint.toRaylib(), 0.05, 0.05, 0.05, Colors
                                    .BLUE);
                            collisionZMin = true;
                        }
                    }

                    //? Z max.
                    {
                        const double normalX = 0.0;
                        const double normalY = 0.0;
                        const double normalZ = 1.0;
                        const double x = xMin;
                        const double y = yMin;
                        const double z = zMax;
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
                                normalX * rayOriginX + normalY * rayOriginY + normalZ * rayOriginZ)) / s;

                        Vec3d collisionPoint = Vec3d(rayOriginX + dirX * collisionDistance,
                            rayOriginY + dirY * collisionDistance, rayOriginZ + dirZ * collisionDistance);

                        if (collisionPoint.x >= xMin && collisionPoint.x <= xMax &&
                            collisionPoint.y >= yMin && collisionPoint.y <= yMax) {
                            DrawCubeWires(collisionPoint.toRaylib(), 0.05, 0.05, 0.05, Colors
                                    .BLUE);
                            collisionZMax = true;
                        }
                    }

                    if (collisionXMin || collisionXMax || collisionYMin || collisionYMax || collisionZMin ||
                        collisionZMax) {
                        hit = true;
                    }
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
        double aDistX = endX - a.x;
        double aDistY = endY - a.y;
        double aDistZ = endZ - a.z;

        const aDist = sqrt(
            aDistX * aDistX + aDistY * aDistY + aDistZ * aDistZ);

        double bDistX = endX - b.x;
        double bDistY = endY - b.y;
        double bDistZ = endZ - b.z;

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

    // writeln("took: ", cast(double) sw.peek().total!"usecs", " usecs");

    return RayResult(rayPoints, currentIndex);
}
