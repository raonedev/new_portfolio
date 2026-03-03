#version 300 es
precision mediump float;

#define DEBUG_NORMALS 0

#include <flutter/runtime_effect.glsl>
#include "shared.glsl"
#include "sdf.glsl"

// Web-Compatible Uniforms (Removed layout(binding))
uniform vec2 uSize;
uniform vec4 uGlassColor;
uniform vec4 uOpticalProps;    // refractiveIndex, chromaticAberration, thickness, blend
uniform vec4 uLightConfig;     // angle, intensity, ambient, saturation
uniform vec2 uLightDirection;
uniform float uNumShapes;

// Array size must be constant. MAX_SHAPES is 16 in sdf.glsl (96 floats).
// However, GLSL ES arrays must have a constant size defined explicitly or via const.
#define ARRAY_SIZE 96 
uniform float uShapeData[ARRAY_SIZE];

uniform sampler2D uBlurredTexture;

out vec4 fragColor;

// Extract individual values
float uChromaticAberration = uOpticalProps.y;
float uLightIntensity = uLightConfig.y;
float uAmbientStrength = uLightConfig.z;
float uThickness = uOpticalProps.z;
float uRefractiveIndex = uOpticalProps.x;
float uBlend = uOpticalProps.w;
float uSaturation = uLightConfig.w;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
     
    #ifdef IMPELLER_TARGET_OPENGLES
        vec2 screenUV = vec2(fragCoord.x / uSize.x, 1.0 - (fragCoord.y / uSize.y));
    #else
        vec2 screenUV = vec2(fragCoord.x / uSize.x, fragCoord.y / uSize.y);
    #endif
    
    // Pass the array to the SDF function found in sdf.glsl
    float sd = sceneSDF(fragCoord, int(uNumShapes), uShapeData, uBlend);
    float foregroundAlpha = 1.0 - smoothstep(-2.0, 0.0, sd);

    if (foregroundAlpha < 0.01) {
        fragColor = texture(uBlurredTexture, screenUV);
        return;
    }

    vec3 normal = getNormal(sd, uThickness);
    
    fragColor = renderLiquidGlass(
        screenUV, 
        fragCoord, 
        uSize, 
        sd, 
        uThickness, 
        uRefractiveIndex, 
        uChromaticAberration, 
        uGlassColor, 
        uLightDirection, 
        uLightIntensity, 
        uAmbientStrength, 
        uBlurredTexture, 
        normal,
        foregroundAlpha,
        0.0,
        uSaturation
    );
    
    #if DEBUG_NORMALS
        fragColor = debugNormals(fragColor, normal, true);
    #endif
}