#version 330

in vec2 fragTexCoord; 
in vec4 fragColor;

out vec4 finalColor;

uniform sampler2D texture0; 
uniform vec4 colDiffuse;
uniform float globalLightLevel;
uniform float torchFlicker;


// const int LIGHT_LEVEL_CHART[16] = int[16](
//     8, // 0
//     11, // 1
//     14, // 2
//     18, // 3
//     21, // 4
//     27, // 5
//     34, // 6
//     43, // 7
//     53, // 8
//     67, // 9
//     84, // 10
//     104, // 11
//     131, // 12
//     163, // 13
//     204, // 14
//     255 // 15
// );

// 1 ubyte above the threshold of 0.
// This is so caves do not flicker in pure darkness. (light level 0)
const float flickerThreshold = 9.0 / 255.0;

// This is the tint of the torch light.
// It is orange.
const vec3 torchLightColor = vec3(1.0, 0.64, 0.0);

void main() { 
    vec4 texelColor = texture(texture0, fragTexCoord);

    // Calculate global light level dimming here.

    // When this drops below 0.03 artificial light will take over even in pure darkness.
    float NATURAL_LIGHT = fragColor.x * globalLightLevel;

    float ARTIFICIAL_LIGHT = fragColor.y;

    if (NATURAL_LIGHT >= ARTIFICIAL_LIGHT) {
        texelColor.rgb *= NATURAL_LIGHT;
    } else {
        texelColor.rgb *= ARTIFICIAL_LIGHT;

        if (ARTIFICIAL_LIGHT > flickerThreshold) {
            texelColor.rgb = mix(texelColor.rgb, torchLightColor, torchFlicker);
        }
    }
    
    // texelColor.g *= fragColor.y;
    finalColor = texelColor * colDiffuse; 
} 