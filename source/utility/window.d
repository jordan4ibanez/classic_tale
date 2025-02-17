module utility.window;

import graphics.camera_handler;
import graphics.font_handler;
import graphics.gui;
import math.vec2d;
import raylib;
import utility.delta;

static final const class Window {
static:
private:

    bool maximized = false;
    bool mouseLocked = false;

public: //* BEGIN PUBLIC API.

    void initialize() {
        SetConfigFlags(ConfigFlags.FLAG_WINDOW_RESIZABLE);

        // This is a hack to get the resolution.
        InitWindow(1, 1, "");
        int currentMonitor = GetCurrentMonitor();
        int monitorWidth = GetMonitorWidth(currentMonitor);
        int monitorHeight = GetMonitorHeight(currentMonitor);
        CloseWindow();

        InitWindow(monitorWidth / 2, monitorHeight / 2, "cube thing");
    }

    void terminate() {
        CloseWindow();
    }

    int getWidth() {
        return GetRenderWidth();
    }

    int getHeight() {
        return GetRenderHeight();
    }

    Vec2d getSize() {
        return Vec2d(getWidth(), getHeight());
    }

    bool shouldStayOpen() {
        // This calls the update system to automatically make common utilities run.
        updateSystem();

        return !WindowShouldClose();
    }

    void maximize() {
        maximized = true;
        MaximizeWindow();
    }

    void unmaximize() {
        maximized = false;
        RestoreWindow();
    }

    void toggleMaximize() {
        if (maximized) {
            unmaximize();
        } else {
            maximize();
        }
    }

    void lockMouse() {
        mouseLocked = true;
        DisableCursor();
    }

    void unlockMouse() {
        mouseLocked = false;
        EnableCursor();
    }

    void toggleMouseLock() {
        if (mouseLocked) {
            unlockMouse();
        } else {
            lockMouse();
        }
    }

    bool isMouseLocked() {
        return mouseLocked;
    }

private: //* BEGIN INTERNAL API.

    void updateSystem() {
        Delta.__calculateDelta();
        GUI.__update(getSize());
        CameraHandler.__update();
        // FontHandler.__update();
    }

}
