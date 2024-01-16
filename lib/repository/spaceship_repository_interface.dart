import '../models/spaceship_data.dart';

abstract class ISpaceshipRepository {
  Stream<List<SpaceshipData>> observeSpaceships();
}