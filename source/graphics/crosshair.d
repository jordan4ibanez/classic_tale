module graphics.crosshair;

import core.memory;
import graphics.gui;
import graphics.render_2d;
import math.rect;
import math.vec2d;
import raylib : BeginBlendMode, BlendMode, Color, Colors, EndBlendMode;
import std.datetime.stopwatch;
import std.stdio;
import utility.window;

static final const class Crosshair {
static:
private:

    Rect* rectangles;
    Vec2d* linePoints;

public:

    void initialize() {
        rectangles = cast(Rect*) GC.malloc(Rect.sizeof * 3);
        linePoints = cast(Vec2d*) GC.malloc(Vec2d.sizeof * 13);
    }

    void draw() {

        auto sw = StopWatch(AutoStart.yes);

        Vec2d windowCenter = vec2dMultiply(Window.getSize(), Vec2d(0.5, 0.5));

        const double guiScale = GUI.getGUIScale();

        // Size horizontal.
        //? 40, 4
        const double shx = 40.0 * guiScale;
        // Size vertical.
        const double shy = 6.0 * guiScale;
        // Half width.
        const double hx = shx * 0.5;
        // Half height.
        const double hy = shy * 0.5;

        const double a = windowCenter.x - hx;
        const double b = windowCenter.y - hy;
        const double c = windowCenter.x - hy;
        const double d = windowCenter.y - hx;
        const double e = windowCenter.x + hy;
        const double f = windowCenter.x + hx;
        const double g = windowCenter.y + hy;
        const double h = windowCenter.y + hx;
        const double i = hx - hy;

        // Left
        (rectangles + 0).x = a;
        (rectangles + 0).y = b;
        (rectangles + 0).width = i;
        (rectangles + 0).height = shy;

        // Right
        (rectangles + 1).x = e;
        (rectangles + 1).y = b;
        (rectangles + 1).width = i;
        (rectangles + 1).height = shy;

        // Vertical.
        (rectangles + 2).x = c;
        (rectangles + 2).y = d;
        (rectangles + 2).width = shy;
        (rectangles + 2).height = shx;

        // This starts at the top left of the horizontal bar then wraps around clockwise.
        (linePoints + 0).x = a;
        (linePoints + 0).y = b;
        (linePoints + 1).x = c;
        (linePoints + 1).y = b;
        (linePoints + 2).x = c;
        (linePoints + 2).y = d;
        (linePoints + 3).x = e;
        (linePoints + 3).y = d;
        (linePoints + 4).x = e;
        (linePoints + 4).y = b;
        (linePoints + 5).x = f;
        (linePoints + 5).y = b;
        (linePoints + 6).x = f;
        (linePoints + 6).y = g;
        (linePoints + 7).x = e;
        (linePoints + 7).y = g;
        (linePoints + 8).x = e;
        (linePoints + 8).y = h;
        (linePoints + 9).x = c;
        (linePoints + 9).y = h;
        (linePoints + 10).x = c;
        (linePoints + 10).y = g;
        (linePoints + 11).x = a;
        (linePoints + 11).y = g;
        (linePoints + 12).x = a;
        (linePoints + 12).y = b;

        static const ULTRA_DARK_GRAY = Color(55, 55, 55, 255);
        static const Color debugColor = Colors.BLACK;
        static const Color WHITE = Colors.WHITE;

        //? First pass uses subtractive blend mode.
        //? This causes issues when looking at gray things like stone.
        BeginBlendMode(BlendMode.BLEND_SUBTRACT_COLORS);
        Render2d.drawRectangles(rectangles, 3, WHITE);

        //? Second pass layers on lightness to make it stand out more.
        BeginBlendMode(BlendMode.BLEND_ADD_COLORS);
        Render2d.drawRectangles(rectangles, 3, ULTRA_DARK_GRAY);
        EndBlendMode();

        //? Third pass draws an outline on the cursor.
        Render2d.drawLinesConnected(linePoints, 13, debugColor);

        writeln("took: ", cast(double) sw.peek().total!"hnsecs", " hns");

    }

}
