import 'package:flutter/material.dart';

class DrawingScreen extends StatefulWidget {
  @override
  _DrawingScreenState createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  List<Offset?> points = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Drawing Canvas'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Container(
        color: theme.colorScheme.background,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              RenderBox? box = context.findRenderObject() as RenderBox?;
              points.add(box?.globalToLocal(details.globalPosition));
            });
          },
          onPanEnd: (details) => points.add(null),
          child: CustomPaint(
            painter: _DrawingPainter(points, theme.colorScheme.onBackground),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color strokeColor;

  _DrawingPainter(this.points, this.strokeColor);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) => true;
}