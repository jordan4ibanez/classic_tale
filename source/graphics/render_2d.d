module graphics.render_2d;

import math.rect;
import math.vec2d;
import raylib;

static final const class Render2d {
static:
private:
@nogc:

public:

    void drawLine(const double startX, const double startY, const double endX, const double endY,
        const ref Color color) {

        rlBegin(RL_LINES);
        {
            rlColor4ub(color.r, color.g, color.b, color.a);
            rlVertex2f(startX, startY);
            rlVertex2f(endX, endY);
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
