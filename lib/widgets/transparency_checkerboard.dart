import 'package:flutter/material.dart';

/// Grey/white checkerboard so a transparent PNG's alpha is visible, the way
/// design tools show transparency.
class TransparencyCheckerboard extends StatelessWidget {
  const TransparencyCheckerboard({
    super.key,
    required this.child,
    this.cellSize = 10,
  });

  final Widget child;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0D6EE)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _CheckerPainter(cellSize: cellSize)),
            child,
          ],
        ),
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  _CheckerPainter({required this.cellSize});

  final double cellSize;
  static const _light = Color(0xFFF4F2F8);
  static const _dark = Color(0xFFE5E0ED);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _light;
    canvas.drawRect(Offset.zero & size, paint);
    paint.color = _dark;
    final cols = (size.width / cellSize).ceil();
    final rows = (size.height / cellSize).ceil();
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if ((row + col).isEven) continue;
        canvas.drawRect(
          Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerPainter oldDelegate) =>
      oldDelegate.cellSize != cellSize;
}
