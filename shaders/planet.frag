#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

// Per-planet shader: renders a flat disc as a lit sphere. The surface is
// textured with animated 3D noise (banding + blotches) tinted by the planet's
// base colour, and lit from the sun's actual screen direction so the side
// facing the sun is bright and the far side falls into shadow (a real
// day/night terminator). Empty space outside the disc is transparent so it
// composites over the orbit lines and starfield.
//
// Uniforms — set from Dart in this exact order:
//   0,1 -> uResolution.x, uResolution.y   (box size; the sphere fills it)
//   2   -> uTime                          (seconds; spins the surface)
//   3,4 -> uLightDir.x, uLightDir.y       (planet -> sun, screen space, y down)
//   5,6,7 -> uColor.r, uColor.g, uColor.b (base colour, 0..1)
//   8   -> uSeed                          (per-planet variation)
uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uLightDir;
uniform vec3 uColor;
uniform float uSeed;

out vec4 fragColor;

// --- 3D value noise ---------------------------------------------------------
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
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 fragCoord = FlutterFragCoord();
    // Normalized coords: the sphere of radius 1 exactly fills the box height.
    vec2 uv = (2.0 * fragCoord - uResolution) / uResolution.y;
    float d = length(uv);

    // Reconstruct the sphere surface normal (z toward the viewer).
    float z = sqrt(max(0.0, 1.0 - d * d));
    vec3 normal = vec3(uv, z);

    // Spin the surface around the vertical axis over time.
    float ang = uTime * 0.1 + uSeed;
    float c = cos(ang);
    float s = sin(ang);
    vec3 sp = vec3(c * normal.x + s * normal.z, normal.y, -s * normal.x + c * normal.z);

    // Surface detail: fbm blotches blended with horizontal bands.
    float n = fbm(sp * 2.5 + uSeed * 13.0);
    float bands = 0.5 + 0.5 * sin(sp.y * 6.0 + n * 4.0);
    float detail = mix(n, bands, 0.4);

    vec3 col = uColor * (0.6 + 0.6 * detail);

    // Sun lighting. uLightDir points toward the sun in screen space; give it a
    // little +z so the terminator sits naturally on the visible hemisphere.
    vec3 lightDir = normalize(vec3(uLightDir, 0.35));
    float diff = max(dot(normal, lightDir), 0.0);
    float light = 0.08 + 0.92 * smoothstep(0.0, 0.25, diff) * diff; // ambient + soft terminator
    col *= light;

    // Subtle bright rim on the lit limb (cheap atmosphere hint).
    float rim = pow(1.0 - z, 3.0) * smoothstep(0.0, 0.4, diff);
    col += uColor * rim * 0.5;

    // Anti-aliased circular edge; premultiplied alpha for Flutter.
    float alpha = smoothstep(1.0, 0.985, d);
    fragColor = vec4(col * alpha, alpha);
}
