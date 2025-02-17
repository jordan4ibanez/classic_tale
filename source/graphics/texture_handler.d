module graphics.texture_handler;

import fast_pack;
import math.rect;
import math.vec2d;
import raylib;
import std.container;
import std.file;
import std.path;
import std.regex;
import std.stdio;
import std.string;

static final const class TextureHandler {
static:
private:

    TexturePoints!Vec2d[string] texturePointDatabase;
    Texture2D* atlas;

public: //* BEGIN PUBLIC API.

    void initialize() {

        // Playing hot potato with the texture data.
        // todo: go into the mods folder as well and search each textures folder with span depth!

        TexturePacker!string database = TexturePacker!string(1);
        foreach (string thisFilePathString; dirEntries("textures", "*.png", SpanMode.depth)) {
            loadTexture(thisFilePathString, database);
        }
        database.finalize("atlas.png");
        *atlas = LoadTexture(toStringz("atlas.png"));

        database.extractTexturePoints(texturePointDatabase);
    }

    bool hasTexture(string textureName) {
        return (textureName in texturePointDatabase) !is null;
    }

private: //* BEGIN INTERNAL API.

    void loadTexture(string location, ref TexturePacker!string database) {

        // Extract the file name from the location.
        string fileName = () {
            string[] items = location.split("/");
            int len = cast(int) items.length;
            if (len <= 1) {
                throw new Error("[TextureManager]: Texture must not be in root directory.");
            }
            string outputFileName = items[len - 1];
            if (!outputFileName.endsWith(".png")) {
                throw new Error("[TextureManager]: Not a .png");
            }
            return outputFileName;
        }();

        database.pack(fileName, location);
    }

    Texture2D* getAtlasPointer() {
        return atlas;
    }

    void terminate() {
        UnloadTexture(*atlas);
    }
}
