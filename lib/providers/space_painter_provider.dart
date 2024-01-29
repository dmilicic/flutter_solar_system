

import 'dart:math';
import 'dart:ui';

import 'package:flutter/rendering.dart';

import '../models/planet_data.dart';

/// This class provides the data for the SpacePainter so it can paint the space.
class SpacePainterProvider {

  final _starPositions = <Offset>[];
  final _random = Random();

  bool starsPainted = false;


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