module source.utility.screenshot;

import controls.keyboard;
import raylib;
import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
import std.file;
import std.path;
import std.stdio;
import std.string;

static final const class Screenshot {
static:
private:

    string workingDir = "";
    bool trigger = false;

public:

    void initialize() {
        workingDir = getcwd();
    }

    /// This is a hackjob for using f12 as the screenshot key for now.
    /// todo: disable f12 screenshot and implement this thing properly.
    /// Teach an engineer to engine and he'll run out of gas or something.
    void listen() {
        if (Keyboard.isDown(KeyboardKey.KEY_F12)) {
            trigger = true;
        }

        // This runs one after another to get a delta time.
        if (trigger) {

            const DirEntry[] entries = dirEntries(workingDir, SpanMode.shallow)
                .filter!((DirEntry a) => a.isFile())
                .filter!((DirEntry a) => a.name().indexOf("screenshot") >= 0)
                .array();

            if (entries.length <= 0) {
                trigger = false;
                return;
            }

            writeln("Processing screenshots.");

            const SysTime time = Clock.currTime();
            string[] fileName = [];
            fileName ~= to!string(time.month()) ~ "-";
            fileName ~= to!string(time.day()) ~ "-";
            fileName ~= to!string(time.year()) ~ "-";
            fileName ~= to!string(time.hour()) ~ "-";
            fileName ~= to!string(time.minute()) ~ ":";
            fileName ~= to!string(time.second()) ~ ":";
            fileName ~= to!string(time.fracSecs().total!"nsecs"());
            fileName ~= ".png";

            DirEntry targetFile = entries[0];

            const string newFileName = fileName.join();

            checkAndMove(targetFile, newFileName);
        }

    }

    void checkAndMove(DirEntry screenshot, string newFileName) {

        string path = buildPath(workingDir, "screenshots");

        if (!exists(path)) {
            try {
                mkdir(path);
            } catch (Exception anything) {
                // Why did you run the game somewhere you don't have permissions!?
                return;
            }
        }

        path = buildPath(path, newFileName);

        try {
            screenshot.rename(path);
        } catch (Exception e) {
            // Again!
            return;
        }
    }
}
