#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

// Earth-like planet: oceans, noise-driven continents, polar ice caps and a
// separately-rotating cloud layer, lit from the sun's screen direction.
// Shared uniform layout with the other planet shaders:
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

    vec3 sp = rotY(normal, uTime * 0.08 + uSeed);

    // Continents vs. ocean.
    float landN = fbm(sp * 2.2 + uSeed * 7.0);
    float land = smoothstep(0.52, 0.58, landN);
    vec3 oceanCol = mix(vec3(0.04, 0.20, 0.50), vec3(0.10, 0.45, 0.65), smoothstep(0.45, 0.52, landN));
    vec3 landCol = mix(vec3(0.18, 0.42, 0.14), vec3(0.45, 0.35, 0.18), smoothstep(0.60, 0.75, landN));
    vec3 surf = mix(oceanCol, landCol, land);

    // Polar ice caps.
    float ice = smoothstep(0.78, 0.88, abs(sp.y));
    surf = mix(surf, vec3(0.90, 0.95, 1.0), ice);

    // Clouds drift a little faster than the surface.
    vec3 cp = rotY(normal, uTime * 0.14 + uSeed);
    float clouds = smoothstep(0.55, 0.75, fbm(cp * 3.0 + vec3(uTime * 0.02)));
    surf = mix(surf, vec3(1.0), clouds * 0.85);

    vec3 lightDir = normalize(vec3(uLightDir, 0.35));
    float diff = max(dot(normal, lightDir), 0.0);
    float light = 0.06 + 0.94 * smoothstep(0.0, 0.25, diff) * diff;
    vec3 col = surf * light;

    // Bluish atmospheric rim on the lit limb.
    float rim = pow(1.0 - z, 3.0) * smoothstep(0.0, 0.4, diff);
    col += vec3(0.3, 0.5, 1.0) * rim * 0.6;

    float alpha = smoothstep(1.0, 0.985, d);
    fragColor = vec4(col * alpha, alpha);
}
