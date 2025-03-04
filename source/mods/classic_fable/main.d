module mods.cube_thing.main;

import game.biome_database;
import game.block_database;
import graphics.model_handler;
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
    stone.textures = "stone.png";
    BlockDatabase.registerBlock(stone);

    CubeThingBlock dirt = new CubeThingBlock();
    dirt.name = "dirt";
    dirt.textures = "dirt.png";
    BlockDatabase.registerBlock(dirt);

    CubeThingBlock grass = new CubeThingBlock();
    grass.name = "grass";
    // Front, back, left, right, top, bottom.
    grass.textures = [
        "grass_side.png", "grass_side.png", "grass_side.png", "grass_side.png",
        "grass.png", "dirt.png"
    ];
    BlockDatabase.registerBlock(grass);

    //? Models.
    ModelHandler.loadModelFromFile("models/torch/torch.glb", "torch.png");

    //? Biomes.

    CubeThingBiome grassLands = new CubeThingBiome();
    grassLands.name = "grass lands";
    grassLands.grassLayer = "grass";
    grassLands.dirtLayer = "dirt";
    grassLands.stoneLayer = "stone";

    BiomeDatabase.registerBiome(grassLands);

}
