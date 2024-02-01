import '../models/spaceship_data.dart';

abstract class ISpaceshipRepository {
  Stream<SpaceshipData> observePlayerSpaceship();
  Stream<List<SpaceshipData>> observeSpaceships();
}