import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/fftframe.dart';

class CircleVis extends CustomPainter {
  FftFrame? spec;
  ui.Image? image;
  Color? startColor;
  Color? endColor;
  CircleVis(this.spec, this.image, this.startColor, this.endColor);

  Rect? _cachedOvalRect;
  Path? _cachedOvalPath;

  @override
  void paint(Canvas canvas, Size size) {
    //print("V:${vibrantColor},M:${mutedColor}");
    // if (Platform.isAndroid) {
    //   final scale = (size.width / 1920).clamp(0.5, 2.0);
    //   canvas.scale(1 / scale);
    // }
    if (spec == null) return;
    final bands = spec!.bands;
    final innerRadius = size.height * 0.15;
    final outerRadius = innerRadius + size.width / 50;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final c = Offset(centerX, centerY);
    final sweepShader = ui.Gradient.sweep(
      c,
      [startColor!, endColor!, startColor!],
      <double>[0.0, 0.5, 1.0],
    );
    final gradient = Paint()
      ..shader = sweepShader
      ..style = PaintingStyle.fill;
    final barPath = Path();
    final perAngle = 2 * pi / bands.length;
    for (int i = 0; i < bands.length; i++) {
      final value = bands[i].clamp(0.0, 1.0);
      final currentOuterRadius =
          innerRadius + outerRadius * ((value < 0.4) ? value / 4 : value / 3);

      final startAngle = i * perAngle;
      final sweepAngle = perAngle - 0.005;
      barPath.addPath(
        _createSegmentPath(
          c,
          innerRadius,
          currentOuterRadius,
          startAngle,
          sweepAngle,
        ),
        Offset.zero,
      );
    }
    canvas.drawPath(barPath, gradient);
    if (image != null) {
      final ovalRect = Rect.fromCircle(center: c, radius: innerRadius);
      if (_cachedOvalRect != ovalRect) {
        _cachedOvalRect = ovalRect;
        _cachedOvalPath = Path()..addOval(ovalRect);
      }

      final imageSize = ui.Size(
        image!.width.toDouble(),
        image!.height.toDouble(),
      );
      final circleDiameter = innerRadius * 2;
      final scale = max(
        circleDiameter / imageSize.width,
        circleDiameter / imageSize.height,
      );
      final drawWidth = imageSize.width * scale;
      final drawHeight = imageSize.height * scale;
      final dstRect = Rect.fromCenter(
        center: c,
        width: drawWidth,
        height: drawHeight,
      );
      final srcRect = Rect.fromLTWH(0, 0, imageSize.width, imageSize.height);

      canvas.save();
      canvas.clipPath(_cachedOvalPath!);
      canvas.drawImageRect(image!, srcRect, dstRect, Paint());
      canvas.restore();
    }
  }

  Path _createSegmentPath(
    Offset center,
    double innerRadius,
    double outerRadius,
    double startAngle,
    double sweepAngle,
  ) {
    final path = Path();
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);

    path.moveTo(
      center.dx + outerRadius * cos(startAngle),
      center.dy + outerRadius * sin(startAngle),
    );
    //外圆弧
    path.arcTo(outerRect, startAngle, sweepAngle, false);

    //连接到内圆弧终点
    final endX = center.dx + innerRadius * cos(startAngle + sweepAngle);
    final endY = center.dy + innerRadius * sin(startAngle + sweepAngle);
    path.lineTo(endX, endY);

    //内圆弧
    path.arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false);

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CircleVis old) =>
      old.spec != spec ||
      old.image != image ||
      old.startColor != startColor ||
      old.endColor != endColor;
}
