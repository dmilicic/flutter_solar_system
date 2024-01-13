import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:solar_system/painters/space_painter.dart';
import 'package:solar_system/providers/space_painter_provider.dart';

class SolarSystem extends StatefulWidget {
  const SolarSystem({super.key});

  @override
  State<SolarSystem> createState() => _SolarSystemState();
}

class _SolarSystemState extends State<SolarSystem> with SingleTickerProviderStateMixin {

  final dataProvider = SpacePainterProvider();

  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((elapsed) {
      setState(() {}); // trigger a repaint
    });

    _ticker.start();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return InteractiveViewer(
      clipBehavior: Clip.none,
      constrained: false,
      child: Stack(children: [
        Container(
          width: 2000,
          height: 2000,
          child: CustomPaint(
            painter: SpacePainter(dataProvider),
          ),
        ),

        // Image.asset("sun.gif", width: 100, height: 100, fit: BoxFit.cover),
      ]),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}