module graphics.texture_handler;

import fast_pack;
import math.rect;
import math.vec2d;
import math.vec2i;
import raylib;
import std.container;
import std.conv;
import std.file;
import std.path;
import std.regex;
import std.stdio;
import std.string;

alias TexPoints = const(TexturePoints!Vec2d*);

static final const class TextureHandler {
static:
private:

    // This is an aggressive micro optimization.
    TexturePoints!Vec2d[int] texturePointIndexDatabase;
    Vec2d[int] textureSizeDatabase;
    int[string] nameToIndexDatabase;

    TexturePoints!Vec2d[string] texturePointDatabase;
    Rect[string] textureRectangleDatabase;

    Texture2D atlas;
    int atlasWidth = 0;
    int atlasHeight = 0;

public: //* BEGIN PUBLIC API.

    void initialize() {

        // Playing hot potato with the texture data.
        // todo: go into the mods folder as well and search each textures folder with span depth!

        TexturePacker!string database = TexturePacker!string(1);
        foreach (string thisFilePathString; dirEntries("textures", "*.png", SpanMode.depth)) {
            loadTexture(thisFilePathString, database);
        }
        database.finalize("atlas.png");
        atlas = Texture2D();
        atlas = LoadTexture(toStringz("atlas.png"));

        atlasWidth = atlas.width;
        atlasHeight = atlas.height;

        database.extractTexturePoints(texturePointDatabase);

        // This is just a small bolt on to transfer the types over.
        struct RectTemp {
            double x = 0;
            double y = 0;
            double w = 0;
            double h = 0;
        }

        RectTemp[string] tempDatabase;
        database.extractRectangles(tempDatabase);

        foreach (key, rectangle; tempDatabase) {
            textureRectangleDatabase[key] = Rect(
                rectangle.x,
                rectangle.y,
                rectangle.w,
                rectangle.h
            );
        }

        // Aggressive micro optimization.
        foreach (index, key; texturePointDatabase.keys) {
            nameToIndexDatabase[key] = cast(int) index;
            texturePointIndexDatabase[cast(int) index] = texturePointDatabase[key];
            Rect thisRect = textureRectangleDatabase[key];
            textureSizeDatabase[cast(int) index] = Vec2d(thisRect.width, thisRect.height);
        }

        // Final rehash.
        texturePointDatabase = texturePointDatabase.rehash();
        textureRectangleDatabase = textureRectangleDatabase.rehash();
        nameToIndexDatabase = nameToIndexDatabase.rehash();
        texturePointIndexDatabase = texturePointIndexDatabase.rehash();

        // Then all of this will be GCed. :)
    }

    bool hasTexture(string textureName) {
        return (textureName in texturePointDatabase) !is null;
    }

    Vec2d getSize(string textureName) {

        Rect* thisRect = textureName in textureRectangleDatabase;
        if (thisRect is null) {
            throw new Error("Tried to get null texture size of " ~ textureName);
        }

        return Vec2d(thisRect.width, thisRect.height);
    }

    const(Vec2d*) getSizeByID(int ID) {
        //? Note: this is tuned for speed. Don't use this in mods.
        return ID in textureSizeDatabase;
    }

    const(TexturePoints!(Vec2d)*) getPoints(string name) {
        const TexturePoints!(Vec2d)* output = name in texturePointDatabase;

        if (output is null) {
            throw new Error("Tried to get null texture points for " ~ name);
        }

        return output;
    }

    int getIDFromName(string name) {
        int* thisID = name in nameToIndexDatabase;

        if (thisID is null) {
            throw new Error("Tried to get ID of null texture " ~ name);
        }

        return *thisID;
    }

    const(TexturePoints!(Vec2d)*) getPointsByID(int id) {
        //? Note: this is tuned for speed. Don't use this in mods.
        return id in texturePointIndexDatabase;
    }

    Texture2D getAtlas() {
        return atlas;
    }

    void terminate() {
        UnloadTexture(atlas);
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
}
