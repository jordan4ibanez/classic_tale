module graphics.model_handler;

public import raylib : Model;
import graphics.shader_handler;
import graphics.texture_handler;
import math.quat;
import math.vec3d;
import raylib;
import std.container;
import std.stdio;
import std.string;

class AnimationContainer {
    int animationCount = 0;
    bool hasAnimation = false;
    ModelAnimation* animationData = null;
}

static final const class ModelHandler {
static:
private:

    Model*[string] database;
    bool[string] isCustomDatabase;
    AnimationContainer[string] animationDatabase;
    Texture2D* textureAtlasPointer;

public: //* BEGIN PUBLIC API.

    void initialize() {
        textureAtlasPointer = TextureHandler.getAtlasPointer();
    }

    bool modelExists(string name) {
        return (name in database) !is null;
    }

    void draw(
        string modelName, Vec3d position, Vec3d rotation = Vec3d(0, 0, 0),
        float scale = 1.0, Color color = Colors.WHITE) {

        Model* thisModel = database[modelName];

        if (thisModel is null) {
            throw new Error("[ModelManager]: Cannot draw model that does not exist. " ~ modelName);
        }

        // Have to jump through some hoops to rotate the model correctly.
        Quat quat = quatFromEuler(rotation.x, rotation.y, rotation.z);
        Vec3d axisRotation;
        double angle;
        quatToAxisAngle(quat, &axisRotation, &angle);

        DrawModelEx(*thisModel, position.toRaylib(), axisRotation.toRaylib(), RAD2DEG * angle,
            Vector3(scale, scale, scale), color);
    }

    void newModelFromMesh(string modelName, float[] vertices, float[] textureCoordinates) {

        if (modelName in database) {
            throw new Error(
                "[ModelManager]: Tried to overwrite mesh [" ~ modelName ~ "]. Delete it first.");
        }

        Mesh* thisMesh = new Mesh();

        thisMesh.vertexCount = cast(int) vertices.length / 3;
        thisMesh.triangleCount = thisMesh.vertexCount / 3;
        thisMesh.vertices = vertices.ptr;
        thisMesh.texcoords = textureCoordinates.ptr;

        UploadMesh(thisMesh, false);

        Model* thisModel = new Model();
        *thisModel = LoadModelFromMesh(*thisMesh);

        if (!IsModelValid(*thisModel)) {
            throw new Error("[ModelHandler]: Invalid model loaded from mesh. " ~ modelName);
        }

        database[modelName] = thisModel;
        isCustomDatabase[modelName] = true;

        foreach (index; 0 .. thisModel.materialCount) {
            thisModel.materials[index].maps[MATERIAL_MAP_DIFFUSE].texture = *textureAtlasPointer;
        }
    }

    void loadModelFromFile(string location) {
        Model* thisModel = new Model();

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

        *thisModel = LoadModel(toStringz(location));

        if (!IsModelValid(*thisModel)) {
            throw new Error("[ModelHandler]: Invalid model loaded from file. " ~ location);
        }

        int animationCount;
        ModelAnimation* thisAnimationData = LoadModelAnimations(toStringz(location), &animationCount);
        AnimationContainer thisModelAnimation = new AnimationContainer();
        thisModelAnimation.animationCount = animationCount;
        thisModelAnimation.animationData = thisAnimationData;
        thisModelAnimation.hasAnimation = thisAnimationData != null;

        database[fileName] = thisModel;
        isCustomDatabase[fileName] = false;
        animationDatabase[fileName] = thisModelAnimation;
    }

    void setModelShader(string modelName, string shaderName) {

        Model* thisModel = database[modelName];

        if (thisModel is null) {
            throw new Error(
                "[ModelManager]: Tried to set shader on non-existent model [" ~ modelName ~ "]");
        }

        Shader* thisShader = ShaderHandler.getShaderPointer(shaderName);
        foreach (index; 0 .. thisModel.materialCount) {
            thisModel.materials[index].shader = *thisShader;
        }
    }

    Model* getModelPointer(string modelName) {
        Model* thisModel = database[modelName];

        if (thisModel is null) {
            throw new Error(
                "[ModelManager]: Tried to set get non-existent model pointer [" ~ modelName ~ "]");
        }

        return thisModel;
    }

    void destroy(string modelName) {
        Model* thisModel = database[modelName];

        if (thisModel is null) {
            throw new Error("[ModelManager]: Tried to destroy non-existent model. " ~ modelName);
        }

        destroyModel(modelName, thisModel);

        database.remove(modelName);
        isCustomDatabase.remove(modelName);
        animationDatabase.remove(modelName);
    }

    void terminate() {
        textureAtlasPointer = null;
        foreach (modelName, thisModel; database) {
            destroyModel(modelName, thisModel);
        }
        database.clear();
        isCustomDatabase.clear();
        animationDatabase.clear();
    }

    void playAnimation(string modelName, int index, int frame) {

        Model* thisModel = database[modelName];

        if (thisModel is null) {
            throw new Error(
                "[ModelManager]: Tried to play animation on non-existent model. " ~ modelName);
        }

        AnimationContainer thisAnimation = animationDatabase[modelName];

        if (thisAnimation is null) {
            throw new Error(
                "[ModelManager]: Tried to play animation on model with no animation. " ~ modelName);
        }
        UpdateModelAnimation(*thisModel, thisAnimation.animationData[index], frame);
    }

    AnimationContainer getAnimationContainer(string modelName) {
        if (modelName !in animationDatabase) {
            throw new Error(
                "[ModelManager]: Tried to get non-existent animation container. " ~ modelName);
        }

        return animationDatabase[modelName];
    }

private: //* BEGIN INTERNAL API.

    void destroyModel(string modelName, Model* thisModel) {
        // If we were using the D runtime to make this model, we'll customize
        // the way we free the items. This makes the GC auto clear.
        if (isCustomDatabase[modelName]) {
            Mesh thisMeshInModel = thisModel.meshes[0];
            thisMeshInModel.vertexCount = 0;
            thisMeshInModel.vertices = null;
            thisMeshInModel.texcoords = null;
            UnloadMesh(thisMeshInModel);
            thisModel.meshes = null;
            thisModel.meshCount = 0;
            UnloadModel(*thisModel);
        } else {
            UnloadModel(*thisModel);

            AnimationContainer thisAnimations = animationDatabase[modelName];
            if (thisAnimations !is null && thisAnimations.hasAnimation) {
                UnloadModelAnimation(*thisAnimations.animationData);
            }
        }
    }

    //     void updateModelInGPU(string modelName) {

    //         const Model* thisModel = database[modelName];

    //         if (thisModel is null) {
    //             throw new Error(
    //                 "[ModelManager]: Tried to update non-existent model [" ~ modelName ~ "]");
    //         }

    //         /*
    // #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_POSITION    0
    // #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD    1
    // #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_NORMAL      2
    // #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_COLOR       3
    // #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_TANGENT     4
    // #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_TEXCOORD2   5
    // #define RL_DEFAULT_SHADER_ATTRIB_LOCATION_INDICES     6
    //         */

    //         foreach (i, thisMesh; thisModel.meshes[0 .. thisModel.meshCount]) {
    //             UpdateMeshBuffer(cast(Mesh) thisMesh, 0, thisMesh.vertices, cast(int)(
    //                     thisMesh.vertexCount * 3 * float.sizeof), 0);

    //             UpdateMeshBuffer(cast(Mesh) thisMesh, 1, thisMesh.texcoords, cast(int)(
    //                     thisMesh.vertexCount * 2 * float.sizeof), 0);
    //         }
    //     }

}
