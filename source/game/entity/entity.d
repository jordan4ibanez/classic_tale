module game.entity.entity;

import math.vec2d;
import math.vec3d;

class Entity {
    //? Note: Entities position is at the bottom center of the collision box.

    /*
    |------------|
    |            |
    |            |
    |            |
    |            |
    |            |
    |            |
    |            |
    |            |
    |------X-----|
           ^
           |-------- Actual position
    */
protected:

    Vec2d size = Vec2d(0.6, 1.8);
    Vec3d position = Vec3d(0, 161, 0);
    Vec3d velocity = Vec3d(0, 0, 0);

public:

    Vec2d getSize() {
        return size;
    }

    Vec3d getPosition() {
        return position;
    }

    double getWidth() {
        return size.y;
    }

    double getHalfWidth() {
        return size.x * 0.5;
    }

    Vec3d getVelocity() {
        return velocity;
    }

    void setPosition(const ref Vec3d newPosition) {
        position = newPosition;
    }

    void setVelocity(const ref Vec3d newVelocity) {
        velocity = newVelocity;
    }
}
