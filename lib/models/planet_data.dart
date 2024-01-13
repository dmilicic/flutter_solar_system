import 'dart:math';
import 'dart:ui';

class PlanetData {
  final String name;
  final String description;
  final Color color;
  final double distance;
  final double radius;
  double angle = 0.0; // angle of the planet on the orbital path in radians

  PlanetData({
    this.name = "Planet",
    this.description = "a planet",
    required this.color,
    required this.distance,
    required this.radius,
    this.angle = 0.0,
  });

  factory PlanetData.fromJson(Map<String, dynamic> json) {
    return PlanetData(
      name: json['name'],
      description: json['description'],
      color: json['image'],
      distance: json['distance'],
      radius: json['radius'],
    );
  }
}

final _random = Random();

final planets = [
  PlanetData(color: const Color(0xFFbbcd96), distance: 400, radius: 50, angle: _random.nextDouble() * 2 * pi),
  PlanetData(color: const Color(0xFF92c1ff), distance: 500, radius: 25, angle: _random.nextDouble() * 2 * pi),
  PlanetData(color: const Color(0xFFff834b), distance: 800, radius: 40, angle: _random.nextDouble() * 2 * pi),
  PlanetData(color: const Color(0xFFc4b995), distance: 1000, radius: 15, angle: _random.nextDouble() * 2 * pi),
];