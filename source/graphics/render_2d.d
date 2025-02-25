module graphics.render_2d;

import raylib;

static final const class Render2d {
static:
private:

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

        const double topRightX = x + width;

        const double bottomLeftY = y + height;

        const double bottomRightX = x + width;
        const double bottomRightY = y + height;

        rlBegin(RL_TRIANGLES);
        {
            rlColor4ub(color.r, color.g, color.b, color.a);

            rlVertex2f(x, y);
            rlVertex2f(x, bottomLeftY);
            rlVertex2f(topRightX, y);

            rlVertex2f(topRightX, y);
            rlVertex2f(x, bottomLeftY);
            rlVertex2f(bottomRightX, bottomRightY);
        }
        rlEnd();
    }

}
