import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SpacePainter extends CustomPainter {

  SpacePainter();

  final int starCount = 300;
  final _random = Random();

  final _paint = Paint()
    ..color = const Color(0xFF000000)
    ..style = PaintingStyle.fill;

  final _distantStarPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.fill;

  final _sunPaint = Paint()
    ..color = const Color(0xFFfee66f)
    ..style = PaintingStyle.fill;

  final _orbitalPathPaint = Paint()
    ..color = const Color(0xFFaabdd6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  final sunRayPaint = Paint()
    ..color = const Color(0xFFfee66f)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  final _planetPaint = Paint()
    ..color = const Color(0xFF00FF00) // color of the planet
    ..style = PaintingStyle.fill;

  final sunRayLength = 100.0;
  final orbitRadius1 = 400.0;

  final starRadius = 1.5;
  final sunRadius = 50.0;

  var planetRadius = 50.0; // radius of the planet
  double planetAngle = 0.0; // angle of the planet on the orbital path in radians


  @override
  void paint(Canvas canvas, Size size) {

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, _paint);

    for (var i = 0; i < starCount; i++) {
      final starPosition = Offset(
        _random.nextDouble() * size.width,
        _random.nextDouble() * size.height,
      );
      canvas.drawCircle(starPosition, starRadius, _distantStarPaint);
    }

    drawSun(canvas, size);
    drawOrbit(canvas, size);
    drawPlanet(canvas, size);
  }

  void drawPlanet(Canvas canvas, Size size) {
    final sunPosition = Offset(
      size.width / 2,
      size.height / 2,
    );

    // Calculate the position of the planet on the orbital path
    final planetPosition = Offset(
      sunPosition.dx + orbitRadius1 * cos(planetAngle),
      sunPosition.dy + orbitRadius1 * sin(planetAngle),
    );

    // Calculate the relative position of the planet to the sun
    final relativePosition = planetPosition - sunPosition;
    final normalizedPosition = Alignment(
      2 * (relativePosition.dx / size.width) - 1,
      2 * (relativePosition.dy / size.height) - 1,
    );

    final alignment = Alignment(
      cos(planetAngle) * orbitRadius1 / (size.width / 2) * -1,
      sin(planetAngle) * orbitRadius1 / (size.height / 2) * -1,
    );

    print(relativePosition);
    print(normalizedPosition);

    // Define the gradient
    final gradient = RadialGradient(
      // center: Alignment(-0.5, 0.15),
      center: alignment,
      radius: 0.5, // covers the full circle
      colors: const <Color>[
        Color(0xFFbbcd96), // inner color
        Color(0xFF5b7c65), // outer color
      ],
      stops: <double>[0.0, 1.0], // defines the position of the colors
    );

    // Create a Rect that represents the bounds of the circle
    final rect = Rect.fromCircle(center: planetPosition, radius: planetRadius);

    // Create the Shader from the gradient and the bounding square
    final shader = gradient.createShader(rect);

    // Set the Shader to the Paint
    _planetPaint.shader = shader;

    // Draw the planet
    canvas.drawCircle(planetPosition, planetRadius, _planetPaint);

    // Update the angle for the next frame
    planetAngle += 0.01; // adjust this value to change the speed of the planet
  }

  void drawOrbit(Canvas canvas, Size size, {double orbitRadius = 400.0}) {
    final sunPosition = Offset(
      size.width / 2,
      size.height / 2,
    );
    final orbitalPath = Path();
    orbitalPath.addOval(Rect.fromCircle(center: sunPosition, radius: orbitRadius));
    canvas.drawPath(orbitalPath, _orbitalPathPaint);
  }

  void drawSun(Canvas canvas, Size size) {
    final sunPosition = Offset(
      size.width / 2,
      size.height / 2,
    );
    canvas.drawCircle(sunPosition, sunRadius, _sunPaint);
    drawSunRays(canvas, sunPosition, size);
  }

  void drawSunRays(Canvas canvas, Offset sunPosition, Size size) {
    final sunRayPath = Path();
    sunRayPath.moveTo(sunPosition.dx, sunPosition.dy);
    sunRayPath.lineTo(sunPosition.dx + sunRayLength, sunPosition.dy);
    sunRayPath.moveTo(sunPosition.dx, sunPosition.dy);
    sunRayPath.lineTo(sunPosition.dx - sunRayLength, sunPosition.dy);
    sunRayPath.moveTo(sunPosition.dx, sunPosition.dy);
    sunRayPath.lineTo(sunPosition.dx, sunPosition.dy + sunRayLength);
    sunRayPath.moveTo(sunPosition.dx, sunPosition.dy);
    sunRayPath.lineTo(sunPosition.dx, sunPosition.dy - sunRayLength);
    sunRayPath.moveTo(sunPosition.dx, sunPosition.dy);
    sunRayPath.lineTo(sunPosition.dx + sunRayLength / 2, sunPosition.dy + sunRayLength / 2);
    sunRayPath.moveTo(sunPosition.dx, sunPosition.dy);
    sunRayPath.lineTo(sunPosition.dx - sunRayLength / 2, sunPosition.dy - sunRayLength / 2);
    sunRayPath.moveTo(sunPosition.dx, sunPosition.dy);
    sunRayPath.lineTo(sunPosition.dx + sunRayLength / 2, sunPosition.dy - sunRayLength / 2);
    sunRayPath.moveTo(sunPosition.dx, sunPosition.dy);
    sunRayPath.lineTo(sunPosition.dx - sunRayLength / 2, sunPosition.dy + sunRayLength / 2);
    canvas.drawPath(sunRayPath, sunRayPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}