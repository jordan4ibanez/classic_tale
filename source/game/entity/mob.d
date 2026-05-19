module game.entity.mob;

import game.entity.entity;

class Mob : Entity {
protected:

    double eyeHeight = 1.625;

    // Jump logic.
    bool jumpQueued = false;
    double jumpQueueTimeout = 0.0;

    double rotation = 0;
    bool moving = false;
    bool skidding = false;
    bool onGround = false;

public:

    double getEyeHeight() {
        return eyeHeight;
    }

}
