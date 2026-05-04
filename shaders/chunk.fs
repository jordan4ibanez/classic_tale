#version 330

in vec2 fragTexCoord; 
in vec4 fragColor;

out vec4 finalColor;

uniform sampler2D texture0; 
uniform vec4 colDiffuse;
uniform float globalLightLevel;


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



void main() { 
    vec4 texelColor = texture(texture0, fragTexCoord);

    // Calculate global light level dimming here.

    float NATURAL_LIGHT = fragColor.x * globalLightLevel;


    if (NATURAL_LIGHT >= fragColor.y) {
        texelColor.rgb *= NATURAL_LIGHT;
    } else {
        texelColor.rgb *= fragColor.y;
    }
    
    

    // texelColor.g *= fragColor.y;
    finalColor = texelColor * colDiffuse; 
} 