#version 330

// Input vertex attributes (from vertex shader)
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

// NOTE: Add here your custom variables

#define     MAX_LIGHTS              128
#define     LIGHT_DIRECTIONAL       0
#define     LIGHT_POINT             1

struct Light {
    bool enabled;
    float brightness;
    vec3 position;
    vec3 color;
};

// Input lighting values
uniform Light lights[MAX_LIGHTS];
uniform vec3 ambient;
uniform vec3 viewPos;

void main()
{
    vec4 texelColor = texture(texture0, fragTexCoord);

    vec3 outputLight = vec3(0.0, 0.0, 0.0);

    if (fragNormal.x > 0) {
        discard;
    }

    // if (fragNormal.y > 0) {
    //     discard;
    // }

    // if (fragNormal.z > 0) {
    //     discard;
    // }

    if (isnan(fragNormal.x) || isinf(fragNormal.x) || isnan(fragNormal.y) || isinf(fragNormal.y) || isnan(fragNormal.z) || isinf(fragNormal.z)) {
        discard;
    }

    
    for (int i = 0; i < MAX_LIGHTS; i++){
        if (!lights[i].enabled) {
           continue; 
        }
        // vec3 norm = normalize(fragNormal);
        vec3 lightDir = normalize(lights[i].position - fragPosition);
        float diff = dot(fragNormal, lightDir);

        float dist = (lights[i].brightness - distance(lights[i].position, fragPosition)) / lights[i].brightness;
        dist = clamp(dist, 0.0, 1.0);

        outputLight += (lights[i].color * dist) * diff;
    }

    outputLight.x = clamp(outputLight.x, 0.0, 1.0);
    outputLight.y = clamp(outputLight.y, 0.0, 1.0);
    outputLight.z = clamp(outputLight.z, 0.0, 1.0);

    vec3 lightLevel = ambient + outputLight;

    lightLevel.x = clamp(lightLevel.x, 0.0, 1.0);
    lightLevel.y = clamp(lightLevel.y, 0.0, 1.0);
    lightLevel.z = clamp(lightLevel.z, 0.0, 1.0);
        
    vec3 result = lightLevel * vec3(texelColor);

    finalColor = vec4(result, texelColor.a);
}
