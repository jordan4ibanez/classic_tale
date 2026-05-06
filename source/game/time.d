module game.time;

import game.light;
import std.conv;
import std.stdio;
import std.string;
import utility.delta;

static final const class Time {
static:
private:

    // Represents a virtual 24 hour clock.
    // These are basically both midnight.
    // But one is yesterday, and the other is today.
    immutable double endOfDay = 24_000;
    immutable double startOfDay = 0;

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

    // todo: this should probably be in the Light module.
    immutable double[] timeOfDayStamps = [
        0, // Midnight. Sun is completely down.
        4500, // Sunrise. Sun appears.
        12_000, // Noon. Sun is directly overhead.
        18_000, // Sunset. Sun starts to go down.
        // Sun goes completely down somewhere at this point but I have no idea where yet.
    ];

    immutable string[] timeOfDayNames = [
        "midnight",
        "sunrise",
        "noon",
        "sunset",
        // Sun down somewhere here.
    ];

    double lightLevel = 0;

    // This is optimized for time moving forward.
    int hitTimestamp(double prev, double curr) {
        foreach (ulong i, double timeStamp; timeOfDayStamps) {

            if (prev < timeStamp && curr >= timeStamp) {
                return cast(int) i;
            }
        }
        // Catch for midnight.
        if (prev > curr) {
            return 0;
        }

        return -1;
    }

    void timeCalculation() {
        const double delta = Delta.getDelta();

        const double prevTime = currentTime;

        currentTime += (delta * timeSpeed) * __convertTOD;

        if (currentTime >= endOfDay) {
            writeln("loop");

            currentTime -= endOfDay;
        }

        // writeln(currentTime, " | ", testTime);

        const int hitter = hitTimestamp(prevTime, currentTime);
        if (hitter >= 0) {
            writeln("Hit: ", timeOfDayNames[hitter]);
        }

        getTimeOfDayString(true);

    }

    void lightLevelCalculation() {
        Light.setCurrentLightLevel(lightLevel);
    }

public:

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
        lightLevelCalculation();

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
