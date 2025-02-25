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

#define     MAX_LIGHTS              1
#define     LIGHT_DIRECTIONAL       0
#define     LIGHT_POINT             1

struct Light {
    int enabled;
    int type;
    vec3 position;
    vec3 target;
    vec4 color;
};

// Input lighting values
uniform Light lights[MAX_LIGHTS];
uniform vec4 ambient;
uniform vec3 viewPos;

void main()
{
    vec4 texelColor = texture(texture0, fragTexCoord);

  	
    // diffuse 
    // vec3 norm = normalize(fragNormal);
    // vec3 lightDir = normalize(lights[0].position - fragPosition);
    // float diff = max(dot(norm, lightDir), 0.0);

    float brightness = 5.0;

    float dist = (brightness - distance(lights[0].position, fragPosition)) / brightness;
    vec3 outputLight = vec3(lights[0].color) * dist;

    // vec3 diffuse = diff * vec3(lights[0].color);

    
    
    // specular
    // float specularStrength = 0.5;
    // vec3 viewDir = normalize(viewPos - fragPosition);
    // vec3 reflectDir = reflect(-lightDir, norm);  
    // float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    // vec3 specular = specularStrength * spec * vec3(lights[0].color);


    vec3 lightLevel = vec3(ambient.x, ambient.y, ambient.z) + outputLight;
    lightLevel.x = clamp(lightLevel.x, 0.0, 1.0);
    lightLevel.y = clamp(lightLevel.y, 0.0, 1.0);
    lightLevel.z = clamp(lightLevel.z, 0.0, 1.0);

        
    vec3 result = lightLevel * vec3(texelColor);

    finalColor = vec4(result, 1.0);
}
