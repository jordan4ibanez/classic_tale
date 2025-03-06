module graphics.model_handler;

public import raylib : Model;
import core.memory;
import graphics.shader_handler;
import graphics.texture_handler;
import math.quat;
import math.rect;
import math.vec3d;
import raylib;
import std.container;
import std.conv;
import std.stdio;
import std.string;
import utility.uuid;

struct AnimationContainer {
    int animationCount = 0;
    bool hasAnimation = false;
    ModelAnimation* animationData = null;
}

static final const class ModelHandler {
static:
private:

    // Dynamic models can be created and destroyed freely.
    // They cannot have animation data. (Too complicated for now)
    Model[ulong] dynamicDatabase;

    // Static models exist from the start to the end of the game's lifetime.
    // They can have animation data.
    // The model name to index database will give you the index into the pointer.
    Model* staticDatabase;
    ulong countStaticDatabase = 0;
    ulong[string] modelNameToIndex;
    bool lock = false;
    // Todo: synchronize this.
    // AnimationContainer[ulong] animationDatabase;
    Texture2D textureAtlas;

public: //* BEGIN PUBLIC API.

    void initialize() {
        textureAtlas = TextureHandler.getAtlas();
    }

    bool modelExists(ulong id) {
        return (id in dynamicDatabase) !is null;
    }

    void drawDynamic(ulong modelID, Vec3d position, Vec3d rotation = Vec3d(0, 0, 0),
        float scale = 1.0, Color color = Colors.WHITE) {

        Model* thisModel = modelID in dynamicDatabase;

        if (thisModel is null) {
            throw new Error(
                "[ModelManager]: Cannot draw model that does not exist. " ~ to!string(modelID));
        }

        // Have to jump through some hoops to rotate the model correctly.
        Quat quat = quatFromEuler(rotation.x, rotation.y, rotation.z);
        Vec3d axisRotation;
        double angle;
        quatToAxisAngle(quat, &axisRotation, &angle);

        DrawModelEx(*thisModel, position.toRaylib(), axisRotation.toRaylib(), RAD2DEG * angle,
            Vector3(scale, scale, scale), color);
    }

    /*
    Immediate wipe will instantly replace the mesh data with null pointers so the
    GC can work it's magic.
    ? This is pretty much exclusively used for the map model generator.
    */
    ulong newModelFromMeshPointers(float* vertices, immutable ulong verticesLength,
        float* textureCoordinates, float* normals, ubyte* colors) {

        const ulong thisID = UUID.get();

        // if (modelName in numberDatabase) {
        //     throw new Error(
        //         "[ModelManager]: Tried to overwrite mesh [" ~ modelName ~ "]. Delete it first.");
        // }

        Mesh thisMesh = Mesh();

        thisMesh.vertexCount = cast(int) verticesLength / 3;
        thisMesh.triangleCount = thisMesh.vertexCount / 3;
        thisMesh.vertices = vertices;
        thisMesh.texcoords = textureCoordinates;
        thisMesh.normals = normals;
        thisMesh.colors = colors;

        UploadMesh(&thisMesh, false);

        Model thisModel = Model();
        thisModel = LoadModelFromMesh(thisMesh);

        if (!IsModelValid(thisModel)) {
            throw new Error("[ModelHandler]: Invalid model loaded from mesh. " ~ to!string(thisID));
        }

        dynamicDatabase[thisID] = thisModel;
        // isCustomDatabase[thisID] = true;

        foreach (index; 0 .. thisModel.materialCount) {
            thisModel.materials[index].maps[MATERIAL_MAP_DIFFUSE].texture = textureAtlas;
        }

        // Launch the GC into action to clean the data we no longer need.
        // This looks a bit silly, because it is. I just like to double check. :)
        thisMesh.vertices = null;
        thisMesh.texcoords = null;
        thisMesh.normals = null;
        thisMesh.colors = null;
        thisModel.meshes[0].vertices = null;
        thisModel.meshes[0].texcoords = null;
        thisModel.meshes[0].normals = null;
        thisModel.meshes[0].colors = null;

        return thisID;
    }

    void lockStatic() {
        this.lock = true;
    }

    /// Gives you the index into the static model pointer array.
    ulong getStaticIndexFromName(string modelName) {
        const ulong* thisModelIndex = modelName in modelNameToIndex;
        if (thisModelIndex is null) {
            throw new Error("Tried to get ID of non-existent model " ~ modelName);
        }
        return *thisModelIndex;
    }

    ulong loadModelFromFile(string location, string[] textures...) {
        // The lock is not here to stop you from being creative.
        // The lock is here to stop the engine from blowing up. :P
        if (lock) {
            throw new Error("Do not create models during runtime");
        }
        Model thisModel = Model();

        // Extract the file name from the location.
        string fileName = () {
            string[] items = location.split("/");
            int len = cast(int) items.length;
            if (len <= 1) {
                throw new Error("[ModelManager]: Model must not be in root directory.");
            }
            string outputFileName = items[len - 1];
            return outputFileName;
        }();

        if (fileName in modelNameToIndex) {
            throw new Error("Tried to override existing model " ~ fileName);
        }

        writeln("Loading model: [", location, "] as [", fileName, "]");

        thisModel = LoadModel(toStringz(location));

        // Something went horribly wrong.
        if (!IsModelValid(thisModel)) {
            throw new Error("[ModelHandler]: Invalid model loaded from file. " ~ location);
        }

        // Enforce all textures are loaded.
        if (thisModel.meshCount != textures.length) {
            throw new Error("Attempted to load [" ~ location ~ "] with mesh count [" ~ to!string(
                    thisModel.meshCount) ~ "] with [" ~ to!string(
                    textures.length) ~ "] textures. Not please add or remove textures.");
        }

        // Map to texture atlas.
        foreach (currentMeshIndex; 0 .. thisModel.meshCount) {

            const string thisTexture = textures[currentMeshIndex];

            const(Rect*) textureRectangle = TextureHandler.getRect(thisTexture);

            Mesh* thisMesh = &thisModel.meshes[currentMeshIndex];

            const ulong textureCount = thisMesh.vertexCount;

            foreach (__indexInto; 0 .. textureCount) {
                // X Y
                const ulong i = __indexInto * 2;

                const double oldX = thisMesh.texcoords[i];
                const double oldY = thisMesh.texcoords[i + 1];

                const double xInRect = textureRectangle.width * oldX;
                const double yInRect = textureRectangle.height * oldY;

                const double xInAtlas = textureRectangle.x + xInRect;
                const double yInAtlas = textureRectangle.y + yInRect;

                thisMesh.texcoords[i] = xInAtlas;
                thisMesh.texcoords[i + 1] = yInAtlas;
            }

            UpdateMeshBuffer(*thisMesh, 1, thisMesh.texcoords, cast(int)(
                    thisMesh.vertexCount * 2 * float.sizeof), 0);
        }

        // Set texture to texture atlas.
        foreach (index; 0 .. thisModel.materialCount) {
            thisModel.materials[index].maps[MATERIAL_MAP_DIFFUSE].texture = textureAtlas;
        }

        // Animations.
        // int animationCount;
        // ModelAnimation* thisAnimationData = LoadModelAnimations(toStringz(location), &animationCount);
        // AnimationContainer thisModelAnimation = AnimationContainer();
        // thisModelAnimation.animationCount = animationCount;
        // thisModelAnimation.animationData = thisAnimationData;
        // thisModelAnimation.hasAnimation = thisAnimationData != null;

        const ulong thisIndex = countStaticDatabase;

        countStaticDatabase++;

        modelNameToIndex[fileName] = thisIndex;

        staticDatabase = cast(Model*) GC.realloc(staticDatabase, Model.sizeof * countStaticDatabase);

        *(staticDatabase + thisIndex) = thisModel;

        // Insert into database.
        // numberDatabase[thisID] = thisModel;
        // isCustomDatabase[thisID] = false;
        // animationDatabase[thisID] = thisModelAnimation;

        // stringToIDDatabase[fileName] = thisID;

        return thisIndex;
    }

    void setModelShader(ulong modelID, string shaderName) {

        Model* thisModel = modelID in dynamicDatabase;

        if (thisModel is null) {
            throw new Error(
                "[ModelManager]: Tried to set shader on non-existent model [" ~ to!string(
                    modelID) ~ "]");
        }

        Shader* thisShader = ShaderHandler.getShaderPointer(shaderName);
        foreach (index; 0 .. thisModel.materialCount) {
            thisModel.materials[index].shader = *thisShader;
        }
    }

    Model* getModelPointer(ulong modelID) {
        Model* thisModel = modelID in dynamicDatabase;

        if (thisModel is null) {
            throw new Error(
                "[ModelManager]: Tried to set get non-existent model pointer [" ~ to!string(
                    modelID) ~ "]");
        }

        return thisModel;
    }

    void destroyDynamic(ulong modelID) {
        // 0 is reserved for null;
        if (modelID == 0) {
            return;
        }

        Model* thisModel = modelID in dynamicDatabase;

        if (thisModel is null) {
            throw new Error(
                "[ModelManager]: Tried to destroy non-existent model. " ~ to!string(modelID));
        }

        destroyModelDynamic(thisModel);

        dynamicDatabase.remove(modelID);
        // isCustomDatabase.remove(modelID);
        // animationDatabase.remove(modelID);
    }

    void terminate() {
        foreach (thisModel; dynamicDatabase) {
            destroyModelDynamic(&thisModel);
        }
        dynamicDatabase.clear();
        // isCustomDatabase.clear();
        // animationDatabase.clear();
    }

    // void playAnimation(ulong modelID, int index, int frame) {

    //     Model* thisModel = modelID in dynamicDatabase;

    //     if (thisModel is null) {
    //         throw new Error(
    //             "[ModelManager]: Tried to play animation on non-existent model. " ~ to!string(
    //                 modelID));
    //     }

    //     AnimationContainer* thisAnimation = modelID in animationDatabase;

    //     if (thisAnimation is null) {
    //         throw new Error(
    //             "[ModelManager]: Tried to play animation on model with no animation. " ~ to!string(
    //                 modelID));
    //     }
    //     UpdateModelAnimation(*thisModel, thisAnimation.animationData[index], frame);
    // }

    // const(AnimationContainer*) getAnimationContainer(ulong modelID) {
    //     AnimationContainer* thisAnimation = modelID in animationDatabase;
    //     if (thisAnimation is null) {
    //         throw new Error(
    //             "[ModelManager]: Tried to get non-existent animation container. " ~ to!string(
    //                 modelID));
    //     }
    //     return thisAnimation;
    // }

    void updateModelInGPU(ulong modelID) {

        const Model* thisModel = modelID in dynamicDatabase;

        if (thisModel is null) {
            throw new Error(
                "[ModelManager]: Tried to update non-existent model [" ~ to!string(modelID) ~ "]");
        }

        /*
    #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_POSITION    0
    #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD    1
    #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_NORMAL      2
    #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_COLOR       3
    #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_TANGENT     4
    #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD2   5
    #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_INDICES     6
            */

        foreach (i, thisMesh; thisModel.meshes[0 .. thisModel.meshCount]) {
            UpdateMeshBuffer(cast(Mesh) thisMesh, 0, thisMesh.vertices, cast(int)(
                    thisMesh.vertexCount * 3 * float.sizeof), 0);

            UpdateMeshBuffer(cast(Mesh) thisMesh, 1, thisMesh.texcoords, cast(int)(
                    thisMesh.vertexCount * 2 * float.sizeof), 0);
        }
    }

private: //* BEGIN INTERNAL API.

    void destroyModelDynamic(Model* thisModel) {
        // If we were using the D runtime to make this model, we'll customize
        // the way we free the items. This makes the GC auto clear.
        // if (isCustomDatabase[modelID]) {
        Mesh thisMeshInModel = thisModel.meshes[0];
        thisMeshInModel.vertexCount = 0;
        thisMeshInModel.vertices = null;
        thisMeshInModel.texcoords = null;
        UnloadMesh(thisMeshInModel);
        thisModel.meshes = null;
        thisModel.meshCount = 0;
        UnloadModel(*thisModel);
        // } else {
        //     UnloadModel(*thisModel);

        //     AnimationContainer* thisAnimations = modelID in animationDatabase;
        //     if (thisAnimations !is null && thisAnimations.hasAnimation) {
        //         UnloadModelAnimation(*thisAnimations.animationData);
        //     }
        // }
    }

    // void loadModelsInModelsFolder() {
    //     import std.file;
    //     foreach (string thisFilePathString; dirEntries("models", "*.{obj,gltf,glb,iqm,vox,m3d}", SpanMode
    //             .depth)) {
    //         loadModelFromFile(thisFilePathString);
    //     }
    // }

}
