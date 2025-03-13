module game.block_database;

import core.memory;
import graphics.model_handler;
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

    // Visual properties.
    Drawtype drawtype = Drawtype.Normal;
    // If it is drawtype model, it will use this.
    string model = null;

    // Physical properties.
    double friction = 2.0;
    double maxSpeed = 3.0;
    // lightPropagates means light passes through it.
    bool lightPropagates = false;
    bool isLightSource = false;
    ubyte lightSourceLevel = 0;

    // These are reserved.
    int[6] textureIDs = -1;
    uint blockID = 0;
    ulong modelIndex = 0;
}

static final const class BlockDatabase {
static:
private:

    // Faster access based on ID or name.
    BlockDefinition[string] nameDatabase;
    BlockDefinition[int] idDatabase;
    /// If you use this in your mods I'm not helping you with segfaults.
    // This is only intended to be used for the map model generator.
    BlockDefinition* ultraFastAccess;

    uint currentID = 2;

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

        if (newBlock.isLightSource) {
            if (newBlock.lightSourceLevel > 14) {
                throw new Error("Light source can not be as bright as sunlight");
            }

            if (newBlock.lightSourceLevel < 2) {
                writeln("warning: block [" ~ newBlock.name ~ "] will not emit any light");
            }
        }

        if (newBlock.drawtype != Drawtype.Air && newBlock.drawtype != Drawtype.Model) {
            foreach (index, const string thisTexture; newBlock.textures) {

                if (thisTexture is null) {
                    throw new Error(
                        "Texture is null for block " ~ newBlock.name ~ " index: " ~ to!string(
                            index));
                }

                if (!TextureHandler.hasTexture(thisTexture)) {
                    throw new Error(
                        "Texture " ~ thisTexture ~ "for block " ~ newBlock.name ~ " index: " ~ to!string(
                            index) ~ " does not exist");
                }
            }
        }

        nameDatabase[newBlock.name] = newBlock;
    }

    bool hasBlockID(uint blockID) {
        return (blockID in idDatabase) !is null;
    }

    bool hasBlockName(string name) {
        return (name in nameDatabase) !is null;
    }

    const(BlockDefinition*) getBlockByID(uint blockID) {
        return blockID in idDatabase;
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

            if (thisDefinition.drawtype == Drawtype.Model) {
                thisDefinition.modelIndex = ModelHandler.getStaticIndexFromName(
                    thisDefinition.model);
            } else {
                foreach (index, textureName; thisDefinition.textures) {
                    thisDefinition.textureIDs[index] = TextureHandler.getIDFromName(textureName);
                }
            }

            // todo: do the match thing below when mongoDB is added in.
            thisDefinition.blockID = nextID();
            idDatabase[thisDefinition.blockID] = thisDefinition;

            debugWrite(thisDefinition);
        }

        // Final rehash.
        idDatabase = idDatabase.rehash();
        nameDatabase = nameDatabase.rehash();

        // This is so the map generator can speed wayyy up.
        mapToPointerArray();
    }

    /// If you use this in your mods I'm not helping you with segfaults.
    /// This is only intended to be used for the map model generator.
    const(BlockDefinition*) getUltraFastAccess() {
        return ultraFastAccess;
    }

private: //* BEGIN INTERNAL API.

    void mapToPointerArray() {
        // currentID is assumed to be at the max ID defined. 
        // todo: If there are holes, and a segfault has brought you here, that MUST be fixed.
        ultraFastAccess = cast(BlockDefinition*) GC.malloc(BlockDefinition.sizeof * currentID);

        foreach (i; 0 .. currentID) {
            *(ultraFastAccess + i) = idDatabase[i];
        }
    }

    void makeAir() {
        BlockDefinition air = new BlockDefinition();
        air.name = "air";
        air.modName = "engine";
        air.drawtype = Drawtype.Air;
        air.lightPropagates = true;
        // Air doesn't get any textures, it's never rendered.
        // air.textures = "air.png";

        // todo: do the match thing below when mongoDB is added in.
        air.blockID = 0;

        debugWrite(air);

        nameDatabase[air.name] = air;
        idDatabase[air.blockID] = air;
    }

    void makeBedrock() {
        BlockDefinition bedrock = new BlockDefinition();
        bedrock.name = "bedrock";
        bedrock.modName = "engine";
        bedrock.textures = "bedrock.png";
        bedrock.textureIDs = TextureHandler.getIDFromName("bedrock.png");
        // todo: do the match thing below when mongoDB is added in.
        bedrock.blockID = 1;

        debugWrite(bedrock);

        nameDatabase[bedrock.name] = bedrock;
        idDatabase[bedrock.blockID] = bedrock;
    }

    void debugWrite(BlockDefinition definition) {
        writeln("Block " ~ definition.name ~ " at ID " ~ to!string(definition.blockID));
    }

    // todo: make this pull the standard IDs into an associative array from the mongoDB.
    // todo: mongoDB should store the MAX current ID and restore it.
    // todo: Then, match to it. If it doesn't match, this is a new block.
    // todo: Then you'd call into this. :)
    uint nextID() {
        uint thisID = currentID;
        currentID++;
        return thisID;
    }

}
