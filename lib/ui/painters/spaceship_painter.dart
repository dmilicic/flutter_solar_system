import 'dart:math';

import 'package:flutter/widgets.dart';

class SpaceshipPainter extends CustomPainter {

  late Color color;

  SpaceshipPainter({required this.color});


  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, 50)
      ..lineTo(50, 50)
      ..lineTo(50, 0)
      ..lineTo(0, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}