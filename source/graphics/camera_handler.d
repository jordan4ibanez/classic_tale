module graphics.camera_handler;

import controls.mouse;
import game.player;
import graphics.gui;
import math.vec2d;
import math.vec3d;
import raylib;
import raylib.rcamera;
import std.math.trigonometry;
import std.stdio;
import utility.window;

static final const class CameraHandler {
static:
private:

    Camera3D camera;

public: //* BEGIN PUBLIC API.

    double realZoom = 100.0;
    double yaw = 0;
    double pitch = 0;
    double cameraSensitivity = 1.0;

    void initialize() {
        camera = Camera3D();

        camera.position = Vector3(0, 170, 0);
        camera.up = Vector3(0, 1, 0);
        camera.fovy = 55;
        camera.projection = CameraProjection.CAMERA_PERSPECTIVE;
    }

    void terminate() {
        // I'm sure I'll find something to put in here.
    }

    void firstPersonControls() {

        const Vec2d mouseDelta = Mouse.getDelta();

        camera.position = Player.getPosition().toRaylib();

        yaw += mouseDelta.x / (750.0 / cameraSensitivity);
        pitch -= mouseDelta.y / (750.0 / cameraSensitivity);

        // When it hits exactly half pi, the camera's matrix flips out.
        // This is exactly why you don't use direction for this.  
        static immutable double HALF_PI_ALMOST = PI * 0.495;

        if (pitch > HALF_PI_ALMOST) {
            pitch = HALF_PI_ALMOST;
        } else if (pitch < -HALF_PI_ALMOST) {
            pitch = -HALF_PI_ALMOST;
        }

        static immutable double DOUBLE_PI = PI * 2.0;

        if (yaw > DOUBLE_PI) {
            yaw -= DOUBLE_PI;
        } else if (yaw < 0.0) {
            yaw += DOUBLE_PI;
        }
    }

    void updateToPlayerPosition() {
        // https://stackoverflow.com/a/1568687 Thanks, Beta! https://creativecommons.org/licenses/by-sa/4.0/
        camera.target.x = camera.position.x + (cos(yaw) * cos(pitch));
        camera.target.y = camera.position.y + sin(pitch);
        camera.target.z = camera.position.z + (sin(yaw) * cos(pitch));
    }

    double getYaw() {
        return yaw;
    }

    void begin() {
        UpdateCamera(&camera, CameraMode.CAMERA_CUSTOM);
        BeginMode3D(camera);
    }

    void end() {
        EndMode3D();
    }

    Vec3d getPosition() {
        return Vec3d(camera.position);
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
