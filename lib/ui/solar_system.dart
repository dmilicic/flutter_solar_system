import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:solar_system/network/spaceship_network_operations.dart';
import 'package:solar_system/providers/space_painter_provider.dart';
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

  late final Ticker _ticker;

  final TransformationController _controller = TransformationController();
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _currentKeysPressed = {};

  double spaceshipX = 1000.0;
  double spaceshipY = 500.0;

  double _elapsed = 0.0;

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

      // show a new spaceship every second
      final elapsedSeconds = elapsed.inSeconds.toDouble();
      if(elapsedSeconds - _elapsed > 1.0) {
        _elapsed = elapsedSeconds;

      }
    });

    _ticker.start();

    networkOperations.fetchSpaceshipData();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

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
          Container(
            width: 2000,
            height: 2000,
            child: CustomPaint(
              painter: SpacePainter(dataProvider),
            ),
          ),

          // player spaceship
          Positioned(
            left: spaceshipX,
            top: spaceshipY,
            child: CustomPaint(
              painter: SpaceshipPainter(),
            ),
          ),

          // other spaceships
          StreamBuilder(
            stream: networkOperations.spaceshipStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final spaceshipData = snapshot.data as SpaceshipData;
                return Positioned(
                  left: spaceshipData.locationX,
                  top: spaceshipData.locationY,
                  child: CustomPaint(
                    painter: SpaceshipPainter(),
                  ),
                );
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