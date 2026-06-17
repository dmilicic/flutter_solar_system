# Solar System

An interactive solar system showcase built with Flutter. It renders an
animated star, orbiting planets, and roaming ships, with each celestial body
drawn by its own GLSL fragment shader for procedural surfaces and lighting.

## Highlights

- **Procedural star** — an animated sun rendered in real time with a fragment
  shader (corona, rays, and surface turbulence) compositing over the app's own
  starfield.
- **Per-type planet shaders** — lit-sphere shaders give each planet type
  (earth-like, gas giant, volcanic, …) a distinct procedural surface.
- **Ships** — named ships roam the system, with idle-ship culling to keep the
  scene lively.
- **Runs on web, macOS, and mobile**, with an HTML/CSS solar-system loader
  shown on the web build while the Flutter engine boots.

## Getting Started

```sh
flutter pub get
flutter run            # pick a device, or:
flutter run -d chrome  # run the web build
```

## Credits

- The realistic sun shader (`shaders/sun_realistic.frag`) is adapted from a
  sun effect by **Alexander Panteleymonov (Panteleymonov A. K.), 2015**,
  originally published on Shadertoy ([4dXGR4](https://www.shadertoy.com/view/4dXGR4)).
  It has been ported to Flutter's runtime effects and trimmed to render only
  the star so it composites over the app's starfield. All credit for the
  original effect goes to the author.
