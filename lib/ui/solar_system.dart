import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:solar_system/network/spaceship_network_operations.dart';
import 'package:solar_system/providers/space_painter_provider.dart';
import 'package:solar_system/repository/spaceship_repository.dart';
import 'package:solar_system/ui/painters/space_painter.dart';
import 'package:solar_system/ui/painters/spaceship_painter.dart';

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

  double spaceshipX = 1000.0;
  double spaceshipY = 500.0;

  double _elapsed = 0.0;

  final colors = <Color>[
    const Color(0xFFff834b),
    getRandomColor(),
    getRandomColor(),
    getRandomColor(),
    getRandomColor(),
    getRandomColor(),
    getRandomColor(),
    getRandomColor(),
    getRandomColor(),
    getRandomColor(),
    getRandomColor(),
    getRandomColor(),
    getRandomColor(),
  ];

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((elapsed) {

      setState(() {}); // trigger a repaint

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
        repository.updateSpaceshipLocation(spaceshipX, spaceshipY);
      }
    });

    _ticker.start();

    repository.registerNewSpaceship();
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

          // player spaceship
          Positioned(
            left: spaceshipX,
            top: spaceshipY,
            child: CustomPaint(
              painter: SpaceshipPainter(color: colors[0]),
            ),
          ),

          // other spaceships
          StreamBuilder(
            stream: repository.observeSpaceships(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final spaceshipData = snapshot.data as List<SpaceshipData>;

                var spaceshipWidgets = <Widget>[];
                for (var ship in spaceshipData) {

                  final idx = spaceshipData.indexOf(ship);

                  spaceshipWidgets.add(Positioned(
                    left: ship.locationX,
                    top: ship.locationY,
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CustomPaint(
                        painter: SpaceshipPainter(color: colors[idx % colors.length]),
                      ),
                    ),
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