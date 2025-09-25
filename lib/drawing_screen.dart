import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

enum DrawingTool { pen, circle, rectangle, line, eraser, bucket }

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

  bool _isProcessingFloodFill = false;

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
                onTapUp: selectedTool == DrawingTool.bucket ? _onTap : null,
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
          // Processing indicator
          if (_isProcessingFloodFill)
            Container(
              padding: EdgeInsets.all(8),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Filling area...', style: theme.textTheme.bodySmall),
                ],
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
                  color: Colors.black.withValues(alpha: 0.1),
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
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "bucket",
            onPressed: () => _selectTool(DrawingTool.bucket),
            backgroundColor: selectedTool == DrawingTool.bucket
                ? colorScheme.primary
                : colorScheme.surface,
            child: Icon(
              Icons.format_color_fill,
              color: selectedTool == DrawingTool.bucket
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

  void _onTap(TapUpDetails details) {
    if (selectedTool == DrawingTool.bucket) {
      _performFloodFill(details.localPosition);
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (selectedTool == DrawingTool.bucket) return; // Bucket tool uses tap, not drag

    _saveToHistory();
    startPoint = details.localPosition;

    if (selectedTool == DrawingTool.pen || selectedTool == DrawingTool.eraser) {
      currentStroke = [];
      _addPointToCurrentStroke(details.localPosition);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (selectedTool == DrawingTool.bucket) return; // Bucket tool uses tap, not drag

    setState(() {
      if (selectedTool == DrawingTool.pen || selectedTool == DrawingTool.eraser) {
        _addPointToCurrentStroke(details.localPosition);
      } else {
        endPoint = details.localPosition;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (selectedTool == DrawingTool.bucket) return; // Bucket tool uses tap, not drag

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

  // Flood fill implementation
  Future<void> _performFloodFill(Offset tapPosition) async {
    if (_isProcessingFloodFill) return;

    setState(() {
      _isProcessingFloodFill = true;
    });

    try {
      // Get the canvas size from the render box
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final size = renderBox.size;
      final canvasWidth = size.width.toInt();
      final canvasHeight = size.height.toInt();

      // Create a bitmap representation of the current drawing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      // Draw all existing strokes
      final painter = DrawingPainter(
        strokes: strokes,
        currentStroke: [],
        selectedTool: selectedTool,
        selectedColor: selectedColor,
        strokeWidth: strokeWidth,
      );
      painter.paint(canvas, size);

      // Convert to image and get pixel data
      final picture = recorder.endRecording();
      final image = await picture.toImage(canvasWidth, canvasHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData == null) return;

      final pixels = byteData.buffer.asUint8List();
      final startX = tapPosition.dx.toInt().clamp(0, canvasWidth - 1);
      final startY = tapPosition.dy.toInt().clamp(0, canvasHeight - 1);

      // Get the target color (color to replace)
      final targetColor = _getPixelColor(pixels, startX, startY, canvasWidth);

      // Check if target color is same as fill color
      if (_colorsEqual(targetColor, selectedColor)) {
        return; // Already the same color
      }

      _saveToHistory();

      // Perform flood fill with improved algorithm
      final filledPixels = await _improvedFloodFill(
        pixels,
        canvasWidth,
        canvasHeight,
        startX,
        startY,
        targetColor,
        selectedColor
      );

      // Convert filled pixels to drawing points
      if (filledPixels.isNotEmpty) {
        final filledStroke = <DrawingPoint?>[];

        for (final pixel in filledPixels) {
          filledStroke.add(DrawingPoint(
            point: Offset(pixel.dx, pixel.dy),
            color: selectedColor,
            strokeWidth: 1.0,
            tool: DrawingTool.bucket,
          ));
        }

        filledStroke.add(null); // End stroke marker

        setState(() {
          strokes.add(filledStroke);
        });
      }
    } finally {
      setState(() {
        _isProcessingFloodFill = false;
      });
    }
  }

  Color _getPixelColor(Uint8List pixels, int x, int y, int width) {
    final index = (y * width + x) * 4;
    if (index + 3 >= pixels.length) return Colors.transparent;

    return Color.fromARGB(
      pixels[index + 3], // alpha
      pixels[index],     // red
      pixels[index + 1], // green
      pixels[index + 2], // blue
    );
  }

  bool _colorsEqual(Color a, Color b) {
    // Use tolerance for anti-aliased edges
    const tolerance = 30;
    final aRed = (a.r * 255.0).round() & 0xff;
    final aGreen = (a.g * 255.0).round() & 0xff;
    final aBlue = (a.b * 255.0).round() & 0xff;

    final bRed = (b.r * 255.0).round() & 0xff;
    final bGreen = (b.g * 255.0).round() & 0xff;
    final bBlue = (b.b * 255.0).round() & 0xff;

    return (aRed - bRed).abs() <= tolerance &&
           (aGreen - bGreen).abs() <= tolerance &&
           (aBlue - bBlue).abs() <= tolerance;
  }

  Future<List<Offset>> _improvedFloodFill(
    Uint8List pixels,
    int width,
    int height,
    int startX,
    int startY,
    Color targetColor,
    Color fillColor,
  ) async {
    final filledPixels = <Offset>[];
    final visited = <String>{};
    final queue = <Offset>[Offset(startX.toDouble(), startY.toDouble())];

    // Use scanline flood fill algorithm for better performance
    while (queue.isNotEmpty && filledPixels.length < 50000) {
      final current = queue.removeAt(0);
      final x = current.dx.toInt();
      final y = current.dy.toInt();

      if (x < 0 || x >= width || y < 0 || y >= height) continue;

      final key = '$x,$y';
      if (visited.contains(key)) continue;

      final currentColor = _getPixelColor(pixels, x, y, width);
      if (!_colorsEqual(currentColor, targetColor)) continue;

      visited.add(key);

      // Fill the current scanline
      int leftX = x;
      int rightX = x;

      // Extend to the left
      while (leftX > 0) {
        final leftColor = _getPixelColor(pixels, leftX - 1, y, width);
        if (!_colorsEqual(leftColor, targetColor)) break;
        leftX--;
      }

      // Extend to the right
      while (rightX < width - 1) {
        final rightColor = _getPixelColor(pixels, rightX + 1, y, width);
        if (!_colorsEqual(rightColor, targetColor)) break;
        rightX++;
      }

      // Fill the scanline
      for (int fillX = leftX; fillX <= rightX; fillX++) {
        final fillKey = '$fillX,$y';
        if (!visited.contains(fillKey)) {
          visited.add(fillKey);
          filledPixels.add(Offset(fillX.toDouble(), y.toDouble()));

          // Add pixels above and below to queue
          if (y > 0) {
            final aboveColor = _getPixelColor(pixels, fillX, y - 1, width);
            if (_colorsEqual(aboveColor, targetColor)) {
              queue.add(Offset(fillX.toDouble(), (y - 1).toDouble()));
            }
          }
          if (y < height - 1) {
            final belowColor = _getPixelColor(pixels, fillX, y + 1, width);
            if (_colorsEqual(belowColor, targetColor)) {
              queue.add(Offset(fillX.toDouble(), (y + 1).toDouble()));
            }
          }
        }
      }
    }

    return filledPixels;
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
      ..color = selectedColor.withValues(alpha: 0.5)
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