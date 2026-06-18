#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

// Volcanic planet: dark basalt rock veined with glowing, pulsing lava seams.
// The rock is lit by the sun; the lava is emissive so it glows on the dark
// side too. Shared uniform layout:
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

    vec3 sp = rotY(normal, uTime * 0.05 + uSeed);

    // Charred rock surface.
    float rockN = fbm(sp * 3.5 + uSeed * 4.0);
    vec3 rock = mix(vec3(0.12, 0.09, 0.08), vec3(0.32, 0.26, 0.22), rockN);

    // Lava seams: thin glowing cracks where the noise field crosses a level.
    float lavaN = fbm(sp * 4.0 + uSeed * 11.0);
    float seam = 1.0 - smoothstep(0.0, 0.09, abs(lavaN - 0.5));
    float pulse = 0.6 + 0.4 * sin(uTime * 2.0 + lavaN * 10.0);
    vec3 lava = mix(vec3(1.0, 0.30, 0.0), vec3(1.0, 0.90, 0.30), seam);

    vec3 lightDir = normalize(vec3(uLightDir, 0.35));
    float diff = max(dot(normal, lightDir), 0.0);
    float light = 0.05 + 0.95 * smoothstep(0.0, 0.25, diff) * diff;

    vec3 col = rock * light;                 // lit rock
    col += lava * seam * pulse * 1.6;        // emissive lava (glows in shadow too)

    // Hot reddish rim glow all around.
    float rim = pow(1.0 - z, 3.0);
    col += vec3(0.8, 0.2, 0.0) * rim * 0.35;

    float alpha = smoothstep(1.0, 0.985, d);
    fragColor = vec4(col * alpha, alpha);
}
