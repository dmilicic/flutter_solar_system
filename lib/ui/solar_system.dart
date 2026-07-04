import 'dart:math';
import 'dart:ui' show FragmentProgram;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:solar_system/network/spaceship_network_operations.dart';
import 'package:solar_system/providers/space_painter_provider.dart';
import 'package:solar_system/repository/spaceship_repository.dart';
import 'package:solar_system/ui/painters/planet_painter.dart';
import 'package:solar_system/ui/painters/space_painter.dart';

import '../models/planet_data.dart';
import '../models/spaceship_data.dart';
import 'config.dart';

class SolarSystem extends StatefulWidget {
  const SolarSystem({super.key});

  @override
  State<SolarSystem> createState() => _SolarSystemState();
}

class _SolarSystemState extends State<SolarSystem> with SingleTickerProviderStateMixin {

  final dataProvider = SpacePainterProvider();
  final networkOperations = SpaceshipNetworkOperations();
  final repository = SpaceshipRepository();

  late final Ticker _ticker;

  // Captured once so the StreamBuilders below keep the same subscription
  // across every rebuild; the ticker calls setState() every frame, and
  // re-invoking repository.observeSpaceships() in build() would otherwise
  // tear down and recreate the Firebase listener 60 times a second.
  late final Stream<SpaceshipData> _playerSpaceshipStream;
  late final Stream<List<SpaceshipData>> _otherSpaceshipsStream;

  final TransformationController _controller = TransformationController();
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _currentKeysPressed = {};

  double _elapsed = 0.0;

  bool playerShipInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      const midPoint = Offset(Config.spaceWidth / 2, Config.spaceHeight / 2);
      const initialScale = 0.5;

      final initialOffset = Offset(midPoint.dx * initialScale - screenSize.width / 2, midPoint.dy * initialScale - screenSize.height / 2);

      _controller.value = Matrix4.identity()
        ..translate(-initialOffset.dx, -initialOffset.dy, 0)
        ..scale(initialScale);

    });

    repository.registerNewSpaceship();
    _playerSpaceshipStream = repository.observePlayerSpaceship();
    _otherSpaceshipsStream = repository.observeSpaceships();

    _loadSunShader();

    _ticker = createTicker((elapsed) {

      dataProvider.time = elapsed.inMilliseconds / 1000.0; // seconds, for the fire shader

      setState(() {}); // trigger a repaint

      final playerSpaceship = repository.playerSpaceship;
      var spaceshipY = playerSpaceship?.locationY ?? 0.0;
      var spaceshipX = playerSpaceship?.locationX ?? 0.0;

      if (_currentKeysPressed.isNotEmpty) {
        if (_currentKeysPressed.contains(LogicalKeyboardKey.arrowUp)) {
          spaceshipY -= 10.0;
        }
        if (_currentKeysPressed.contains(LogicalKeyboardKey.arrowDown)) {
          spaceshipY += 10.0;
        }
        if (_currentKeysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
          spaceshipX -= 10.0;
        }
        if (_currentKeysPressed.contains(LogicalKeyboardKey.arrowRight)) {
          spaceshipX += 10.0;
        }
      }

      // send the updates after a short period of time
      final elapsedMillis = elapsed.inMilliseconds.toDouble();
      if(elapsedMillis - _elapsed > 10) {
        _elapsed = elapsedMillis;

        if (!playerShipInitialized || spaceshipX != playerSpaceship?.locationX || spaceshipY != playerSpaceship?.locationY) {
          playerShipInitialized = true;
          repository.updateSpaceshipLocation(spaceshipX, spaceshipY);
        }
      }
    });

    _ticker.start();
  }

  Future<void> _loadSunShader() async {
    final program = await FragmentProgram.fromAsset('shaders/sun_realistic.frag');
    dataProvider.sunShader = program.fragmentShader();

    for (final entry in planetShaderAssets.entries) {
      final planetProgram = await FragmentProgram.fromAsset(entry.value);
      dataProvider.planetShaders[entry.key] = planetProgram.fragmentShader();
    }
  }

  /// A ship model with its name shown underneath. Only the model rotates with
  /// the ship's orientation; the name label stays upright and readable.
  Widget _shipWidget(SpaceshipData ship) {
    return Positioned(
      left: ship.locationX,
      top: ship.locationY,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: ship.orientation,
            child: Image.asset('assets/ships/ship${ship.shipType}.png', width: 50, height: 50),
          ),
          const SizedBox(height: 2),
          Text(
            ship.name,
            style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          _currentKeysPressed.add(event.logicalKey);
        } else if (event is KeyUpEvent) {
          _currentKeysPressed.remove(event.logicalKey);
        }
      },
      child: InteractiveViewer(
        transformationController: _controller,
        clipBehavior: Clip.none,
        constrained: false,
        maxScale: 10,
        minScale: 0.01,
        child: Stack(children: [
          SizedBox(
            width: Config.spaceWidth,
            height: Config.spaceHeight,
            child: CustomPaint(
              painter: SpacePainter(dataProvider),
            ),
          ),

          SizedBox(
            width: Config.spaceWidth,
            height: Config.spaceHeight,
            child: CustomPaint(
              painter: PlanetPainter(dataProvider),
            ),
          ),

          StreamBuilder(
            stream: _playerSpaceshipStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final spaceshipData = snapshot.data as SpaceshipData;

                return _shipWidget(spaceshipData);
              } else {
                return Container();
              }
            },
          ),

          // other spaceships
          StreamBuilder(
            stream: _otherSpaceshipsStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final spaceshipData = snapshot.data as List<SpaceshipData>;

                var spaceshipWidgets = <Widget>[];
                for (var ship in spaceshipData) {

                  spaceshipWidgets.add(_shipWidget(ship));
                }

                return SizedBox(
                    width: Config.spaceWidth,
                    height: Config.spaceHeight,
                    child: Stack(children: spaceshipWidgets));
              } else {
                return Container();
              }
            },
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

Color getRandomColor() {
  Random random = Random();
  return Color.fromRGBO(
    random.nextInt(256), // Red
    random.nextInt(256), // Green
    random.nextInt(256), // Blue
    1, // Alpha
  );
}