import 'dart:math' as math;

import 'package:flutter/material.dart';

enum DrawingTool { pen, circle, rectangle, line, eraser }

class DrawingPoint {
  final Offset point;
  final Color color;
  final double strokeWidth;
  final DrawingTool tool;

  DrawingPoint({
    required this.point,
    required this.color,
    required this.strokeWidth,
    required this.tool,
  });
}

class DrawingScreen extends StatefulWidget {
  @override
  _DrawingScreenState createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  List<List<DrawingPoint?>> strokes = [];
  List<DrawingPoint?> currentStroke = [];
  List<List<List<DrawingPoint?>>> history = [];
  int historyIndex = -1;

  DrawingTool selectedTool = DrawingTool.pen;
  Color selectedColor = Colors.black;
  double strokeWidth = 3.0;

  Offset? startPoint;
  Offset? endPoint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Drawing Canvas'),
        actions: [
          // Undo button
          IconButton(
            onPressed: canUndo() ? undo : null,
            icon: Icon(Icons.undo),
            tooltip: 'Undo',
          ),
          // Redo button
          IconButton(
            onPressed: canRedo() ? redo : null,
            icon: Icon(Icons.redo),
            tooltip: 'Redo',
          ),
          // Save button
          IconButton(
            onPressed: saveDrawing,
            icon: Icon(Icons.save),
            tooltip: 'Save',
          ),
          // Load button
          IconButton(
            onPressed: loadDrawing,
            icon: Icon(Icons.folder_open),
            tooltip: 'Load',
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas area
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: DrawingPainter(
                    strokes: strokes,
                    currentStroke: currentStroke,
                    selectedTool: selectedTool,
                    startPoint: startPoint,
                    endPoint: endPoint,
                    selectedColor: selectedColor,
                    strokeWidth: strokeWidth,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          // Color picker at the bottom
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text('Colors: ', style: theme.textTheme.labelLarge),
                SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Basic colors
                        ...[
                          Colors.black,
                          Colors.red,
                          Colors.blue,
                          Colors.green,
                          Colors.yellow,
                          Colors.orange,
                          Colors.purple,
                          Colors.pink,
                          Colors.brown,
                          Colors.grey,
                        ].map((color) => _buildColorButton(color)).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Tool selection floating action button
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "pen",
            onPressed: () => _selectTool(DrawingTool.pen),
            backgroundColor: selectedTool == DrawingTool.pen
                ? colorScheme.primary
                : colorScheme.surface,
            child: Icon(
              Icons.brush,
              color: selectedTool == DrawingTool.pen
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "circle",
            onPressed: () => _selectTool(DrawingTool.circle),
            backgroundColor: selectedTool == DrawingTool.circle
                ? colorScheme.primary
                : colorScheme.surface,
            child: Icon(
              Icons.circle_outlined,
              color: selectedTool == DrawingTool.circle
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "rectangle",
            onPressed: () => _selectTool(DrawingTool.rectangle),
            backgroundColor: selectedTool == DrawingTool.rectangle
                ? colorScheme.primary
                : colorScheme.surface,
            child: Icon(
              Icons.crop_square,
              color: selectedTool == DrawingTool.rectangle
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "line",
            onPressed: () => _selectTool(DrawingTool.line),
            backgroundColor: selectedTool == DrawingTool.line
                ? colorScheme.primary
                : colorScheme.surface,
            child: Icon(
              Icons.remove,
              color: selectedTool == DrawingTool.line
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "eraser",
            onPressed: () => _selectTool(DrawingTool.eraser),
            backgroundColor: selectedTool == DrawingTool.eraser
                ? colorScheme.primary
                : colorScheme.surface,
            child: Icon(
              Icons.auto_fix_high,
              color: selectedTool == DrawingTool.eraser
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () => _selectColor(color),
      child: Container(
        width: 40,
        height: 40,
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            width: selectedColor == color ? 3 : 1,
          ),
        ),
      ),
    );
  }

  void _selectTool(DrawingTool tool) {
    setState(() {
      selectedTool = tool;
    });
  }

  void _selectColor(Color color) {
    setState(() {
      selectedColor = color;
    });
  }

  void _onPanStart(DragStartDetails details) {
    _saveToHistory();
    startPoint = details.localPosition;

    if (selectedTool == DrawingTool.pen || selectedTool == DrawingTool.eraser) {
      currentStroke = [];
      _addPointToCurrentStroke(details.localPosition);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (selectedTool == DrawingTool.pen || selectedTool == DrawingTool.eraser) {
        _addPointToCurrentStroke(details.localPosition);
      } else {
        endPoint = details.localPosition;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      if (selectedTool == DrawingTool.pen || selectedTool == DrawingTool.eraser) {
        currentStroke.add(null); // End stroke marker
        strokes.add(List.from(currentStroke));
        currentStroke.clear();
      } else if (startPoint != null && endPoint != null) {
        // Add shape to strokes
        _addShape(startPoint!, endPoint!);
      }
      startPoint = null;
      endPoint = null;
    });
  }

  void _addPointToCurrentStroke(Offset point) {
    currentStroke.add(DrawingPoint(
      point: point,
      color: selectedTool == DrawingTool.eraser ? Colors.white : selectedColor,
      strokeWidth: strokeWidth,
      tool: selectedTool,
    ));
  }

  void _addShape(Offset start, Offset end) {
    List<DrawingPoint?> shape = [];

    switch (selectedTool) {
      case DrawingTool.line:
        shape.add(DrawingPoint(
          point: start,
          color: selectedColor,
          strokeWidth: strokeWidth,
          tool: selectedTool,
        ));
        shape.add(DrawingPoint(
          point: end,
          color: selectedColor,
          strokeWidth: strokeWidth,
          tool: selectedTool,
        ));
        break;
      case DrawingTool.circle:
      case DrawingTool.rectangle:
        // Create multiple points to form the shape
        shape = _createShapePoints(start, end, selectedTool);
        break;
      default:
        break;
    }

    if (shape.isNotEmpty) {
      shape.add(null); // End stroke marker
      strokes.add(shape);
    }
  }

  List<DrawingPoint?> _createShapePoints(Offset start, Offset end, DrawingTool tool) {
    List<DrawingPoint?> points = [];

    if (tool == DrawingTool.rectangle) {
      // Create rectangle points
      points.add(DrawingPoint(point: start, color: selectedColor, strokeWidth: strokeWidth, tool: tool));
      points.add(DrawingPoint(point: Offset(end.dx, start.dy), color: selectedColor, strokeWidth: strokeWidth, tool: tool));
      points.add(DrawingPoint(point: end, color: selectedColor, strokeWidth: strokeWidth, tool: tool));
      points.add(DrawingPoint(point: Offset(start.dx, end.dy), color: selectedColor, strokeWidth: strokeWidth, tool: tool));
      points.add(DrawingPoint(point: start, color: selectedColor, strokeWidth: strokeWidth, tool: tool));
    } else if (tool == DrawingTool.circle) {
      // Create circle points
      final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      final radius = (end - start).distance / 2;

      for (int i = 0; i <= 360; i += 5) {
        final angle = i * 3.14159 / 180;
        final x = center.dx + radius * math.cos(angle);
        final y = center.dy + radius * math.sin(angle);
        points.add(DrawingPoint(
          point: Offset(x, y),
          color: selectedColor,
          strokeWidth: strokeWidth,
          tool: tool,
        ));
      }
    }

    return points;
  }

  void _saveToHistory() {
    if (historyIndex < history.length - 1) {
      history = history.sublist(0, historyIndex + 1);
    }
    history.add(strokes.map((stroke) => List<DrawingPoint?>.from(stroke)).toList());
    historyIndex++;

    // Limit history size
    if (history.length > 50) {
      history.removeAt(0);
      historyIndex--;
    }
  }

  bool canUndo() => historyIndex > 0;
  bool canRedo() => historyIndex < history.length - 1;

  void undo() {
    if (canUndo()) {
      setState(() {
        historyIndex--;
        strokes = history[historyIndex].map((stroke) => List<DrawingPoint?>.from(stroke)).toList();
      });
    }
  }

  void redo() {
    if (canRedo()) {
      setState(() {
        historyIndex++;
        strokes = history[historyIndex].map((stroke) => List<DrawingPoint?>.from(stroke)).toList();
      });
    }
  }

  void saveDrawing() {
    // TODO: Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Save functionality to be implemented')),
    );
  }

  void loadDrawing() {
    // TODO: Implement load functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Load functionality to be implemented')),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<List<DrawingPoint?>> strokes;
  final List<DrawingPoint?> currentStroke;
  final DrawingTool selectedTool;
  final Offset? startPoint;
  final Offset? endPoint;
  final Color selectedColor;
  final double strokeWidth;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    required this.selectedTool,
    this.startPoint,
    this.endPoint,
    required this.selectedColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (var stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw current stroke (for pen and eraser)
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke);
    }

    // Draw preview for shapes
    if (startPoint != null && endPoint != null &&
        (selectedTool == DrawingTool.line ||
         selectedTool == DrawingTool.circle ||
         selectedTool == DrawingTool.rectangle)) {
      _drawPreview(canvas);
    }
  }

  void _drawStroke(Canvas canvas, List<DrawingPoint?> stroke) {
    for (int i = 0; i < stroke.length - 1; i++) {
      if (stroke[i] != null && stroke[i + 1] != null) {
        final point1 = stroke[i]!;
        final point2 = stroke[i + 1]!;

        final paint = Paint()
          ..color = point1.color
          ..strokeWidth = point1.strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(point1.point, point2.point, paint);
      }
    }
  }

  void _drawPreview(Canvas canvas) {
    final paint = Paint()
      ..color = selectedColor.withOpacity(0.5)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (selectedTool) {
      case DrawingTool.line:
        canvas.drawLine(startPoint!, endPoint!, paint);
        break;
      case DrawingTool.rectangle:
        final rect = Rect.fromPoints(startPoint!, endPoint!);
        canvas.drawRect(rect, paint);
        break;
      case DrawingTool.circle:
        final center = Offset((startPoint!.dx + endPoint!.dx) / 2, (startPoint!.dy + endPoint!.dy) / 2);
        final radius = (endPoint! - startPoint!).distance / 2;
        canvas.drawCircle(center, radius, paint);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}