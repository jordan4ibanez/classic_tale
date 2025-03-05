module game.block_database;

import graphics.texture_handler;
import std.conv;
import std.stdio;
import std.string;

enum Drawtype {
    Air,
    Normal,
    Model,
    Liquid
}

class BlockDefinition {
    string name = null;
    string modName = null;
    // Front, back, left, right, top, bottom.
    string[6] textures = null;
    // This is reserved.
    int[6] textureIDs = -1;
    int id = -1;

    // Visual properties.
    bool clear = false;

    // Physical properties.
    double friction = 2.0;
    double maxSpeed = 3.0;
}

static final const class BlockDatabase {
static:
private:

    // Faster access based on ID or name.
    BlockDefinition[string] nameDatabase;
    BlockDefinition[int] idDatabase;

    int currentID = 2;

public: //* BEGIN PUBLIC API.

    void registerBlock(BlockDefinition newBlock) {

        if (newBlock.name is null) {
            throw new Error("Name for block is null.");
        }

        if (newBlock.name.toLower() == "air") {
            throw new Error("Block air is reserved by engine.");
        }

        if (newBlock.name in nameDatabase) {
            throw new Error("Trying to overwrite block " ~ newBlock.name);
        }

        if (newBlock.modName is null) {
            throw new Error("Mod name is null for block " ~ newBlock.name);
        }

        foreach (index, const string thisTexture; newBlock.textures) {

            if (thisTexture is null) {
                throw new Error(
                    "Texture is null for block " ~ newBlock.name ~ " index: " ~ to!string(index));
            }

            if (!TextureHandler.hasTexture(thisTexture)) {
                throw new Error(
                    "Texture " ~ thisTexture ~ "for block " ~ newBlock.name ~ " index: " ~ to!string(
                        index) ~ " does not exist");
            }
        }

        nameDatabase[newBlock.name] = newBlock;
    }

    bool hasBlockID(int id) {
        return (id in idDatabase) !is null;
    }

    bool hasBlockName(string name) {
        return (name in nameDatabase) !is null;
    }

    const(BlockDefinition*) getBlockByID(int id) {
        return id in idDatabase;
    }

    const(BlockDefinition*) getBlockByName(string name) {
        return name in nameDatabase;
    }

    void finalize() {

        makeAir();
        makeBedrock();

        foreach (name, ref thisDefinition; nameDatabase) {

            if (name == "air" || name == "bedrock") {
                continue;
            }

            foreach (index, textureName; thisDefinition.textures) {
                thisDefinition.textureIDs[index] = TextureHandler.getIDFromName(textureName);
            }

            // todo: do the match thing below when mongoDB is added in.
            thisDefinition.id = nextID();
            idDatabase[thisDefinition.id] = thisDefinition;

            debugWrite(thisDefinition);
        }

        // Final rehash.
        idDatabase = idDatabase.rehash();
        nameDatabase = nameDatabase.rehash();
    }

private: //* BEGIN INTERNAL API.

    void makeAir() {
        BlockDefinition air = new BlockDefinition();
        air.name = "air";
        air.modName = "engine";
        // Air doesn't get any textures, it's never rendered.
        // air.textures = "air.png";

        // todo: do the match thing below when mongoDB is added in.
        air.id = 0;

        debugWrite(air);

        nameDatabase[air.name] = air;
        idDatabase[air.id] = air;
    }

    void makeBedrock() {
        BlockDefinition bedrock = new BlockDefinition();
        bedrock.name = "bedrock";
        bedrock.modName = "engine";
        bedrock.textures = "bedrock.png";
        bedrock.textureIDs = TextureHandler.getIDFromName("bedrock.png");
        // todo: do the match thing below when mongoDB is added in.
        bedrock.id = 1;

        debugWrite(bedrock);

        nameDatabase[bedrock.name] = bedrock;
        idDatabase[bedrock.id] = bedrock;
    }

    void debugWrite(BlockDefinition definition) {
        writeln("Block " ~ definition.name ~ " at ID " ~ to!string(definition.id));
    }

    // todo: make this pull the standard IDs into an associative array from the mongoDB.
    // todo: mongoDB should store the MAX current ID and restore it.
    // todo: Then, match to it. If it doesn't match, this is a new block.
    // todo: Then you'd call into this. :)
    int nextID() {
        int thisID = currentID;
        currentID++;
        return thisID;
    }

}
