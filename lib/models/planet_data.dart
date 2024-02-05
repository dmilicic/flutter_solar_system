import 'dart:math';
import 'dart:ui';

class PlanetData {
  final String name;
  final String description;
  final Color color;
  final double distance;
  final double radius;
  double angle = 0.0; // angle of the planet on the orbital path in radians
  double revolutionSpeed = 0.0001; // how much the angle changes per second

  PlanetData({
    this.name = "Planet",
    this.description = "a planet",
    required this.color,
    required this.distance,
    required this.radius,
    this.angle = 0.0,
    this.revolutionSpeed = 0.0001,
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

// this will make all the planets be aligned across all visiting users
final basePlanetAngle = DateTime.now().millisecondsSinceEpoch;

final planets = [
  PlanetData(color: const Color(0xFFbbcd96), distance: 400, radius: 50, revolutionSpeed: 0.0003, angle: basePlanetAngle / 16 * 0.0003), // divided by 16 as that that is the frame rate
  PlanetData(color: const Color(0xFF92c1ff), distance: 500, radius: 25, revolutionSpeed: 0.0002, angle: basePlanetAngle / 16 * 0.0002),
  PlanetData(color: const Color(0xFFff834b), distance: 800, radius: 40, revolutionSpeed: 0.0004, angle: basePlanetAngle / 16 * 0.0004),
  PlanetData(color: const Color(0xFFc4b995), distance: 950, radius: 15, revolutionSpeed: 0.0002, angle: basePlanetAngle / 16 * 0.0002),
];