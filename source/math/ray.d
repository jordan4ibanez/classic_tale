module math.ray;

import math.aabb;
import math.vec3d;
import math.vec3i;
import std.datetime.stopwatch;
import std.math;
import std.stdio;

void ray(Vec3d startingPoint, Vec3d endingPoint) {

    // https://www.geeksforgeeks.org/bresenhams-algorithm-for-3-d-line-drawing/
    // http://www.cse.yorku.ca/~amana/research/grid.pdf
    // https://en.wikipedia.org/wiki/Bresenham's_line_algorithm
    // https://stackoverflow.com/a/28786538
    // https://deepnight.net/tutorial/bresenham-magic-raycasting-line-of-sight-pathfinding/

    auto sw = StopWatch(AutoStart.yes);

    Vec3i start = Vec3i(
        cast(int) floor(startingPoint.x),
        cast(int) floor(startingPoint.y),
        cast(int) floor(startingPoint.z)
    );

    Vec3i end = Vec3i(
        cast(int) floor(endingPoint.x),
        cast(int) floor(endingPoint.y),
        cast(int) floor(endingPoint.z)
    );

    void drawIt(Vec3i input) {
        // writeln(input);

        import raylib;

        Vec3d pos = Vec3d(
            input.x, input.y, input.z
        );

        DrawCube(vec3dAdd(pos, Vec3d(0.5, 0.5, 0.5)).toRaylib(), 1, 1, 1, Colors.BLUE);

        DrawCubeWires(vec3dAdd(pos, Vec3d(0.5, 0.5, 0.5)).toRaylib(), 1, 1, 1, Colors
                .BLACK);
    }

    drawIt(start);
    drawIt(end);

    writeln("took: ", cast(double) sw.peek().total!"usecs");
}

// https://github.com/JOML-CI/joml-primitives/blob/main/src/org/joml/primitives/Intersectionf.java#L2732 MIT
bool testRayAab(const ref Vec3d origin, const ref Vec3d dir, const ref AABB aabb) {

    float invDirX = 1.0 / dir.x, invDirY = 1.0 / dir.y, invDirZ = 1.0 / dir.z;
    float tNear, tFar, tymin, tymax, tzmin, tzmax;
    if (invDirX >= 0.0) {
        tNear = (aabb.min.x - origin.x) * invDirX;
        tFar = (aabb.max.x - origin.x) * invDirX;
    } else {
        tNear = (aabb.max.x - origin.x) * invDirX;
        tFar = (aabb.min.x - origin.x) * invDirX;
    }
    if (invDirY >= 0.0) {
        tymin = (aabb.min.y - origin.y) * invDirY;
        tymax = (aabb.max.y - origin.y) * invDirY;
    } else {
        tymin = (aabb.max.y - origin.y) * invDirY;
        tymax = (aabb.min.y - origin.y) * invDirY;
    }
    if (tNear > tymax || tymin > tFar)
        return false;
    if (invDirZ >= 0.0) {
        tzmin = (aabb.min.z - origin.z) * invDirZ;
        tzmax = (aabb.max.z - origin.z) * invDirZ;
    } else {
        tzmin = (aabb.max.z - origin.z) * invDirZ;
        tzmax = (aabb.min.z - origin.z) * invDirZ;
    }
    if (tNear > tzmax || tzmin > tFar)
        return false;
    tNear = tymin > tNear || isNaN(tNear) ? tymin : tNear;
    tFar = tymax < tFar || isNaN(tFar) ? tymax : tFar;
    tNear = tzmin > tNear ? tzmin : tNear;
    tFar = tzmax < tFar ? tzmax : tFar;
    return tNear < tFar && tFar >= 0.0;
}
