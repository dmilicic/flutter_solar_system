

import 'dart:math';
import 'dart:ui';

import 'package:flutter/rendering.dart';

import '../models/planet_data.dart';

/// This class provides the data for the SpacePainter so it can paint the space.
class SpacePainterProvider {

  final _starPositions = <Offset>[];
  final _random = Random();

  bool starsPainted = false;

  /// Elapsed time in seconds, fed to the animated sun fire shader. Updated
  /// every frame from the [Ticker] in SolarSystem.
  double time = 0.0;

  /// The compiled fragment shader used to render the sun. Null until the
  /// async program load completes, in which case the painter falls back to a
  /// plain gradient.
  FragmentShader? sunShader;

  /// Compiled fragment shaders for each planet type (earth, jupiter, etc.),
  /// keyed by [PlanetType]. Empty until loaded; the painter falls back to a
  /// radial gradient for any type not yet present.
  final Map<PlanetType, FragmentShader> planetShaders = {};


  SpacePainterProvider() {
    generateStars(300);
  }

  final _spacePaint = Paint()
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

  final planetPainter = Paint()
  ..style = PaintingStyle.fill;

  Future<List<Offset>> generateStars(int starCount) async {
    for (var i = 0; i < starCount; i++) {
      final starPosition = Offset(_random.nextDouble(), _random.nextDouble());
      _starPositions.add(starPosition);
    }

    return _starPositions;
  }

  List<Offset> provideStars() {
    return _starPositions;
  }

  Paint provideSpacePaint() {
    return _spacePaint;
  }

  Paint provideStarPaint() {
    return _distantStarPaint;
  }

  Paint provideSunPaint() {
    return _sunPaint;
  }

  Paint provideOrbitalPathPaint() {
    return _orbitalPathPaint;
  }

  Paint provideSunRayPaint() {
    return sunRayPaint;
  }

  Paint providePlanetPaint(Color color) {
    return planetPainter..color = color;
  }

  List<PlanetData> providePlanets() {
    return planets;
  }
}