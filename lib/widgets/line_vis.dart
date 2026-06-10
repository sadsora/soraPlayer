import 'package:flutter/material.dart';
import '../models/fftframe.dart';

class LineVis extends CustomPainter {
  FftFrame? spec;
  Color? startColor;
  Color? endColor;
  LineVis(this.spec, this.startColor, this.endColor);

  @override
  void paint(Canvas canvas, Size size) {
    final bands = spec?.bands;
    if (bands == null) return;
    final bandWidth = size.width / bands.length;
    final halfH = size.height / 2;
    Rect full = Rect.fromLTWH(0, 0, size.width, size.height);
    final fullShader = LinearGradient(
      begin: AlignmentGeometry.centerLeft,
      end: AlignmentGeometry.centerRight,
      colors: [
        startColor!.withValues(alpha: 0.8),
        endColor!.withValues(alpha: 0.8),
      ],
    ).createShader(full);
    final barPaint = Paint()
      ..shader = fullShader
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.screen;

    final barPath = Path();
    final clipR = Radius.circular(bandWidth / 2);
    for (int i = 0; i < bands.length; i++) {
      final barHeight = bands[i] * size.height / 2.5;
      barPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * bandWidth,
            halfH - barHeight,
            bandWidth - 2,
            barHeight,
          ),
          clipR,
        ),
      );
    }
    canvas.drawPath(barPath, barPaint);
  }

  @override
  bool shouldRepaint(covariant LineVis old) =>
      old.spec != spec ||
      old.startColor != startColor ||
      old.endColor != endColor;
}
