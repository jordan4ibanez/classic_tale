module math.ray;

import math.aabb;
import math.vec3d;
import math.vec3i;
import std.datetime.stopwatch;
import std.math;
import std.stdio;

void ray(const Vec3d startingPoint, Vec3d endingPoint) {

    // https://www.geeksforgeeks.org/bresenhams-algorithm-for-3-d-line-drawing/
    // http://www.cse.yorku.ca/~amana/research/grid.pdf
    // https://en.wikipedia.org/wiki/Bresenham's_line_algorithm
    // https://stackoverflow.com/a/28786538
    // https://deepnight.net/tutorial/bresenham-magic-raycasting-line-of-sight-pathfinding/

    Vec3d start = startingPoint;
    Vec3d end = endingPoint;

    auto sw = StopWatch(AutoStart.yes);

    start = vec3dFloor(start);
    end = vec3dFloor(end);

    Vec3d d = vec3dAbs(vec3dSubtract(start, end));

    Vec3d s;

    if (end.x > start.x) {
        s.x = 1;
    } else {
        s.x = -1;
    }

    if (end.y > start.y) {
        s.y = 1;
    } else {
        s.y = -1;
    }

    if (end.z > start.z) {
        s.z = 1;
    } else {
        s.z = -1;
    }

    void drawIt(Vec3d input) {
        // writeln(input);

        import raylib;

        DrawCube(vec3dAdd(input, Vec3d(0.5, 0.5, 0.5)).toRaylib(), 1, 1, 1, Colors.BLUE);

        DrawCubeWires(vec3dAdd(input, Vec3d(0.5, 0.5, 0.5)).toRaylib(), 1, 1, 1, Colors
                .BLACK);
    }

    Vec3d[] points;

    // Driving axis is X-axis"
    if (d.x >= d.y && d.x >= d.z) {

        double p1 = 2 * d.y - d.x;
        double p2 = 2 * d.z - d.x;

        while (start.x != end.x) {

            start.x += s.x;

            if (p1 >= 0) {
                start.y += s.y;
                p1 -= 2 * d.x;
            }
            if (p2 >= 0) {
                start.z += s.z;
                p2 -= 2 * d.x;
            }

            p1 += 2 * d.y;
            p2 += 2 * d.z;

            points ~= Vec3d(start.x, start.y, start.z);

            // drawIt(Vec3d(start.x, start.y, start.z));
        }

        // Driving axis is Y-axis"
    } else if (d.y >= d.x && d.y >= d.z) {

        double p1 = 2 * d.x - d.y;
        double p2 = 2 * d.z - d.y;

        while (start.y != end.y) {
            start.y += s.y;
            if (p1 >= 0) {
                // Think of this as rounding down.

                start.x += s.x;
                p1 -= 2 * d.y;
            }

            if (p2 >= 0) {

                start.z += s.z;
                p2 -= 2 * d.y;
            }
            p1 += 2 * d.x;
            p2 += 2 * d.z;

            points ~= Vec3d(start.x, start.y, start.z);
            // drawIt(Vec3d(start.x, start.y, start.z));

        }

        // Driving axis is Z-axis"
    } else {

        double p1 = 2 * d.y - d.z;

        double p2 = 2 * d.x - d.z;

        while (start.z != end.z) {
            start.z += s.z;

            if (p1 >= 0) {

                start.y += s.y;
                p1 -= 2 * d.z;
            }
            if (p2 >= 0) {

                start.x += s.x;
                p2 -= 2 * d.z;
            }
            p1 += 2 * d.y;
            p2 += 2 * d.x;

            points ~= Vec3d(start.x, start.y, start.z);
            // drawIt(Vec3d(start.x, start.y, start.z));
        }
    }

    writeln("took: ", cast(double) sw.peek().total!"usecs", " usecs");
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
