import 'dart:math';
import 'dart:ui' show FragmentProgram;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
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

class _SolarSystemState extends State<SolarSystem>
    with SingleTickerProviderStateMixin {
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

      final initialOffset = Offset(
          midPoint.dx * initialScale - screenSize.width / 2,
          midPoint.dy * initialScale - screenSize.height / 2);

      _controller.value = Matrix4.identity()
        ..translate(-initialOffset.dx, -initialOffset.dy, 0)
        ..scale(initialScale);
    });

    repository.registerNewSpaceship();
    _playerSpaceshipStream = repository.observePlayerSpaceship();
    _otherSpaceshipsStream = repository.observeSpaceships();

    _loadSunShader();

    _ticker = createTicker((elapsed) {
      dataProvider.time =
          elapsed.inMilliseconds / 1000.0; // seconds, for the fire shader

      setState(() {}); // trigger a repaint

      final playerSpaceship = repository.playerSpaceship;
      var spaceshipY = playerSpaceship?.locationY ?? 0.0;
      var spaceshipX = playerSpaceship?.locationX ?? 0.0;

      if (_currentKeysPressed.isNotEmpty) {
        const speed = 10.0;
        var dx = 0.0;
        var dy = 0.0;

        if (_currentKeysPressed.contains(LogicalKeyboardKey.arrowUp)) {
          dy -= 1.0;
        }
        if (_currentKeysPressed.contains(LogicalKeyboardKey.arrowDown)) {
          dy += 1.0;
        }
        if (_currentKeysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
          dx -= 1.0;
        }
        if (_currentKeysPressed.contains(LogicalKeyboardKey.arrowRight)) {
          dx += 1.0;
        }

        // Normalize so diagonal movement (e.g. up+left) covers the same
        // distance per tick as a single direction, instead of moving
        // sqrt(2)x faster.
        if (dx != 0.0 || dy != 0.0) {
          final length = sqrt(dx * dx + dy * dy);
          spaceshipX += dx / length * speed;
          spaceshipY += dy / length * speed;
        }
      }

      // send the updates after a short period of time
      final elapsedMillis = elapsed.inMilliseconds.toDouble();
      if (elapsedMillis - _elapsed > 10) {
        _elapsed = elapsedMillis;

        if (!playerShipInitialized ||
            spaceshipX != playerSpaceship?.locationX ||
            spaceshipY != playerSpaceship?.locationY) {
          playerShipInitialized = true;
          repository.updateSpaceshipLocation(spaceshipX, spaceshipY);
        }
      }
    });

    _ticker.start();
  }

  Future<void> _loadSunShader() async {
    final program =
        await FragmentProgram.fromAsset('shaders/sun_realistic.frag');
    dataProvider.sunShader = program.fragmentShader();

    for (final entry in planetShaderAssets.entries) {
      final planetProgram = await FragmentProgram.fromAsset(entry.value);
      dataProvider.planetShaders[entry.key] = planetProgram.fragmentShader();
    }
  }

  // Mirrors the keyboard handling below: on-screen d-pad buttons add/remove
  // the same LogicalKeyboardKey values so the ticker's movement logic doesn't
  // need to know whether the press came from a keyboard or a touch button.
  void _setKeyPressed(LogicalKeyboardKey key, bool pressed) {
    setState(() {
      if (pressed) {
        _currentKeysPressed.add(key);
      } else {
        _currentKeysPressed.remove(key);
      }
    });
  }

  Widget _controlButton(_ArrowDirection direction, LogicalKeyboardKey key) {
    final pressed = _currentKeysPressed.contains(key);
    return Listener(
      onPointerDown: (_) => _setKeyPressed(key, true),
      onPointerUp: (_) => _setKeyPressed(key, false),
      onPointerCancel: (_) => _setKeyPressed(key, false),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: pressed
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CustomPaint(
              painter: _ArrowPainter(direction, Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  /// Directional pad shown on small/touch screens, fixed to the viewport
  /// (outside the InteractiveViewer) so panning/zooming the space doesn't
  /// move the controls.
  Widget _buildMobileControls() {
    return Positioned(
      left: 24,
      bottom: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _controlButton(_ArrowDirection.up, LogicalKeyboardKey.arrowUp),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _controlButton(
                  _ArrowDirection.left, LogicalKeyboardKey.arrowLeft),
              const SizedBox(width: 64),
              _controlButton(
                  _ArrowDirection.right, LogicalKeyboardKey.arrowRight),
            ],
          ),
          const SizedBox(height: 8),
          _controlButton(_ArrowDirection.down, LogicalKeyboardKey.arrowDown),
        ],
      ),
    );
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
            child: Image.asset('assets/ships/ship${ship.shipType}.png',
                width: 50, height: 50),
          ),
          const SizedBox(height: 2),
          DefaultTextStyle(
            style: GoogleFonts.orbitron(
              color: const Color(0xFFFFFFFF),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
            child: Text(
              ship.name,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Phones and small tablets get on-screen d-pad controls instead of
    // relying on a hardware keyboard. shortestSide is orientation-agnostic.
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;

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
      child: Stack(children: [
        InteractiveViewer(
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
        if (isMobile) _buildMobileControls(),
      ]),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

enum _ArrowDirection { up, down, left, right }

/// Draws a filled triangle pointing in [direction]. Used for the mobile
/// d-pad instead of Icons.keyboard_arrow_* so the controls don't depend on
/// the MaterialIcons web font loading correctly.
class _ArrowPainter extends CustomPainter {
  final _ArrowDirection direction;
  final Color color;

  const _ArrowPainter(this.direction, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final path = Path();

    switch (direction) {
      case _ArrowDirection.up:
        path.moveTo(w / 2, 0);
        path.lineTo(w, h);
        path.lineTo(0, h);
      case _ArrowDirection.down:
        path.moveTo(0, 0);
        path.lineTo(w, 0);
        path.lineTo(w / 2, h);
      case _ArrowDirection.left:
        path.moveTo(w, 0);
        path.lineTo(w, h);
        path.lineTo(0, h / 2);
      case _ArrowDirection.right:
        path.moveTo(0, 0);
        path.lineTo(w, h / 2);
        path.lineTo(0, h);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.direction != direction || oldDelegate.color != color;
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
