import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:solar_system/network/spaceship_network_operations.dart';
import 'package:solar_system/providers/space_painter_provider.dart';
import 'package:solar_system/repository/spaceship_repository.dart';
import 'package:solar_system/ui/painters/planet_painter.dart';
import 'package:solar_system/ui/painters/space_painter.dart';

import '../models/spaceship_data.dart';

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

  final TransformationController _controller = TransformationController();
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _currentKeysPressed = {};

  final spaceWidth = 2000.0;
  final spaceHeight = 2000.0;

  double _elapsed = 0.0;

  bool playerShipInitialized = false;

  @override
  void initState() {
    super.initState();

    _controller.value = Matrix4.identity()
      ..scale(0.8)
      ..translate(-spaceWidth / 4, -spaceHeight / 4);

    repository.registerNewSpaceship();

    _ticker = createTicker((elapsed) {

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

  @override
  Widget build(BuildContext context) {

    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          _currentKeysPressed.add(event.logicalKey);
        } else if (event is RawKeyUpEvent) {
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
            width: spaceWidth,
            height: spaceHeight,
            child: CustomPaint(
              painter: SpacePainter(dataProvider),
            ),
          ),

          SizedBox(
            width: spaceWidth,
            height: spaceHeight,
            child: CustomPaint(
              painter: PlanetPainter(dataProvider),
            ),
          ),

          StreamBuilder(
            stream: repository.observePlayerSpaceship(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final spaceshipData = snapshot.data as SpaceshipData;

                return Positioned(
                  left: spaceshipData.locationX,
                  top: spaceshipData.locationY,
                  child: Transform.rotate(
                      angle: spaceshipData.orientation,
                      child: Image.asset('assets/ships/ship${spaceshipData.shipType}.png', width: 50, height: 50)
                  ),
                );
              } else {
                return Container();
              }
            },
          ),

          // other spaceships
          StreamBuilder(
            stream: repository.observeSpaceships(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final spaceshipData = snapshot.data as List<SpaceshipData>;

                var spaceshipWidgets = <Widget>[];
                for (var ship in spaceshipData) {

                  spaceshipWidgets.add(Positioned(
                    left: ship.locationX,
                    top: ship.locationY,
                    child: Transform.rotate(
                        angle: ship.orientation,
                        child: Image.asset('assets/ships/ship${ship.shipType}.png', width: 50, height: 50)
                    )
                  ));
                }

                return SizedBox(
                    width: spaceWidth,
                    height: spaceHeight,
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