// Copyright 2025, Tim Lehmann for whynotmake.it
//
// Consolidated Liquid Glass Shader for Flutter Web.
// Merges: liquid_glass_filter.frag, sdf.glsl, shared.glsl
// 
// Features:
// - Real-time SDF-based geometry calculation
// - Refraction, Chromatic Aberration, and Lighting
// - Interactive via Uniforms (Shape data, light, colors)

#version 320 es
precision highp float;

#include <flutter/runtime_effect.glsl>

// --- Constants ---
#define MAX_SHAPES 16
const vec3 LUMA_WEIGHTS = vec3(0.299, 0.587, 0.114);

// --- Uniforms ---
// Grouped for performance (vec4 where possible)

layout(location = 0) uniform vec2 uSize;                    // Screen/Canvas size
layout(location = 1) uniform vec4 uGlassColor;             // r, g, b, a
layout(location = 2) uniform vec4 uOpticalProps;           // refractiveIndex, chromaticAberration, thickness, blend
layout(location = 3) uniform vec4 uLightConfig;            // angle, intensity, ambient, saturation
layout(location = 4) uniform vec2 uLightDirection;         // pre-computed cos(angle), sin(angle)

layout(location = 5) uniform float uNumShapes;             // Number of active shapes
//layout(location = 6) uniform float uShapeData[MAX_SHAPES * 6]; // Shape definitions
layout(location = 6) uniform float uShapeData[96];

uniform sampler2D uBlurredTexture; // Background texture (snapshot of widgets behind this layer)

layout(location = 0) out vec4 fragColor;

// --- Extracted Values for Readability ---
float uChromaticAberration = uOpticalProps.y;
float uLightIntensity = uLightConfig.y;
float uAmbientStrength = uLightConfig.z;
float uThickness = uOpticalProps.z;
float uRefractiveIndex = uOpticalProps.x;
float uBlend = uOpticalProps.w;
float uSaturation = uLightConfig.w;

// --------------------------------------------------------------------------------
// SDF Functions (from sdf.glsl)
// --------------------------------------------------------------------------------

float sdfRRect(in vec2 p, in vec2 b, in float r) {
    float shortest = min(b.x, b.y);
    r = min(r, shortest);
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

float sdfSquircle(vec2 p, vec2 b, float r) {
    float shortest = min(b.x, b.y);
    r = min(r, shortest);
    vec2 q = abs(p) - b + r;
    vec2 maxQ = max(q, 0.0);
    return min(max(q.x, q.y), 0.0) + sqrt(maxQ.x * maxQ.x + maxQ.y * maxQ.y) - r;
}

float sdfEllipse(vec2 p, vec2 r) {
    r = max(r, 1e-4);
    vec2 invR = 1.0 / r;
    vec2 invR2 = invR * invR;
    vec2 pInvR = p * invR;
    float k1 = length(pInvR);
    vec2 pInvR2 = p * invR2;
    float k2 = length(pInvR2);
    return (k1 * (k1 - 1.0)) / max(k2, 1e-4);
}

float smoothUnion(float d1, float d2, float k) {
    if (k <= 0.0) return min(d1, d2);
    float e = max(k - abs(d1 - d2), 0.0);
    return min(d1, d2) - e * e * 0.25 / k;
}

float getShapeSDF(float type, vec2 p, vec2 center, vec2 size, float r) {
    if (type == 1.0) return sdfSquircle(p - center, size / 2.0, r);
    if (type == 2.0) return sdfEllipse(p - center, size / 2.0);
    if (type == 3.0) return sdfRRect(p - center, size / 2.0, r);
    return 1e9; // none
}

float getShapeSDFFromArray(int index, vec2 p, float shapeData[MAX_SHAPES * 6]) {
    int baseIndex = index * 6;
    float type = shapeData[baseIndex];
    vec2 center = vec2(shapeData[baseIndex + 1], shapeData[baseIndex + 2]);
    vec2 size = vec2(shapeData[baseIndex + 3], shapeData[baseIndex + 4]);
    float cornerRadius = shapeData[baseIndex + 5];
    return getShapeSDF(type, p, center, size, cornerRadius);
}

float sceneSDF(vec2 p, int numShapes, float shapeData[MAX_SHAPES * 6], float blend) {
    if (numShapes == 0) return 1e9;
    
    float result = getShapeSDFFromArray(0, p, shapeData);
    
    // Unroll for common cases
    if (numShapes >= 2) result = smoothUnion(result, getShapeSDFFromArray(1, p, shapeData), blend);
    if (numShapes >= 3) result = smoothUnion(result, getShapeSDFFromArray(2, p, shapeData), blend);
    if (numShapes >= 4) result = smoothUnion(result, getShapeSDFFromArray(3, p, shapeData), blend);
    
    // Loop for rest
    for (int i = 4; i < min(numShapes, MAX_SHAPES); i++) {
        result = smoothUnion(result, getShapeSDFFromArray(i, p, shapeData), blend);
    }
    
    return result;
}

// Calculate 3D normal using derivatives
vec3 getNormal(float sd, float thickness) {
    float dx = dFdx(sd);
    float dy = dFdy(sd);
    
    float n_cos = max(thickness + sd, 0.0) / thickness;
    float n_sin = sqrt(max(0.0, 1.0 - n_cos * n_cos));
    
    return normalize(vec3(dx * n_cos, dy * n_cos, n_sin));
}

// --------------------------------------------------------------------------------
// Shared Rendering Functions (from shared.glsl)
// --------------------------------------------------------------------------------

// Optimized highlight color calculation
vec3 getHighlightColor(vec3 backgroundColor, float targetBrightness) {
    float luminance = dot(backgroundColor, LUMA_WEIGHTS);
    float maxComponent = max(max(backgroundColor.r, backgroundColor.g), backgroundColor.b);
    
    float lum = luminance * 2.5;
    float lumFactor = lum / (1.0 + lum);
    float sat = maxComponent * 2.5;
    float satFactor = sat / (1.0 + sat);
    
    float colorInfluence = lumFactor * satFactor;
    vec3 tinted = (backgroundColor / max(luminance, 0.001)) * targetBrightness;
    
    return mix(vec3(targetBrightness), tinted, colorInfluence);
}

float getHeight(float sd, float thickness) {
    if (sd >= 0.0 || thickness <= 0.0) return 0.0;
    if (sd < -thickness) return thickness;
    
    float x = thickness + sd;
    return sqrt(max(0.0, thickness * thickness - x * x));
}

vec3 calculateLighting(
    vec2 uv, 
    vec3 normal, 
    float sd, 
    float thickness, 
    float height,
    vec2 lightDirection, 
    float lightIntensity, 
    float ambientStrength, 
    vec3 backgroundColor
) {
    float normalizedHeight = thickness > 0.0 ? height / thickness : 0.0;
    float shape = clamp((1.0 - normalizedHeight) * 1.111, 0.0, 1.0);
    if (shape < 0.01) return vec3(0.0);

    float thicknessFactor = clamp((thickness - 5.0) * 0.5, 0.0, 1.0);
    if (thicknessFactor < 0.01) return vec3(0.0);

    float rimWidth = 1.5;
    float k = 0.89;
    float x = sd / rimWidth;
    float rimFactor = 1.0 / (1.0 + k * x * x);

    if (rimFactor < 0.01 || lightIntensity < 0.01) return vec3(0.0);

    vec2 normalXY = normal.xy;
    float mainLightInfluence = max(0.0, dot(normalXY, lightDirection));
    float oppositeLightInfluence = max(0.0, dot(normalXY, -lightDirection));
    float totalInfluence = mainLightInfluence + oppositeLightInfluence * 0.8;

    vec3 highlightColor = getHighlightColor(backgroundColor, 1.0);
    vec3 directionalRim = (highlightColor * 0.7) * (totalInfluence * totalInfluence) * lightIntensity * 2.0;
    vec3 ambientRim = (highlightColor * 0.4) * ambientStrength;
    vec3 totalRimLight = (directionalRim + ambientRim) * rimFactor;

    return totalRimLight * thicknessFactor * shape;
}

// Refraction with Chromatic Aberration
vec4 calculateRefraction(
    vec2 screenUV, 
    vec3 normal, 
    float height, 
    float thickness, 
    float refractiveIndex, 
    float chromaticAberration, 
    vec2 uSize, 
    sampler2D backgroundTexture, 
    out vec2 refractionDisplacement
) {
    float baseHeight = thickness * 8.0;
    vec3 incident = vec3(0.0, 0.0, -1.0);
    
    float invRefractiveIndex = 1.0 / refractiveIndex;
    vec2 invUSize = 1.0 / uSize;
    
    vec3 baseRefract = refract(incident, normal, invRefractiveIndex);
    float baseRefractLength = (height + baseHeight) / max(0.001, abs(baseRefract.z));
    vec2 baseDisplacement = baseRefract.xy * baseRefractLength;
    refractionDisplacement = baseDisplacement;
    
    if (chromaticAberration < 0.001) {
        return texture(backgroundTexture, screenUV + baseDisplacement * invUSize);
    }
    
    float dispersionStrength = chromaticAberration * 0.5;
    vec2 redOffset = baseDisplacement * (1.0 + dispersionStrength);
    vec2 blueOffset = baseDisplacement * (1.0 - dispersionStrength);

    float red = texture(backgroundTexture, screenUV + redOffset * invUSize).r;
    vec4 greenSample = texture(backgroundTexture, screenUV + baseDisplacement * invUSize);
    float blue = texture(backgroundTexture, screenUV + blueOffset * invUSize).b;

    return vec4(red, greenSample.g, blue, greenSample.a);
}

vec3 applySaturation(vec3 color, float saturation) {
    float luminance = dot(color, LUMA_WEIGHTS);
    return clamp(mix(vec3(luminance), color, saturation), 0.0, 1.0);
}

vec4 applyGlassColor(vec4 liquidColor, vec4 glassColor) {
    vec4 finalColor = liquidColor;
    if (glassColor.a > 0.0) {
        float glassLuminance = dot(glassColor.rgb, LUMA_WEIGHTS);
        
        if (glassLuminance < 0.5) {
            vec3 darkened = liquidColor.rgb * (glassColor.rgb * 2.0);
            finalColor.rgb = mix(liquidColor.rgb, darkened, glassColor.a);
        } else {
            vec3 invLiquid = vec3(1.0) - liquidColor.rgb;
            vec3 invGlass = vec3(1.0) - glassColor.rgb;
            vec3 screened = vec3(1.0) - (invLiquid * invGlass);
            finalColor.rgb = mix(liquidColor.rgb, screened, glassColor.a);
        }
    }
    return finalColor;
}

vec4 renderLiquidGlass(
    vec2 screenUV, 
    vec2 p, 
    vec2 uSize, 
    float sd, 
    float thickness, 
    float refractiveIndex, 
    float chromaticAberration, 
    vec4 glassColor, 
    vec2 lightDirection, 
    float lightIntensity, 
    float ambientStrength, 
    sampler2D backgroundTexture, 
    vec3 normal, 
    float foregroundAlpha, 
    float saturation
) {
    float height = getHeight(sd, thickness);
    
    vec2 refractionDisplacement;
    vec4 refractColor = calculateRefraction(
        screenUV, normal, height, thickness, refractiveIndex, chromaticAberration, 
        uSize, backgroundTexture, refractionDisplacement
    );
    
    vec3 backgroundColor = refractColor.rgb;
    vec3 lighting = calculateLighting(
        screenUV, normal, sd, thickness, height, lightDirection, 
        lightIntensity, ambientStrength, backgroundColor
    );
    
    vec4 finalColor = applyGlassColor(refractColor, glassColor);
    finalColor.rgb += lighting;
    finalColor.rgb = applySaturation(finalColor.rgb, saturation);
    
    return mix(vec4(0.0), finalColor, foregroundAlpha);
}

// --------------------------------------------------------------------------------
// Main Entry Point
// --------------------------------------------------------------------------------

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
     
    // We invert screenUV Y on OpenGL (Flutter Web/Impeller) to sample correctly
    #ifdef IMPELLER_TARGET_OPENGLES
        vec2 screenUV = vec2(fragCoord.x / uSize.x, 1.0 - (fragCoord.y / uSize.y));
    #else
        vec2 screenUV = vec2(fragCoord.x / uSize.x, fragCoord.y / uSize.y);
    #endif
    
    // Calculate SDF for the scene
    float sd = sceneSDF(fragCoord, int(uNumShapes), uShapeData, uBlend);
    
    // Calculate alpha based on distance to edge
    float foregroundAlpha = 1.0 - smoothstep(-2.0, 0.0, sd);

    // Early discard for pixels outside glass shapes to save performance
    if (foregroundAlpha < 0.01) {
        fragColor = vec4(0, 0, 0, 0);
        return;
    }

    // Calculate surface normal
    vec3 normal = getNormal(sd, uThickness);
    
    // Render the liquid glass effect
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
        uSaturation
    );
}