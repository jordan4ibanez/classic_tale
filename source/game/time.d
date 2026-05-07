module game.time;

import game.light;
import std.conv;
import std.stdio;
import std.string;
import utility.delta;

static final const class Time {
static:
private:

    // Time Expansion Metric.
    // Converts (24_000 24 hour time virtual) to (86_400 real seconds, so time speed 1 is 24 hours).
    immutable double TEM = 3.6;
    // This inverts (86_400 real seconds 24 hour) to (24_000 24 hour time virtual).
    immutable double __convertTOD = 1.0 / TEM;

    double currentTime = 0;
    // 1 lasts 24 hours (1440 minutes).
    // 72 lasts 20 minutes.
    // 720 lasts 2 minutes.
    // 1440 lasts 1 minute.
    // 8_640 is 10 seconds.
    // 86_400 is 1 second.
    // The faster this goes, the less precision it has to the point where it looks incorrect.
    // But it is just double floating point precision loss.
    double timeSpeed = 8_640;

    void timeCalculation() {
        const double delta = Delta.getDelta();

        currentTime += (delta * timeSpeed) * __convertTOD;

        if (currentTime >= END_OF_DAY) {
            currentTime -= END_OF_DAY;
        }

        // writeln(currentTime, " | ", testTime);

    }

public:

    // Represents a virtual 24 hour clock.
    // These are basically both midnight.
    // But one is yesterday, and the other is today.
    immutable double END_OF_DAY = 24_000;
    immutable double START_OF_DAY = 0;

    double getTimeOfDay() {
        return currentTime;
    }

    /// Real 12/24 hour time.
    string getTimeOfDayString(bool use12Hour = true, bool displaySeconds = false) {

        string[] timeString = [];

        // Hour.
        const int rawTime = cast(int)(currentTime * 0.001);
        int outputTime = rawTime;
        if (use12Hour) {
            if (rawTime == 0 || rawTime == 12) {
                outputTime = 12;
            } else {
                outputTime %= 12;
            }
        }
        timeString ~= to!string(outputTime);

        // Ends with (* 60.0) instead of (* 100.0) to get it in classical 60 minute hour intervals.

        // Minute.
        timeString ~= rightJustify(
            to!string(cast(int)(((currentTime * 0.001) % 1.0) * 60.0)), 2, '0');

        if (displaySeconds) {
            // Seconds.
            timeString ~= rightJustify(
                to!string(cast(int)(((currentTime * 0.1) % 1.0) * 60.0)), 2, '0');
        }

        string output = timeString.join(":");

        if (use12Hour) {
            output ~= rawTime >= 12 ? " pm" : " am";
        }

        return output;
    }

    void update() {

        timeCalculation();

        //! Debug daylight cycle.

        // {
        //     import game.light;
        //     import utility.delta;

        //     double delta = Delta.getDelta();

        //     const timeSpeed = 0.01;

        //     if (brighter) {
        //         float level = Light.getCurrentLightLevel();
        //         level += delta * timeSpeed;
        //         if (level >= Light.GLOBAL_LIGHT_MAX) {
        //             level = Light.GLOBAL_LIGHT_MAX;
        //             brighter = false;
        //         }
        //         Light.setCurrentLightLevel(level);
        //     } else {
        //         float level = Light.getCurrentLightLevel();
        //         level -= delta * timeSpeed;
        //         if (level <= Light.GLOBAL_LIGHT_MIN) {
        //             level = Light.GLOBAL_LIGHT_MIN;
        //             brighter = true;
        //         }

        //     }
        // }

        //! End debug daylight cycle.

    }

}
