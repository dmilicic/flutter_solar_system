class SpaceshipData {
  final String id;
  final String name;
  final double locationX;
  final double locationY;

  SpaceshipData({
    required this.id,
    required this.name,
    required this.locationX,
    required this.locationY
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'locationX': locationX,
      'locationY': locationY,
    };
  }

  factory SpaceshipData.fromJson(Map<String, dynamic> json) {
    return SpaceshipData(
      id: json['id'],
      name: json['name'],
      locationX: (json['locationX'] as num).toDouble(),
      locationY: (json['locationY'] as num).toDouble(),
    );
  }
}