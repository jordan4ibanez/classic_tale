module graphics.shader_handler;

import raylib;
import std.string;

static final const class ShaderHandler {
static:
private:

    Shader*[string] database;

    //* BEGIN PUBLIC API.

    public void newShader(string shaderName, string vertCodeLocation, string fragCodeLocation) {

        if (shaderName in database) {
            throw new Error("[ShaderHandler]: Tried to overwrite shader " ~ shaderName);
        }

        Shader* thisShader = new Shader();
        *thisShader = LoadShader(toStringz(vertCodeLocation), toStringz(fragCodeLocation));

        if (!IsShaderValid(*thisShader)) {
            throw new Error("[ShaderHandler]: Invalid shader. " ~ shaderName);
        }

        database[shaderName] = thisShader;
    }

    public int getUniformLocation(string shaderName, string uniformName) {
        if (shaderName !in database) {
            throw new Error(
                "[ShaderHandler]: Tried to get non-existent shader. " ~ shaderName);
        }

        int val = GetShaderLocation(*database[shaderName], toStringz(uniformName));

        if (val == -1) {
            throw new Error(
                "[ShaderHandler]: Uniform " ~ uniformName ~ " does not exist for shader. " ~ shaderName);
        }

        return val;
    }

    public Shader* getShaderPointer(string shaderName) {
        if (shaderName !in database) {
            throw new Error(
                "[ShaderHandler]: Tried to get non-existent shader pointer. " ~ shaderName);
        }
        return database[shaderName];
    }

    public void setFloatUniformFloat(string shaderName, int location, float value) {
        if (shaderName !in database) {
            throw new Error(
                "[ShaderHandler]: Tried to set uniform in non-existent shader. " ~ shaderName);
        }

        SetShaderValue(*database[shaderName], location, &value,
            ShaderUniformDataType.SHADER_UNIFORM_FLOAT);
    }

    public void terminate() {
        foreach (shaderName, thisShader; database) {
            UnloadShader(*thisShader);
        }

        database.clear();
    }

    //* BEGIN INTERNAL API.
}
