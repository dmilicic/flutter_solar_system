import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:solar_system/repository/spaceship_repository_interface.dart';
import 'package:uuid/uuid.dart';

import '../models/spaceship_data.dart';
import '../ui/config.dart';

class SpaceshipRepository implements ISpaceshipRepository {

  final uuid = const Uuid();
  final _db = FirebaseDatabase.instance;
  final _random = Random();

  late SpaceshipData? playerSpaceship;

  final _spaceshipStreamController = StreamController<SpaceshipData>();
  Stream<SpaceshipData> get spaceshipStream => _spaceshipStreamController.stream;

  final spaceships = <String, SpaceshipData>{}; // <id, SpaceshipData>

  Future<SpaceshipData> registerNewSpaceship() async {

    final randomShipType = _random.nextInt(3) + 1;

    final id = uuid.v4();
    playerSpaceship = SpaceshipData(
      id: id,
      name: 'Spaceship 1',
      locationX: Config.spaceWidth / 2.0 - 200.0,
      locationY: Config.spaceHeight / 2.0 - 200.0,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
      shipType: randomShipType,
    );

    await updateRemoteSpaceshipData(playerSpaceship!);

    // populate our local map
    final snapshot = await _db.ref("spaceships").get();
    _updateLocalSpaceships(snapshot);

    _spaceshipStreamController.sink.add(playerSpaceship!);

    return playerSpaceship!;
  }

  Future<void> updateRemoteSpaceshipData(SpaceshipData spaceshipData) async {
    DatabaseReference ref = _db.ref("spaceships/${spaceshipData.id}");
    await ref.set(spaceshipData.toMap())
        .onError((error, stackTrace) {
          if (kDebugMode) {
            print('Failed to update spaceship data: $error');
          }
    }).timeout(const Duration(seconds: 5), onTimeout: () {
      if (kDebugMode) {
        print('Failed to update spaceship data: timeout');
      }
    });
  }

  SpaceshipData? getPlayerSpaceship() {
    return playerSpaceship;
  }

  @override
  Stream<SpaceshipData> observePlayerSpaceship() {
    return spaceshipStream;
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
      const oldThreshold = 60 * 24 * 2; // in minutes, 2 days

      final spaceshipsToShow = spaceships.values
          .where((element) => now - element.lastUpdated < oldThreshold * 60 * 1000)
          .where((element) => element.id != playerSpaceship?.id); // don't draw the player spaceship here

      return spaceshipsToShow.toList();
    });
  }

  updateSpaceshipLocation(double spaceshipX, double spaceshipY) {
    playerSpaceship = SpaceshipData(
      id: playerSpaceship?.id ?? uuid.v4(),
      name: playerSpaceship?.name ?? 'Spaceship 1',
      locationX: spaceshipX,
      locationY: spaceshipY,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
      orientation: playerSpaceship?.determineOrientation(spaceshipX, spaceshipY) ?? 0.0,
    );

    _spaceshipStreamController.sink.add(playerSpaceship!);

    updateRemoteSpaceshipData(playerSpaceship!);
  }

  void _updateLocalSpaceships(DataSnapshot snapshot) async {
    for (var doc in snapshot.children) {
      _updateSpaceship(doc.value as Map<Object?, Object?>);
    }
  }

  void _updateSpaceship(Map<Object?, Object?> data) {
    final spaceshipData = data.map((key, value) => MapEntry(key.toString(), value));
    final spaceship = SpaceshipData.fromJson(spaceshipData);
    spaceships[spaceship.id] = spaceship;
  }
}