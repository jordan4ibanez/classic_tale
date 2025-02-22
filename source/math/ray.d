module math.ray;

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
