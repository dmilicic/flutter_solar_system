class SpaceshipData {
  final String id;
  final String name;
  final double locationX;
  final double locationY;
  final int lastUpdated;
  final int shipType;

  SpaceshipData({
    required this.id,
    required this.name,
    required this.locationX,
    required this.locationY,
    required this.lastUpdated,
    this.shipType = 2,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'locationX': locationX,
      'locationY': locationY,
      'lastUpdated': lastUpdated,
      'shipType': shipType,
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
    );
  }
}