module graphics.render_2d;

import math.rect;
import math.vec2d;
import raylib;

static final const class Render2d {
static:
private:
@nogc:

public:

    void drawLinesConnected(const Vec2d* points, const ulong numPoints, const ref Color color) {

        rlBegin(RL_LINES);
        {
            rlColor4ub(color.r, color.g, color.b, color.a);

            foreach (i; 0 .. (numPoints - 1)) {
                rlVertex2f((points + i).x, (points + i).y);
                rlVertex2f((points + i + 1).x, (points + i + 1).y);
            }
        }
        rlEnd();
    }

    void drawRectangles(const Rect* rects, const ulong numRects, const ref Color color) {

        rlBegin(RL_TRIANGLES);
        {
            rlColor4ub(color.r, color.g, color.b, color.a);

            foreach (i; 0 .. numRects) {

                const double x = (rects + i).x;
                const double y = (rects + i).y;
                const double a = x + (rects + i).width;
                const double b = y + (rects + i).height;

                rlVertex2f(x, y);
                rlVertex2f(x, b);
                rlVertex2f(a, y);

                rlVertex2f(a, y);
                rlVertex2f(x, b);
                rlVertex2f(a, b);
            }
        }
        rlEnd();
    }

}
