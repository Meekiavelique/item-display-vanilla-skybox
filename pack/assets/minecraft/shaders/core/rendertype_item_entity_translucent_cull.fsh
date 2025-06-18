#version 150

#moj_import <minecraft:fog.glsl>
// based on https://www.shadertoy.com/view/4tdSWr
uniform sampler2D Sampler0;
uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform float GameTime;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in vec2 texCoord1;
in vec3 vertexPosition;

out vec4 fragColor;

#define ALPHA_EFFECT(a) if(isTextureAlpha(a))

const float cloudscale = 1.1;
const float speed = 0.03;
const float clouddark = 0.5;
const float cloudlight = 0.3;
const float cloudcover = 0.2;
const float cloudalpha = 8.0;
const float skytint = 0.5;
const vec3 skycolour1 = vec3(0.2, 0.4, 0.6);
const vec3 skycolour2 = vec3(0.4, 0.7, 1.0);
const mat2 m = mat2(1.6, 1.2, -1.2, 1.6);

bool isTextureAlpha(float valueToExpected) {
    float epsilon = 1.0;
    float colorValue = texture(Sampler0, texCoord0).a * 255.0;
    return abs(colorValue - valueToExpected) < epsilon;
}

vec2 cloudHash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float cloudNoise(in vec2 p) {
    const float K1 = 0.366025404;
    const float K2 = 0.211324865;
    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    vec2 o = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;
    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 n = h * h * h * h * vec3(dot(a, cloudHash(i + 0.0)), dot(b, cloudHash(i + o)), dot(c, cloudHash(i + 1.0)));
    return dot(n, vec3(70.0));
}

float cloudFbm(vec2 n) {
    float total = 0.0, amplitude = 0.1;
    for (int i = 0; i < 7; i++) {
        total += cloudNoise(n) * amplitude;
        n = m * n;
        amplitude *= 0.4;
    }
    return total;
}

vec3 getMinecraftSkyWithClouds(vec3 rayDir) {
    vec2 uv = rayDir.xz / (abs(rayDir.y) + 0.2); 
    uv *= 0.3; 

    float time = GameTime * speed;
    float q = cloudFbm(uv * cloudscale * 0.5);
    
    float r = 0.0;
    vec2 cloudUV = uv * cloudscale;
    cloudUV -= q - time;
    float weight = 0.8;
    for (int i = 0; i < 6; i++) {
        r += abs(weight * cloudNoise(cloudUV));
        cloudUV = m * cloudUV + time;
        weight *= 0.7;
    }
    
    float f = 0.0;
    cloudUV = uv * cloudscale;
    cloudUV -= q - time;
    weight = 0.7;
    for (int i = 0; i < 6; i++) {
        f += weight * cloudNoise(cloudUV);
        cloudUV = m * cloudUV + time;
        weight *= 0.6;
    }
    
    f *= r + f;
    
    float c = 0.0;
    time = GameTime * speed * 2.0;
    cloudUV = uv * cloudscale * 2.0;
    cloudUV -= q - time;
    weight = 0.4;
    for (int i = 0; i < 5; i++) {
        c += weight * cloudNoise(cloudUV);
        cloudUV = m * cloudUV + time;
        weight *= 0.6;
    }
    
    float c1 = 0.0;
    time = GameTime * speed * 3.0;
    cloudUV = uv * cloudscale * 3.0;
    cloudUV -= q - time;
    weight = 0.4;
    for (int i = 0; i < 5; i++) {
        c1 += abs(weight * cloudNoise(cloudUV));
        cloudUV = m * cloudUV + time;
        weight *= 0.6;
    }
    
    c += c1;
    
    float verticalGradient = rayDir.y * 0.5 + 0.5;
    vec3 skycolour = mix(skycolour2, skycolour1, verticalGradient);
    vec3 cloudcolour = vec3(1.1, 1.1, 0.9) * clamp((clouddark + cloudlight * c), 0.0, 1.0);
    
    f = cloudcover + cloudalpha * f * r;
    

    float cloudMask = smoothstep(0.15, 0.5, rayDir.y); 
    f *= cloudMask;
    c *= cloudMask;
    c1 *= cloudMask;
    
    vec3 result = mix(skycolour, clamp(skytint * skycolour + cloudcolour, 0.0, 1.0), clamp(f + c, 0.0, 1.0));
    
    return result;
}

void main() {
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    
    ALPHA_EFFECT(254) {
        vec3 viewDir = normalize(vertexPosition);
        vec3 clouds = getMinecraftSkyWithClouds(viewDir);
        fragColor = vec4(clouds, 1.0);
        return;
    }
    
    if (color.a < 0.1) {
        discard;
    }
    
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}