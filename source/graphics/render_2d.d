module graphics.render_2d;

import math.rect;
import math.vec2d;
import raylib;

static final const class Render2d {
static:
private:
@nogc:

public:

    void drawLines(const Vec2d* points, const ulong numPoints, const ref Color color) {

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

    void drawRectangle(const double x, const double y, const double width, const double height, const ref Color color) {

        rlBegin(RL_TRIANGLES);
        {
            const double a = x + width;
            const double b = y + height;

            rlColor4ub(color.r, color.g, color.b, color.a);

            rlVertex2f(x, y);
            rlVertex2f(x, b);
            rlVertex2f(a, y);

            rlVertex2f(a, y);
            rlVertex2f(x, b);
            rlVertex2f(a, b);
        }
        rlEnd();
    }

}
