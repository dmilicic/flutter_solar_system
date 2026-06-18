#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

// Jupiter-like gas giant: turbulent horizontal bands in a cream/tan/brown
// palette plus a great-red-spot storm. Lit from the sun's screen direction.
// Shared uniform layout:
//   0,1 uResolution | 2 uTime | 3,4 uLightDir | 5,6,7 uColor | 8 uSeed
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uLightDir;
uniform vec3 uColor; // unused here; kept for a common layout
uniform float uSeed;

out vec4 fragColor;

float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
                   mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
               mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
                   mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.0; a *= 0.5; }
    return v;
}

vec3 rotY(vec3 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return vec3(c * p.x + s * p.z, p.y, -s * p.x + c * p.z);
}

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 uv = (2.0 * fragCoord - uResolution) / uResolution.y;
    float d = length(uv);
    float z = sqrt(max(0.0, 1.0 - d * d));
    vec3 normal = vec3(uv, z);

    vec3 sp = rotY(normal, uTime * 0.06 + uSeed);

    // Latitude bands wavered by turbulence (domain warp).
    float warp = fbm(sp * 3.0 + uSeed * 5.0);
    float t = 0.5 + 0.5 * sin(sp.y * 8.0 + warp * 2.5);

    vec3 cream = vec3(0.85, 0.75, 0.55);
    vec3 tan = vec3(0.75, 0.55, 0.35);
    vec3 brown = vec3(0.55, 0.32, 0.18);
    vec3 surf = mix(cream, tan, t);
    surf = mix(surf, brown, smoothstep(0.6, 1.0, t) * 0.6);

    // Fine swirling detail.
    float det = fbm(sp * 8.0 + uSeed * 9.0);
    surf *= 0.8 + 0.4 * det;

    // Great red spot, fixed in surface space so it rotates with the planet.
    vec3 spotCenter = normalize(vec3(0.6, -0.3, 0.7));
    float spot = smoothstep(0.32, 0.0, distance(sp, spotCenter));
    surf = mix(surf, vec3(0.70, 0.22, 0.12), spot * 0.85);

    vec3 lightDir = normalize(vec3(uLightDir, 0.35));
    float diff = max(dot(normal, lightDir), 0.0);
    float light = 0.07 + 0.93 * smoothstep(0.0, 0.25, diff) * diff;
    vec3 col = surf * light;

    float rim = pow(1.0 - z, 3.0) * smoothstep(0.0, 0.4, diff);
    col += vec3(0.9, 0.7, 0.4) * rim * 0.4;

    float alpha = smoothstep(1.0, 0.985, d);
    fragColor = vec4(col * alpha, alpha);
}
