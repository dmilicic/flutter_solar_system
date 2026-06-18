#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

// Uniforms — MUST be set in this exact order from Dart via setFloat():
//   0,1 -> uResolution.x, uResolution.y
//   2   -> uTime
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

// --- Simple value noise -----------------------------------------------------
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f); // smoothstep interpolation
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion: stack a few octaves of noise for detail.
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p *= 2.0;          // double the frequency
        amplitude *= 0.5;  // halve the contribution
    }
    return value;
}

void main() {
    // Centered, normalized coordinates in roughly [-1, 1] with (0,0) at center.
    vec2 fragCoord = FlutterFragCoord();
    vec2 uv = (fragCoord - 0.5 * uResolution) / (0.5 * uResolution);

    float dist = length(uv);

    // Sample animated, domain-warped noise so the flames churn and rise.
    vec2 q = uv * 3.0;
    q.y += uTime * 0.6;        // scroll the field "upward" over time
    float n = fbm(q + fbm(q)); // feed fbm into itself for a swirly look

    // Brightness: hotter in the core, broken up by the noise.
    float fire = n + (1.0 - dist) * 1.2;
    fire *= smoothstep(1.0, 0.2, dist); // fade toward the rim

    // Fire palette: black -> deep red -> orange -> yellow -> white-hot.
    vec3 col = vec3(0.0);
    col = mix(col, vec3(0.6, 0.0, 0.0), smoothstep(0.0, 0.40, fire));
    col = mix(col, vec3(1.0, 0.4, 0.0), smoothstep(0.3, 0.70, fire));
    col = mix(col, vec3(1.0, 0.85, 0.2), smoothstep(0.6, 0.95, fire));
    col = mix(col, vec3(1.0, 1.0, 0.9), smoothstep(0.9, 1.30, fire));

    // Soft circular edge so it reads as a glowing sphere, not a square.
    float alpha = smoothstep(1.0, 0.75, dist);

    fragColor = vec4(col * alpha, alpha);
}
