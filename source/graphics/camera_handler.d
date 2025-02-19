module graphics.camera_handler;

import game.player;
import graphics.gui;
import math.vec2d;
import raylib;
import std.stdio;
import utility.window;

static final const class CameraHandler {
static:
private:

    Camera3D* camera;

public: //* BEGIN PUBLIC API.

    double realZoom = 100.0;

    void initialize() {
        camera = new Camera3D();

        camera.position = Vector3(0, 0, 3);
        camera.target = Vector3(0, 0, 0);
        camera.up = Vector3(0, 1, 0);
        camera.fovy = 55;
        camera.projection = CameraProjection.CAMERA_PERSPECTIVE;
    }

    void terminate() {
        camera = null;
    }

    void begin() {
        // UpdateCamera(camera, CameraMode.CAMERA_ORBITAL);
        BeginMode3D(*camera);
    }

    void end() {
        EndMode3D();
    }

    // void setTarget(const ref Vec3d position) {
    //     camera.target = position.toRaylib();
    // }

    double getZoom() {
        return realZoom;
    }

    void setZoom(double zoom) {
        realZoom = zoom;
    }

    // Vec2d screenToWorld(const ref Vec2d position) {
    //     return Vec2d(GetScreenToWorld2D(position.toRaylib(), *camera));
    // }

    // void centerToPlayer() {
    //     Vec2d playerPosition = Player.getPosition();
    //     Vec2d offset = Player.getSize();
    //     offset.x = 0;
    //     //? this will move it to the center of the collisionbox.
    //     // offset.y *= -0.5;
    //     offset.y = 0;

    //     Vec2d playerCenter = vec2dAdd(playerPosition, offset);

    //     camera.target = playerCenter.toRaylib();
    // }

    // Vec2d screenToWorld(int x, int y) {

    //     return Vec2d(GetScreenToWorld2D(Vec2d(x, y).toRaylib(), *camera));
    // }

    void __update() {
        // camera.offset = vec2dMultiply(Window.getSize(), Vec2d(0.5, 0.5)).toRaylib();
        // camera.zoom = realZoom * GUI.getGUIScale();
    }

private: //* BEGIN INTERNAL API.

}
