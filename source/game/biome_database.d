module game.biome_database;

import game.block_database;

class BiomeDefinition {
    string name = null;
    string modName = null;

    uint id = 0;

    string grassLayer = null;
    uint grassLayerID = 0;
    string dirtLayer = null;
    uint dirtLayerID = 0;
    string stoneLayer = null;
    uint stoneLayerID = 0;

    // todo: noise parameters.

    // todo: ores.
}

static final const class BiomeDatabase {
static:
private:

    // Faster access based on ID or name.
    BiomeDefinition[string] nameDatabase;
    BiomeDefinition[int] idDatabase;

    int currentID = 0;

public: //* BEGIN PUBLIC API.

    void registerBiome(BiomeDefinition newBiome) {

        if (newBiome.name is null) {
            throw new Error("Biome is missing a name.");
        }

        if (newBiome.name in nameDatabase) {
            throw new Error("Tried to overwrite biome" ~ newBiome.name);
        }

        if (newBiome.modName is null) {
            throw new Error("Mod name is missing from biome " ~ newBiome.name);
        }

        if (newBiome.grassLayer is null) {
            throw new Error("Grass layer missing from biome " ~ newBiome.name);
        }

        if (newBiome.dirtLayer is null) {
            throw new Error("Dirt layer missing from biome " ~ newBiome.name);
        }

        if (newBiome.stoneLayer is null) {
            throw new Error("Stone layer missing from biome " ~ newBiome.name);
        }

        nameDatabase[newBiome.name] = newBiome;
    }

    const(BiomeDefinition*) getBiomeByID(int id) {
        return id in idDatabase;
    }

    const(BiomeDefinition*) getBiomeByName(string name) {
        return name in nameDatabase;
    }

    void finalize() {
        foreach (name, ref thisBiome; nameDatabase) {
            const(BlockDefinition*) grass = BlockDatabase.getBlockByName(
                thisBiome.grassLayer);
            if (grass is null) {
                throw new Error(
                    "Biome " ~ thisBiome.name ~ " grass layer " ~ thisBiome.grassLayer ~ " is not a registered block");
            }

            const(BlockDefinition*) dirt = BlockDatabase.getBlockByName(thisBiome.dirtLayer);
            if (dirt is null) {
                throw new Error(
                    "Biome " ~ thisBiome.name ~ " dirt layer " ~ thisBiome.dirtLayer ~ " is not a registered block");
            }

            const(BlockDefinition*) stone = BlockDatabase.getBlockByName(
                thisBiome.stoneLayer);
            if (stone is null) {
                throw new Error(
                    "Biome " ~ thisBiome.name ~ " stone layer " ~ thisBiome.stoneLayer ~ " is not a registered block");
            }

            thisBiome.grassLayerID = grass.blockID;
            thisBiome.dirtLayerID = dirt.blockID;
            thisBiome.stoneLayerID = stone.blockID;

            // todo: do the match thing below when mongoDB is added in.
            thisBiome.id = nextID();

            idDatabase[thisBiome.id] = thisBiome;

            debugWrite(thisBiome);
        }
    }

private: //* BEGIN INTERNAL API.

    void debugWrite(BiomeDefinition biome) {
        import std.conv;
        import std.stdio;

        writeln("Biome " ~ biome.name ~ " at ID " ~ to!string(biome.id));
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
