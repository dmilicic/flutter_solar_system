import 'dart:async';
import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:solar_system/repository/spaceship_repository_interface.dart';
import 'package:uuid/uuid.dart';

import '../models/spaceship_data.dart';
import '../ui/config.dart';

class SpaceshipRepository implements ISpaceshipRepository {
  // Ships are grouped into batches of this size so each client only streams
  // one batch's worth of positions, no matter how many visitors are on the
  // site. Once a batch reaches capacity, the next visitor starts a new one.
  static const _batchCapacity = 10;

  final uuid = const Uuid();
  final _db = FirebaseDatabase.instance;
  final _random = Random();
  final _analytics = FirebaseAnalytics.instance;

  // Pool of starship names. Ships are christened "SS <name>", e.g. "SS Enterprise".
  static const _shipNames = <String>[
    'Enterprise',
    'Discovery',
    'Voyager',
    'Endeavour',
    'Defiant',
    'Nostromo',
    'Serenity',
    'Galactica',
    'Rocinante',
    'Normandy',
    'Sulaco',
    'Prometheus',
    'Andromeda',
    'Icarus',
    'Bebop',
    'Nautilus',
    'Excelsior',
    'Yamato',
    'Executor',
    'Nebuchadnezzar',
  ];

  String _randomShipName() =>
      'SS ${_shipNames[_random.nextInt(_shipNames.length)]}';

  late SpaceshipData? playerSpaceship;

  // The batch this session's ship was assigned to. Stored as a Future (rather
  // than awaited immediately) so that registerNewSpaceship can hand out the
  // in-flight assignment to any update that arrives before it resolves,
  // instead of each caller racing its own transaction.
  Future<int>? _batchIdFuture;

  final _spaceshipStreamController = StreamController<SpaceshipData>();
  Stream<SpaceshipData> get spaceshipStream =>
      _spaceshipStreamController.stream;

  final spaceships = <String, SpaceshipData>{}; // <id, SpaceshipData>

  Future<SpaceshipData> registerNewSpaceship() async {
    // One spaceship is registered per visitor session, so this doubles as
    // our "site visited" counter in the Analytics dashboard.
    _analytics.logEvent(name: 'ship_spawned');

    final randomShipType = _random.nextInt(3) + 1;

    final id = uuid.v4();
    playerSpaceship = SpaceshipData(
      id: id,
      name: _randomShipName(),
      locationX: Config.spaceWidth / 2.0 - 200.0,
      locationY: Config.spaceHeight / 2.0 - 200.0,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
      shipType: randomShipType,
    );

    _batchIdFuture = _assignBatch();

    await updateRemoteSpaceshipData(playerSpaceship!);

    final batchId = await _batchIdFuture!;

    // Remove this ship the moment its connection drops (tab closed, browser
    // crashed, etc.) so it doesn't linger in the batch forever.
    await _db.ref('spaceships/$batchId/$id').onDisconnect().remove();

    // populate our local map
    final snapshot = await _db.ref('spaceships/$batchId').get();
    _updateLocalSpaceships(snapshot);

    _spaceshipStreamController.sink.add(playerSpaceship!);

    return playerSpaceship!;
  }

  // Atomically claims a slot in the batch currently being filled, or starts a
  // new one if it's full. Using a transaction on a single counter node keeps
  // this race-free even when many visitors join at the same moment.
  Future<int> _assignBatch() async {
    final ref = _db.ref('currentSpaceshipBatch');
    final result = await ref.runTransaction((Object? current) {
      final data = current as Map<Object?, Object?>?;
      final index = (data?['index'] as num?)?.toInt() ?? 0;
      final count = (data?['count'] as num?)?.toInt() ?? 0;

      final isFull = count >= _batchCapacity;
      return Transaction.success({
        'index': isFull ? index + 1 : index,
        'count': isFull ? 1 : count + 1,
      });
    });

    final committed = result.snapshot.value as Map<Object?, Object?>;
    return (committed['index'] as num).toInt();
  }

  Future<void> updateRemoteSpaceshipData(SpaceshipData spaceshipData) async {
    final batchId = await _batchIdFuture;
    if (batchId == null) return; // batch not assigned yet; drop this update

    DatabaseReference ref = _db.ref("spaceships/$batchId/${spaceshipData.id}");
    await ref.set(spaceshipData.toMap()).onError((error, stackTrace) {
      if (kDebugMode) {
        print('Failed to update spaceship data: $error');
      }
    }).timeout(const Duration(seconds: 5), onTimeout: () {
      if (kDebugMode) {
        print(
            'Failed to update spaceship data: timeout, ${spaceshipData.toMap()}');
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
  Stream<List<SpaceshipData>> observeSpaceships() async* {
    // Only ever listen to our own batch's node, so a client streams at most
    // _batchCapacity other ships' worth of data regardless of total visitors.
    final batchId = await _batchIdFuture;
    if (batchId == null) {
      yield const [];
      return;
    }

    yield* _db.ref('spaceships/$batchId').onValue.map((event) {
      if (kDebugMode) {
        print('spaceship added: ${event.snapshot.value}');
      }
      _updateLocalSpaceships(event.snapshot);

      // filter old spaceships out
      final now = DateTime.now().millisecondsSinceEpoch;
      const oldThreshold = 5; // in minutes; hide ships idle longer than this

      final spaceshipsToShow = spaceships.values
          .where(
              (element) => now - element.lastUpdated < oldThreshold * 60 * 1000)
          .where((element) =>
              element.id !=
              playerSpaceship?.id); // don't draw the player spaceship here

      return spaceshipsToShow.toList();
    });
  }

  updateSpaceshipLocation(double spaceshipX, double spaceshipY) {
    playerSpaceship = SpaceshipData(
      id: playerSpaceship?.id ?? uuid.v4(),
      name: playerSpaceship?.name ?? _randomShipName(),
      locationX: spaceshipX,
      locationY: spaceshipY,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
      shipType: playerSpaceship?.shipType ?? _random.nextInt(3) + 1,
      orientation:
          playerSpaceship?.determineOrientation(spaceshipX, spaceshipY) ?? 0.0,
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
    final spaceshipData =
        data.map((key, value) => MapEntry(key.toString(), value));
    final spaceship = SpaceshipData.fromJson(spaceshipData);
    spaceships[spaceship.id] = spaceship;
  }
}
