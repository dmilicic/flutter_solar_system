import 'dart:ui';

/// The visual style of a planet, selecting which fragment shader renders it.
enum PlanetType { earth, jupiter, volcanic, rocky }

/// Shader asset for each planet type. All share the same uniform layout.
const planetShaderAssets = <PlanetType, String>{
  PlanetType.earth: 'shaders/planet_earth.frag',
  PlanetType.jupiter: 'shaders/planet_jupiter.frag',
  PlanetType.volcanic: 'shaders/planet_volcanic.frag',
  PlanetType.rocky: 'shaders/planet.frag',
};

class PlanetData {
  final String name;
  final String description;
  final Color color;
  final double distance;
  final double radius;
  final PlanetType type;
  double angle = 0.0; // angle of the planet on the orbital path in radians
  double revolutionSpeed = 0.0001; // how much the angle changes per second

  PlanetData({
    this.name = "Planet",
    this.description = "a planet",
    required this.color,
    required this.distance,
    required this.radius,
    this.type = PlanetType.rocky,
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
  PlanetData(color: const Color(0xFFff834b), distance: 500, radius: 55, type: PlanetType.volcanic, revolutionSpeed: 0.0004, angle: basePlanetAngle / 16 * 0.0004),
  PlanetData(color: const Color(0xFFc4b995), distance: 800, radius: 120, type: PlanetType.rocky, revolutionSpeed: 0.0002, angle: basePlanetAngle / 16 * 0.0002),
  PlanetData(color: const Color(0xFFbbcd96), distance: 1000, radius: 70, type: PlanetType.earth, revolutionSpeed: 0.0003, angle: basePlanetAngle / 16 * 0.0003), // divided by 16 as that that is the frame rate
  PlanetData(color: const Color(0xFF92c1ff), distance: 1500, radius: 150, type: PlanetType.jupiter, revolutionSpeed: 0.0002, angle: basePlanetAngle / 16 * 0.0002),
];