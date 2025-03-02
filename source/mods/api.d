module mods.api;

import game.biome_database;
import game.block_database;
import mods.cube_thing.main;

static final const class Api {
static:
private:

public: //* BEGIN PUBLIC API.

    void initialize() {
        cubeThingMain();

        finalize();
    }

private: //* BEGIN INTERNAL API.

    void finalize() {
        BlockDatabase.finalize();
        BiomeDatabase.finalize();
    

    }

}