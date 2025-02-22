module math.ray;

import math.vec3d;
import std.stdio;

void ray(Vec3d start, Vec3d end) {

    // https://www.geeksforgeeks.org/bresenhams-algorithm-for-3-d-line-drawing/
    // http://www.cse.yorku.ca/~amana/research/grid.pdf
    // https://en.wikipedia.org/wiki/Bresenham's_line_algorithm
    // https://stackoverflow.com/a/28786538
    // https://deepnight.net/tutorial/bresenham-magic-raycasting-line-of-sight-pathfinding/

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

    // Driving axis is X-axis"
    if (d.x >= d.y && d.x >= d.z) {

        writeln("X");

        double p1 = 2 * d.y - d.x;
        double p2 = 2 * d.z - d.x;

        while (start.x != end.x) {

            start.x += s.x;

            if (p1 >= 0) {
                drawIt(Vec3d(start.x, start.y, start.z));
                start.y += s.y;
                p1 -= 2 * d.x;
            }
            if (p2 >= 0) {
                drawIt(Vec3d(start.x, start.y, start.z));
                start.z += s.z;
                p2 -= 2 * d.x;
            }

            p1 += 2 * d.y;
            p2 += 2 * d.z;

            drawIt(Vec3d(start.x, start.y, start.z));
        }

        // Driving axis is Y-axis"
    } else if (d.y >= d.x && d.y >= d.z) {

        writeln("Y");

        double p1 = 2 * d.x - d.y;
        double p2 = 2 * d.z - d.y;

        while (start.y != end.y) {
            start.y += s.y;
            if (p1 >= 0) {
                // Think of this as rounding down.
                drawIt(Vec3d(start.x, start.y, start.z));
                start.x += s.x;
                p1 -= 2 * d.y;
            }

            if (p2 >= 0) {
                drawIt(Vec3d(start.x, start.y, start.z));
                start.z += s.z;
                p2 -= 2 * d.y;
            }
            p1 += 2 * d.x;
            p2 += 2 * d.z;

            drawIt(Vec3d(start.x, start.y, start.z));

        }

        // Driving axis is Z-axis"
    } else {
        writeln("Z");

        double p1 = 2 * d.y - d.z;

        double p2 = 2 * d.x - d.z;

        while (start.z != end.z) {
            start.z += s.z;

            if (p1 >= 0) {
                drawIt(Vec3d(start.x, start.y, start.z));
                start.y += s.y;
                p1 -= 2 * d.z;
            }
            if (p2 >= 0) {
                drawIt(Vec3d(start.x, start.y, start.z));
                start.x += s.x;
                p2 -= 2 * d.z;
            }
            p1 += 2 * d.y;
            p2 += 2 * d.x;

            drawIt(Vec3d(start.x, start.y, start.z));
        }
    }
}
