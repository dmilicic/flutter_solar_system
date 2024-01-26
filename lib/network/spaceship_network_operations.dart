import 'dart:async';
import 'dart:math';

import '../models/spaceship_data.dart';

class SpaceshipNetworkOperations {

  final _spaceshipStreamController = StreamController<List<SpaceshipData>>();

  Stream<List<SpaceshipData>> get spaceshipStream => _spaceshipStreamController.stream;

  final random = Random();

  void fetchSpaceshipData() {
    // Fetch the data from network or any other source
    // For now, let's use a dummy SpaceshipData

    var spaceships = <SpaceshipData>[];
    for(var i = 0; i < 100; i++) {
      spaceships.add(SpaceshipData(
        id: i.toString(),
        name: 'Spaceship $i',
        locationX: 2000 * random.nextDouble(),
        locationY: 2000 * random.nextDouble(),
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    Future.doWhile(() async {

      // update all spaceship movements
      for(var i = 0; i < spaceships.length; i++) {
        spaceships[i] = SpaceshipData(
          id: i.toString(),
          name: 'Spaceship $i',
          locationX: spaceships[i].locationX + 5.0 * random.nextDouble() * (random.nextBool() ? 1 : -1),
          locationY: spaceships[i].locationY + 5.0 * random.nextDouble() * (random.nextBool() ? 1 : -1),
          lastUpdated: DateTime.now().millisecondsSinceEpoch,
        );
      }

      await Future.delayed(const Duration(milliseconds: 50));

      _spaceshipStreamController.sink.add(spaceships);

      return true;
    });

  }

  void dispose() {
    _spaceshipStreamController.close();
  }
}