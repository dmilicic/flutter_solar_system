import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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

    // final snapshot = await FirebaseDatabase.instance.ref("spaceships").get();
    // if (!snapshot.exists) {
    //   FirebaseDatabase.instance.ref("spaceships").set({});
    // }

    final id = uuid.v4();
    playerSpaceship = SpaceshipData(
      id: id,
      name: 'Spaceship 1',
      locationX: 200.0,
      locationY: 200.0,
    );

    await updateSpaceshipData(playerSpaceship);

    // populate our local map
    _updateSpaceships();
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
    return _db.ref('spaceships').onChildChanged.map((event) {

      print(event.snapshot.value);

      _updateSpaceship(event.snapshot as Map<String, dynamic>);

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

  void _updateSpaceships() async {
    final snapshot = await FirebaseDatabase.instance.ref("spaceships").get();
    for (var doc in snapshot.children) {
      _updateSpaceship(doc.value as Map<String, dynamic>);
    }
  }

  void _updateSpaceship(Map<String, dynamic> data) {
    final spaceship = SpaceshipData.fromJson(data);
    spaceships[spaceship.id] = spaceship;
  }

}