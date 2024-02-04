import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../models/planet_data.dart';
import '../../providers/space_painter_provider.dart';

class PlanetPainter extends CustomPainter {

  final SpacePainterProvider provider;

  PlanetPainter(this.provider);

  final sunRadius = 100.0;
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

    // Create a Rect that represents the bounds of the sun
    final rect = Rect.fromCircle(center: sunPosition, radius: sunRadius);

    // Create the Shader from the gradient and the bounding square
    final shader = sunGradient.createShader(rect);

    // Set the Shader to the Paint
    sunPaint.shader = shader;

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
