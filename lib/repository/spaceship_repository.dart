import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:solar_system/repository/spaceship_repository_interface.dart';
import 'package:uuid/uuid.dart';

import '../models/spaceship_data.dart';

class SpaceshipRepository implements ISpaceshipRepository {

  final uuid = const Uuid();
  final _db = FirebaseDatabase.instance;
  final _random = Random();

  late SpaceshipData playerSpaceship;

  final spaceships = <String, SpaceshipData>{}; // <id, SpaceshipData>

  Future<void> registerNewSpaceship() async {

    final randomShipType = _random.nextInt(3) + 1;

    final id = uuid.v4();
    playerSpaceship = SpaceshipData(
      id: id,
      name: 'Spaceship 1',
      locationX: 200.0,
      locationY: 200.0,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
      shipType: randomShipType,
    );

    await updateSpaceshipData(playerSpaceship);

    // populate our local map
    final snapshot = await _db.ref("spaceships").get();
    _updateLocalSpaceships(snapshot);
  }

  Future<void> updateSpaceshipData(SpaceshipData spaceshipData) async {
    DatabaseReference ref = _db.ref("spaceships/${spaceshipData.id}");
    await ref.set({
      'id': spaceshipData.id,
      'name': spaceshipData.name,
      'locationX': spaceshipData.locationX,
      'locationY': spaceshipData.locationY,
      'lastUpdated': spaceshipData.lastUpdated,
    }).onError((error, stackTrace) {
      if (kDebugMode) {
        print('Failed to update spaceship data: $error');
      }
    }).timeout(const Duration(seconds: 5), onTimeout: () {
      if (kDebugMode) {
        print('Failed to update spaceship data: timeout');
      }
    });
  }

  @override
  Stream<List<SpaceshipData>> observeSpaceships() {
    return _db.ref('spaceships').onValue.map((event) {
      if (kDebugMode) {
        // print('spaceship added: ${event.snapshot.value}');
      }
      _updateLocalSpaceships(event.snapshot);

      // filter old spaceships out
      final now = DateTime.now().millisecondsSinceEpoch;
      const oldThreshold = 5; // in minutes

      final spaceshipsToShow = spaceships.values
          .where((element) => now - element.lastUpdated < oldThreshold * 60 * 1000)
          .where((element) => element.id != playerSpaceship.id); // don't draw the player spaceship here

      return spaceshipsToShow.toList();
    });
  }

  void updateSpaceshipLocation(double spaceshipX, double spaceshipY) {
    if (playerSpaceship != null) {
      updateSpaceshipData(SpaceshipData(
        id: playerSpaceship.id,
        name: playerSpaceship.name,
        locationX: spaceshipX,
        locationY: spaceshipY,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  void _updateLocalSpaceships(DataSnapshot snapshot) async {
    for (var doc in snapshot.children) {
      _updateSpaceship(doc.value as Map<String, dynamic>);
    }
  }

  void _updateSpaceship(Map<String, dynamic> data) {
    final spaceship = SpaceshipData.fromJson(data);
    spaceships[spaceship.id] = spaceship;
  }

}