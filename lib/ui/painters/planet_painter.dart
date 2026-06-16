import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../models/planet_data.dart';
import '../../providers/space_painter_provider.dart';

class PlanetPainter extends CustomPainter {

  final SpacePainterProvider provider;

  PlanetPainter(this.provider);

  final sunRadius = 80.0;
  final sunGradient = const RadialGradient(
    center: Alignment(0.0, 0.0),
    radius: 0.5, // covers the full circle
    colors: <Color>[
      Color(0xFFfee66f),
      Color(0xFFf69600),
    ],
    stops: <double>[0.0, 1.0], // defines the position of the colors
  );

  @override
  void paint(Canvas canvas, Size size) {

    drawSun(canvas, size);

    for (var planet in planets) {
      drawOrbit(canvas, size, orbitRadius: planet.distance);
      drawPlanet(canvas, size, planet);
    }
  }

  void drawPlanet(Canvas canvas, Size size, PlanetData planet) {
    final sunPosition = Offset(
      size.width / 2,
      size.height / 2,
    );

    final planetPaint = provider.planetPainter..color = planet.color;
    final planetAngle = planet.angle;

    // Calculate the position of the planet on the orbital path
    final planetPosition = Offset(
      sunPosition.dx + planet.distance * cos(planetAngle),
      sunPosition.dy + planet.distance * sin(planetAngle),
    );

    final planetShader = provider.planetShaders[planet.type];
    if (planetShader != null) {
      // Render the planet as a sun-lit sphere via its type-specific shader.
      final box = planet.radius * 2;

      // Uniforms must be set in the order declared in planet.frag.
      planetShader.setFloat(0, box); // uResolution.x
      planetShader.setFloat(1, box); // uResolution.y
      planetShader.setFloat(2, provider.time); // uTime
      // Direction from the planet toward the sun in screen space (unit length).
      planetShader.setFloat(3, -cos(planetAngle)); // uLightDir.x
      planetShader.setFloat(4, -sin(planetAngle)); // uLightDir.y
      planetShader.setFloat(5, planet.color.r); // uColor.r
      planetShader.setFloat(6, planet.color.g); // uColor.g
      planetShader.setFloat(7, planet.color.b); // uColor.b
      planetShader.setFloat(8, planet.distance / 100.0); // uSeed (distinct per planet)

      canvas.save();
      canvas.translate(planetPosition.dx - planet.radius, planetPosition.dy - planet.radius);
      canvas.drawRect(Rect.fromLTWH(0, 0, box, box), Paint()..shader = planetShader);
      canvas.restore();

      planet.angle += planet.revolutionSpeed;
      return;
    }

    final alignment = Alignment(
      cos(planetAngle) * planet.distance / (size.width / 2) * -1,
      sin(planetAngle) * planet.distance / (size.height / 2) * -1,
    );

    // Define the gradient
    final gradient = RadialGradient(
      center: alignment,
      radius: 0.5, // covers the full circle
      colors: <Color>[
        planet.color,
        darken(planet.color),
      ],
      stops: const <double>[0.0, 1.0], // defines the position of the colors
    );

    // Create a Rect that represents the bounds of the circle
    final rect = Rect.fromCircle(center: planetPosition, radius: planet.radius);

    // Create the Shader from the gradient and the bounding square
    final shader = gradient.createShader(rect);

    // Set the Shader to the Paint
    planetPaint.shader = shader;

    // Draw the planet
    canvas.drawCircle(planetPosition, planet.radius, planetPaint);

    // Update the angle for the next frame
    planet.angle += planet.revolutionSpeed; // adjust this value to change the speed of the planet
  }

  void drawOrbit(Canvas canvas, Size size, {double orbitRadius = 400.0}) {
    final sunPosition = Offset(
      size.width / 2,
      size.height / 2,
    );
    final orbitalPath = Path();
    orbitalPath.addOval(Rect.fromCircle(center: sunPosition, radius: orbitRadius));
    canvas.drawPath(orbitalPath, provider.provideOrbitalPathPaint());
  }

  void drawSun(Canvas canvas, Size size) {
    final sunPosition = Offset(
      size.width / 2,
      size.height / 2,
    );

    final sunPaint = provider.provideSunPaint();
    final fireShader = provider.sunShader;

    if (fireShader != null) {
      // Animated GLSL sun shader. The star's corona and rays extend well beyond
      // the body, so we render into a square box larger than the sun and let the
      // shader's luminance-based alpha keep the empty corners transparent.
      // (In this shader the bright body fills ~0.71 of the box height, so a box
      // of ~2.8x the radius reproduces the old sun size; 4x leaves room for rays.)
      const coronaScale = 4.0;
      final box = sunRadius * coronaScale;

      // Uniforms must be set in the same order they're declared in the shader.
      fireShader.setFloat(0, box); // uResolution.x
      fireShader.setFloat(1, box); // uResolution.y
      fireShader.setFloat(2, provider.time); // uTime

      sunPaint.shader = fireShader;

      canvas.save();
      canvas.translate(sunPosition.dx - box / 2, sunPosition.dy - box / 2);
      canvas.drawRect(Rect.fromLTWH(0, 0, box, box), sunPaint);
      canvas.restore();
      return;
    }

    // Fallback: plain radial gradient until the shader program finishes loading.
    final rect = Rect.fromCircle(center: sunPosition, radius: sunRadius);
    sunPaint.shader = sunGradient.createShader(rect);
    canvas.drawCircle(sunPosition, sunRadius, sunPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  Color darken(Color color, [double amount = .5]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }
}
