import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../providers/space_painter_provider.dart';

class SpacePainter extends CustomPainter {

  final SpacePainterProvider provider;

  SpacePainter(this.provider);

  final starRadius = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(backgroundRect, provider.provideSpacePaint());

    paintStars(canvas, size);
  }

  void paintStars(Canvas canvas, Size size) {
    final stars = provider.provideStars();
    final path = Path(); // we want to batch the circle draw calls for more performance

    for (var starPosition in stars) {
      final position = starPosition * size.width;
      final rect = Rect.fromCircle(center: position, radius: starRadius);
      path.addOval(rect);
    }

    canvas.drawPath(path, provider.provideStarPaint());
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
