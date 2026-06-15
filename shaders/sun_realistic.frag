#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

// Sun shader after Panteleymonov A. K. 2015 (Shadertoy "4dXGR4").
// Ported to Flutter and trimmed to the star only: the body, its corona ring
// and rays are kept; the original space/nebula background is removed so this
// composites over the app's own starfield. Empty space is made transparent by
// deriving alpha from luminance (premultiplied for Flutter's blend).
//
// Uniforms — set from Dart in this exact order:
//   0,1 -> uResolution.x, uResolution.y   (size of the box we draw into)
//   2   -> uTime                          (seconds)
uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

// --- procedural animated noise (4D) -----------------------------------------
vec4 hash4(vec4 n) { return fract(sin(n) * 1399763.5453123); }

float noise4q(vec4 x) {
    vec4 n3 = vec4(0, 0.25, 0.5, 0.75);
    vec4 p2 = floor(x.wwww + n3);
    vec4 b = floor(x.xxxx + n3) + floor(x.yyyy + n3) * 157.0 + floor(x.zzzz + n3) * 113.0;
    vec4 p1 = b + fract(p2 * 0.00390625) * vec4(164352.0, -164352.0, 163840.0, -163840.0);
    p2 = b + fract((p2 + 1.0) * 0.00390625) * vec4(164352.0, -164352.0, 163840.0, -163840.0);
    vec4 f1 = fract(x.xxxx + n3);
    vec4 f2 = fract(x.yyyy + n3);
    f1 = f1 * f1 * (3.0 - 2.0 * f1);
    f2 = f2 * f2 * (3.0 - 2.0 * f2);
    vec4 n1 = vec4(0, 1.0, 157.0, 158.0);
    vec4 n2 = vec4(113.0, 114.0, 270.0, 271.0);
    vec4 vs1 = mix(hash4(p1), hash4(n1.yyyy + p1), f1);
    vec4 vs2 = mix(hash4(n1.zzzz + p1), hash4(n1.wwww + p1), f1);
    vec4 vs3 = mix(hash4(p2), hash4(n1.yyyy + p2), f1);
    vec4 vs4 = mix(hash4(n1.zzzz + p2), hash4(n1.wwww + p2), f1);
    vs1 = mix(vs1, vs2, f2);
    vs3 = mix(vs3, vs4, f2);
    vs2 = mix(hash4(n2.xxxx + p1), hash4(n2.yyyy + p1), f1);
    vs4 = mix(hash4(n2.zzzz + p1), hash4(n2.wwww + p1), f1);
    vs2 = mix(vs2, vs4, f2);
    vs4 = mix(hash4(n2.xxxx + p2), hash4(n2.yyyy + p2), f1);
    vec4 vs5 = mix(hash4(n2.zzzz + p2), hash4(n2.wwww + p2), f1);
    vs4 = mix(vs4, vs5, f2);
    f1 = fract(x.zzzz + n3);
    f2 = fract(x.wwww + n3);
    f1 = f1 * f1 * (3.0 - 2.0 * f1);
    f2 = f2 * f2 * (3.0 - 2.0 * f2);
    vs1 = mix(vs1, vs2, f1);
    vs3 = mix(vs3, vs4, f1);
    vs1 = mix(vs1, vs3, f2);
    float r = dot(vs1, vec4(0.25));
    return r * r * (3.0 - 2.0 * r);
}

// body of the star: layered noise over the visible hemisphere
float noiseSpere(vec3 ray, vec3 pos, float r, mat3 mr, float zoom, vec3 subnoise, float anim) {
    float b = dot(ray, pos);
    float c = dot(pos, pos) - b * b;

    vec3 r1 = vec3(0.0);
    float s = 0.0;
    float d = 0.03125;
    float d2 = zoom / (d * d);
    float ar = 5.0;

    for (int i = 0; i < 3; i++) {
        float rq = r * r;
        if (c < rq) {
            float l1 = sqrt(rq - c);
            r1 = ray * (b - l1) - pos;
            r1 = r1 * mr;
            s += abs(noise4q(vec4(r1 * d2 + subnoise * ar, anim * ar)) * d);
        }
        ar -= 2.0;
        d *= 4.0;
        d2 *= 0.0625;
        r = r - r * 0.02;
    }
    return s;
}

// thin glow ring around the star's edge
float ring(vec3 ray, vec3 pos, float r, float size) {
    float b = dot(ray, pos);
    float c = dot(pos, pos) - b * b;
    return max(0.0, (1.0 - size * abs(r - sqrt(c))));
}

// flares / rays radiating from the star
float ringRayNoise(vec3 ray, vec3 pos, float r, float size, mat3 mr, float anim) {
    float b = dot(ray, pos);
    vec3 pr = ray * b - pos;
    float c = length(pr);

    pr *= mr;
    pr = normalize(pr);

    float s = max(0.0, (1.0 - size * abs(r - c)));

    float nd = noise4q(vec4(pr * 1.0, -anim + c)) * 2.0;
    nd = pow(nd, 2.0);
    float n = 0.4;
    float ns = 1.0;
    if (c > r) {
        n = noise4q(vec4(pr * 10.0, -anim + c));
        ns = noise4q(vec4(pr * 50.0, -anim * 2.5 + c * 2.0)) * 2.0;
    }
    n = n * n * nd * ns;

    return pow(s, 4.0) + s * s * n;
}

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 p = (-uResolution.xy + 2.0 * fragCoord.xy) / uResolution.y;

    float time = uTime;

    // Slow auto-rotation (the original used the mouse; we keep its no-mouse path).
    float mx = time * 0.025;
    float my = -0.6;
    vec2 rotate = vec2(mx, my);

    vec2 sins = sin(rotate);
    vec2 coss = cos(rotate);
    mat3 mr = mat3(vec3(coss.x, 0.0, sins.x), vec3(0.0, 1.0, 0.0), vec3(-sins.x, 0.0, coss.x));
    mr = mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, coss.y, sins.y), vec3(0.0, -sins.y, coss.y)) * mr;

    vec3 ray = normalize(vec3(p, 2.0));
    vec3 pos = vec3(0.0, 0.0, 3.0);

    // Star body: a hot yellow-white core broken up by two noise scales.
    float s1 = noiseSpere(ray, pos, 1.0, mr, 0.5, vec3(0.0), time);
    s1 = pow(min(1.0, s1 * 2.4), 2.0);
    float s2 = noiseSpere(ray, pos, 1.0, mr, 4.0, vec3(83.23, 34.34, 67.453), time);
    s2 = min(1.0, s2 * 2.2);
    fragColor = vec4(mix(vec3(1.0, 1.0, 0.0), vec3(1.0), pow(s1, 60.0)) * s1, 1.0);
    fragColor += vec4(mix(mix(vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 1.0), pow(s2, 2.0)), vec3(1.0), pow(s2, 10.0)) * s2, 1.0);

    // Dark rim just outside the surface.
    fragColor.xyz -= vec3(ring(ray, pos, 1.03, 11.0)) * 2.0;
    fragColor = max(vec4(0.0), fragColor);

    // Corona rays.
    float s3 = ringRayNoise(ray, pos, 0.96, 1.0, mr, time);
    fragColor.xyz += mix(vec3(1.0, 0.6, 0.1), vec3(1.0, 0.95, 1.0), pow(s3, 3.0)) * s3;

    fragColor = max(vec4(0.0), fragColor);
    fragColor = min(vec4(1.0), fragColor);

    // Isolate the sun: turn black space into transparency. Premultiply because
    // Flutter expects fragment-shader output in premultiplied alpha.
    float alpha = clamp(max(fragColor.r, max(fragColor.g, fragColor.b)), 0.0, 1.0);
    fragColor = vec4(fragColor.rgb * alpha, alpha);
}
