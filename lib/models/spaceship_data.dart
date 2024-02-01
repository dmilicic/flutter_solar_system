import 'dart:math';

class SpaceshipData {
  final String id;
  final String name;
  final double locationX;
  final double locationY;
  final int lastUpdated;
  final int shipType;
  final double orientation;

  SpaceshipData({
    required this.id,
    required this.name,
    required this.locationX,
    required this.locationY,
    required this.lastUpdated,
    this.shipType = 2,
    this.orientation = 0.0,
  });

  /// Determine the orientation of the spaceship based on the new location.
  double determineOrientation(double newX, double newY) {

    if (newX == locationX && newY == locationY) {
      return orientation;
    }

    final dx = newX - locationX;
    final dy = newY - locationY;

    if (dx == 0.0) {
      if (dy > 0.0) {
        return pi;
      } else {
        return 0.0;
      }
    }

    if (dy == 0.0) {
      if (dx > 0.0) {
        return pi / 2;
      } else {
        return 3 * pi / 2;
      }
    }

    if (dx > 0.0 && dy > 0.0) {
      return 3 * pi / 4;
    }

    if (dx > 0.0 && dy < 0.0) {
      return pi / 4;
    }

    if (dx < 0.0 && dy > 0.0) {
      return 5 * pi / 4;
    }

    if (dx < 0.0 && dy < 0.0) {
      return 7 * pi / 4;
    }

    return 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'locationX': locationX,
      'locationY': locationY,
      'lastUpdated': lastUpdated,
      'shipType': shipType,
      'orientation': orientation,
    };
  }

  factory SpaceshipData.fromJson(Map<String, dynamic> json) {

    return SpaceshipData(
      id: json['id'],
      name: json['name'],
      locationX: (json['locationX'] as num).toDouble(),
      locationY: (json['locationY'] as num).toDouble(),
      lastUpdated: (json['lastUpdated'] as num).toInt(),
      shipType: (json['shipType'] as num?)?.toInt() ?? 2,
      orientation: (json['orientation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  SpaceshipData? copyWith({required double orientation}) {
    return SpaceshipData(
      id: id,
      name: name,
      locationX: locationX,
      locationY: locationY,
      lastUpdated: lastUpdated,
      shipType: shipType,
      orientation: orientation,
    );
  }
}