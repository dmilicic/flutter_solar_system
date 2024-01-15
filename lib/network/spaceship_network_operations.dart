import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/spaceship_data.dart';

class SpaceshipNetworkOperations {

  final _spaceshipStreamController = StreamController<SpaceshipData>();

  Stream<SpaceshipData> get spaceshipStream => _spaceshipStreamController.stream;

  final random = Random();

  void fetchSpaceshipData() {
    // Fetch the data from network or any other source
    // For now, let's use a dummy SpaceshipData
    SpaceshipData spaceshipData = SpaceshipData(
      id: '1',
      name: 'Spaceship 1',
      locationX: 200.0,
      locationY: 200.0,
    );

    var oldSpaceshipData = spaceshipData;

    Future.doWhile(() async {
      final movedSpaceship = SpaceshipData(
        id: spaceshipData.id,
        name: spaceshipData.name,
        locationX: oldSpaceshipData.locationX + 10.0 * random.nextDouble(),
        locationY: oldSpaceshipData.locationY + 10.0 * random.nextDouble(),
      );

      print("Spaceship: ${movedSpaceship.locationX}, ${movedSpaceship.locationY}");

      await Future.delayed(const Duration(milliseconds: 16));

      oldSpaceshipData = movedSpaceship;

      _spaceshipStreamController.sink.add(movedSpaceship);

      return true;
    });

  }

  void observeSpaceshipData(void Function(SpaceshipData event) onData) {
    spaceshipStream.listen((SpaceshipData data) {
      // We have new spaceship data
      print('Spaceship Name: ${data.name}');
      onData(data);
    });
  }

  void dispose() {
    _spaceshipStreamController.close();
  }
}