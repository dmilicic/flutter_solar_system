import 'dart:math';
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

/// Fixed reference instant shared by ALL clients so everyone computes the same
/// planet positions from their wall clock. Arbitrary, but must never change
/// once shipped — changing it rotates the whole system for every visitor.
const orbitEpochMs = 1700000000000; // 2023-11-14T22:13:20Z

class PlanetData {
  final String name;
  final String description;
  final Color color;
  final double distance;
  final double radius;
  final PlanetType type;

  /// Angle on the orbital path at [orbitEpochMs], in radians. Spreading this
  /// across planets keeps them off the same ray at the epoch.
  final double initialAngle;

  /// Orbital angular velocity in radians per second.
  final double revolutionSpeed;

  /// Current angle on the orbital path, recomputed each frame from wall-clock
  /// time via [angleAt]. Never accumulated, so it cannot drift between clients.
  double angle = 0.0;

  PlanetData({
    this.name = "Planet",
    this.description = "a planet",
    required this.color,
    required this.distance,
    required this.radius,
    this.type = PlanetType.rocky,
    this.initialAngle = 0.0,
    this.revolutionSpeed = 0.006,
  }) : angle = initialAngle;

  /// The planet's orbital angle at wall-clock time [nowMs] (ms since Unix
  /// epoch). Pure function of absolute time, so all synced clocks agree.
  double angleAt(int nowMs) =>
      initialAngle + revolutionSpeed * (nowMs - orbitEpochMs) / 1000.0;

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

// Positions are derived from wall-clock time against [orbitEpochMs] (see
// angleAt), so every visitor with a roughly-correct clock sees the same layout.
// revolutionSpeed is radians/second; initialAngle spreads them out at the epoch.
final planets = [
  PlanetData(color: const Color(0xFFff834b), distance: 500, radius: 55, type: PlanetType.volcanic, revolutionSpeed: 0.024, initialAngle: 0.0),
  PlanetData(color: const Color(0xFFc4b995), distance: 800, radius: 120, type: PlanetType.rocky, revolutionSpeed: 0.012, initialAngle: pi / 2),
  PlanetData(color: const Color(0xFFbbcd96), distance: 1000, radius: 70, type: PlanetType.earth, revolutionSpeed: 0.018, initialAngle: pi),
  PlanetData(color: const Color(0xFF92c1ff), distance: 1500, radius: 150, type: PlanetType.jupiter, revolutionSpeed: 0.012, initialAngle: 3 * pi / 2),
];