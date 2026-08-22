import 'dart:math';
import 'package:flutter/material.dart';

/// Every selectable background texture id, for pickers/validation.
const List<String> kUiTextureIds = ['none', 'grid', 'noise', 'scanlines', 'paper'];

const Map<String, String> kUiTextureLabels = {
  'none': 'NONE',
  'grid': 'TECHNICAL GRID',
  'noise': 'SOFT GRAIN',
  'scanlines': 'SCANLINES',
  'paper': 'RULED PAPER',
};

/// Procedurally-drawn background texture, painted once behind a screen's
/// content (see MainScaffold). Generated instead of user-uploaded so there's
/// no asset/file-size/legibility risk - see PLAN discussion in PNDEV.
class UiTexture extends StatelessWidget {
  final String textureId;
  final double intensity; // 0..1
  final Color color;

  const UiTexture({super.key, required this.textureId, required this.intensity, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    if (textureId == 'none' || intensity <= 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _UiTexturePainter(textureId: textureId, intensity: intensity.clamp(0, 1), color: color),
        ),
      ),
    );
  }
}

class _UiTexturePainter extends CustomPainter {
  final String textureId;
  final double intensity;
  final Color color;

  _UiTexturePainter({required this.textureId, required this.intensity, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    switch (textureId) {
      case 'grid':
        _paintGrid(canvas, size);
        break;
      case 'noise':
        _paintNoise(canvas, size);
        break;
      case 'scanlines':
        _paintScanlines(canvas, size);
        break;
      case 'paper':
        _paintPaper(canvas, size);
        break;
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: intensity * 0.15)
      ..strokeWidth = 0.5;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintNoise(Canvas canvas, Size size) {
    // Deterministic seed so the texture doesn't flicker/redraw differently
    // on every rebuild.
    final rng = Random(42);
    final paint = Paint()..color = color.withValues(alpha: intensity * 0.5);
    final dotCount = (size.width * size.height / 900).round();
    for (int i = 0; i < dotCount; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.6, paint);
    }
  }

  void _paintScanlines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: intensity * 0.25)
      ..strokeWidth = 1;
    const step = 4.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintPaper(Canvas canvas, Size size) {
    // Ruled notebook lines, with a faint left margin rule like a physical
    // training journal page.
    final linePaint = Paint()
      ..color = color.withValues(alpha: intensity * 0.2)
      ..strokeWidth = 0.5;
    const step = 32.0;
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    final marginPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: intensity * 0.25)
      ..strokeWidth = 0.75;
    canvas.drawLine(const Offset(28, 0), Offset(28, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant _UiTexturePainter oldDelegate) =>
      oldDelegate.textureId != textureId || oldDelegate.intensity != intensity || oldDelegate.color != color;
}
