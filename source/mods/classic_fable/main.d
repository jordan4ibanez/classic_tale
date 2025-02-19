module mods.cube_thing.main;

import game.biome_database;
import game.block_database;
import std.stdio;

private immutable string nameOfMod = "CubeThing";

class CubeThingBlock : BlockDefinition {
    this() {
        this.modName = nameOfMod;
    }
}

class CubeThingBiome : BiomeDefinition {
    this() {
        this.modName = nameOfMod;
    }
}

void cubeThingMain() {

    //? Blocks.

    CubeThingBlock stone = new CubeThingBlock();
    stone.name = "stone";
    stone.textures = "default_stone.png";
    BlockDatabase.registerBlock(stone);

    CubeThingBlock dirt = new CubeThingBlock();
    dirt.name = "dirt";
    dirt.textures = "default_dirt.png";
    BlockDatabase.registerBlock(dirt);

    CubeThingBlock grass = new CubeThingBlock();
    grass.name = "grass";
    grass.textures = "default_grass.png";
    BlockDatabase.registerBlock(grass);

    //? Biomes.

    CubeThingBiome grassLands = new CubeThingBiome();
    grassLands.name = "grass lands";
    grassLands.grassLayer = "grass";
    grassLands.dirtLayer = "dirt";
    grassLands.stoneLayer = "stone";

    BiomeDatabase.registerBiome(grassLands);

}
