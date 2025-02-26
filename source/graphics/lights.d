module graphics.lights;

import graphics.camera_handler;
import graphics.shader_handler;
import math.vec3d;
import raylib;
import raylib.rcamera;
import std.stdio;
import utility.delta;

static const MAX_LIGHTS = 512;

static final const class Lights {
static:
private:

    int shaderAmbientLightLocation;
    int shaderViewPositionLocation;

    // Lantern is basically as if you're holding a lantern. 
    Light lantern;

    Light[4] testLights;

    float pos = 0;

    double ambientLight = 0.1;
    double up = false;

public:

    void initialize() {
        // shaderViewPositionLocation = ShaderHandler.getUniformLocation("main", "viewPos");
        shaderAmbientLightLocation = ShaderHandler.getUniformLocation("main", "ambient");

        float[3] ambientLightLevel = [0.05, 0.05, 0.1];

        SetShaderValue(*ShaderHandler.getShaderPointer("main"), shaderAmbientLightLocation,
            &ambientLightLevel, ShaderUniformDataType.SHADER_UNIFORM_VEC3);

        // Flame yellow.
        lantern = CreateLight(Vector3(0, 0, 0), Vector3(0, 0, 0),
            Color(255, 207, 73), 0.0, *ShaderHandler.getShaderPointer("main"));

        // testLights[0] = CreateLight(LightType.LIGHT_POINT, Vector3(0, 0, 0), Vector3(0, 0, 0),
        //     Colors.RED, *ShaderHandler.getShaderPointer("main"));

        // testLights[1] = CreateLight(LightType.LIGHT_POINT, Vector3(0, 0, 0), Vector3(0, 0, 0),
        //     Colors.GREEN, *ShaderHandler.getShaderPointer("main"));

        // testLights[2] = CreateLight(LightType.LIGHT_POINT, Vector3(0, 0, 0), Vector3(0, 0, 0),
        //     Colors.BLUE, *ShaderHandler.getShaderPointer("main"));

        // testLights[3] = CreateLight(LightType.LIGHT_POINT, Vector3(0, 0, 0), Vector3(0, 0, 0),
        //     Colors.WHITE, *ShaderHandler.getShaderPointer("main"));
    }

    void update() {

        double delta = Delta.getDelta();

        if (up) {
            lantern.brightness += delta * 10.0;
            if (lantern.brightness >= 20) {
                lantern.brightness = 20;
                up = false;
            }
        } else {

            lantern.brightness -= delta * 10.0;
            if (lantern.brightness <= 1) {
                lantern.brightness = 1;
                up = true;
            }
        }

        float[3] ambientLightLevel = [
            ambientLight, ambientLight, ambientLight * 1.05
        ];
        SetShaderValue(*ShaderHandler.getShaderPointer("main"), shaderAmbientLightLocation,
            &ambientLightLevel, ShaderUniformDataType.SHADER_UNIFORM_VEC3);

        const Vec3d camPos = CameraHandler.getPosition();
        ShaderHandler.setUniformVec3d("main", shaderViewPositionLocation, camPos);

        lantern.position = camPos.toRaylib();

        // Vec3d workerPos = camPos;

        // workerPos.x += 20;
        // testLights[0].position = workerPos.toRaylib();

        // workerPos.x -= 40;
        // testLights[1].position = workerPos.toRaylib();

        // workerPos.x += 20;
        // workerPos.z += 20;
        // testLights[2].position = workerPos.toRaylib();

        // workerPos.z -= 40;
        // testLights[3].position = workerPos.toRaylib();

        // DrawSphere(lantern.position, 10.0, Colors.RED);

        // lantern.target.x = camPos.x;
        // lantern.target.y = camPos.y;
        // lantern.target.z = camPos.z;

        // lantern.color.r = 128;

        writeln(lantern.brightness);

        UpdateLightValues(*ShaderHandler.getShaderPointer("main"), lantern);

        foreach (light; testLights) {
            UpdateLightValues(*ShaderHandler.getShaderPointer("main"), light);
        }

        // ShaderHandler.setUniformVec3d("main", lantern.positionLoc, CameraHandler.getPosition());

        // writeln(CameraHandler.getPosition());
        // ShaderHandler.setUniformVec3d("main", lantern.attenuationLoc, CameraHandler.getPosition());

    }

    void debugIt() {

        DrawSphere(lantern.position, 1.0, Colors.BLUE);

        DrawSphere(testLights[0].position, 1.0, Colors.RED);
        DrawSphere(testLights[1].position, 1.0, Colors.GREEN);
        DrawSphere(testLights[2].position, 1.0, Colors.BLUE);
        DrawSphere(testLights[3].position, 1.0, Colors.WHITE);

    }
}

struct Light {
    bool enabled = false;
    Vector3 position;
    Vector3 target;
    Color color;
    float brightness;

    // Shader locations
    int enabledLoc;
    int typeLoc;
    int positionLoc;
    int targetLoc;
    int colorLoc;
    int brightnessLoc;
}

// Light type
enum LightType {
    LIGHT_DIRECTIONAL = 0,
    LIGHT_POINT = 1
}

static int lightsCount = 0;

// Create a light and get shader locations
Light CreateLight(Vector3 position, Vector3 target, Color color, float brightness, Shader shader) {
    Light light = {0};

    if (lightsCount < MAX_LIGHTS) {
        light.enabled = true;
        light.position = position;
        light.target = target;
        light.color = color;
        light.brightness = brightness;

        // NOTE: Lighting shader naming must be the provided ones
        light.enabledLoc = GetShaderLocation(shader, TextFormat("lights[%i].enabled", lightsCount));
        light.typeLoc = GetShaderLocation(shader, TextFormat("lights[%i].type", lightsCount));
        light.positionLoc = GetShaderLocation(shader, TextFormat("lights[%i].position", lightsCount));
        light.targetLoc = GetShaderLocation(shader, TextFormat("lights[%i].target", lightsCount));
        light.colorLoc = GetShaderLocation(shader, TextFormat("lights[%i].color", lightsCount));
        light.brightnessLoc = GetShaderLocation(shader, TextFormat("lights[%i].brightness", lightsCount));

        UpdateLightValues(shader, light);

        lightsCount++;
    }

    return light;
}

// Send light properties to shader
// NOTE: Light shader locations should be available 
void UpdateLightValues(Shader shader, Light light) {

    // Send to shader light enabled state and type
    SetShaderValue(shader, light.enabledLoc, &light.enabled, ShaderUniformDataType
            .SHADER_UNIFORM_INT);

    // SetShaderValue(shader, light.typeLoc, &light.type, ShaderUniformDataType.SHADER_UNIFORM_INT);

    SetShaderValue(shader, light.brightnessLoc, &light.brightness, ShaderUniformDataType
            .SHADER_UNIFORM_FLOAT);

    // Send to shader light position values
    // float[3] position = [light.position.x, light.position.y, light.position.z];
    SetShaderValue(shader, light.positionLoc, &light.position, ShaderUniformDataType
            .SHADER_UNIFORM_VEC3);

    // Send to shader light target position values
    float[3] target = [light.target.x, light.target.y, light.target.z];
    SetShaderValue(shader, light.targetLoc, &target, ShaderUniformDataType.SHADER_UNIFORM_VEC3);

    // Send to shader light color values
    // Alpha is ignored.
    float[3] color = [
        cast(float) light.color.r / cast(float) 255,
        cast(float) light.color.g / cast(float) 255,
        cast(float) light.color.b / cast(float) 255
    ];
    SetShaderValue(shader, light.colorLoc, &color, ShaderUniformDataType.SHADER_UNIFORM_VEC3);
}
