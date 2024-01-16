import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:solar_system/repository/spaceship_repository_interface.dart';
import 'package:uuid/uuid.dart';

import '../models/spaceship_data.dart';

class SpaceshipRepository implements ISpaceshipRepository {

  final uuid = const Uuid();
  final _db = FirebaseDatabase.instance;

  late SpaceshipData playerSpaceship;

  final spaceships = <String, SpaceshipData>{}; // <id, SpaceshipData>

  Future<void> registerNewSpaceship() async {

    final id = uuid.v4();
    playerSpaceship = SpaceshipData(
      id: id,
      name: 'Spaceship 1',
      locationX: 200.0,
      locationY: 200.0,
    );

    await updateSpaceshipData(playerSpaceship);

    // populate our local map
    final snapshot = await _db.ref("spaceships").get();
    _updateSpaceships(snapshot);
  }

  Future<void> updateSpaceshipData(SpaceshipData spaceshipData) async {
    DatabaseReference ref = _db.ref("spaceships/${spaceshipData.id}");
    await ref.set({
      'id': spaceshipData.id,
      'name': spaceshipData.name,
      'locationX': spaceshipData.locationX,
      'locationY': spaceshipData.locationY,
    }).onError((error, stackTrace) =>
        print('Failed to update spaceship data: $error')
    ).timeout(Duration(seconds: 5), onTimeout: () {
      print('Failed to update spaceship data: timeout');
    });
  }

  @override
  Stream<List<SpaceshipData>> observeSpaceships() {
    return _db.ref('spaceships').onValue.map((event) {
      print('spaceship added: ${event.snapshot.value}');
      _updateSpaceships(event.snapshot);
      return spaceships.values.toList();
    });
  }

  void updateSpaceshipLocation(double spaceshipX, double spaceshipY) {
    if (playerSpaceship != null) {
      updateSpaceshipData(SpaceshipData(
        id: playerSpaceship.id,
        name: playerSpaceship.name,
        locationX: spaceshipX,
        locationY: spaceshipY,
      ));
    }
  }

  void _updateSpaceships(DataSnapshot snapshot) async {
    for (var doc in snapshot.children) {
      _updateSpaceship(doc.value as Map<String, dynamic>);
    }
  }

  void _updateSpaceship(Map<String, dynamic> data) {
    final spaceship = SpaceshipData.fromJson(data);
    spaceships[spaceship.id] = spaceship;
  }

}