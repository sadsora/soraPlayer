import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/fftframe.dart';

class PolyVis extends CustomPainter {
  final FftFrame? spec;
  final Color? startColor;
  final Color? endColor;
  final ui.Image? image;
  final double rotation;
  final double progress;

  PolyVis(
    this.spec,
    this.image,
    this.startColor,
    this.endColor,
    this.rotation, {
    this.progress = 0.0,
  });

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final bands = spec?.bands;
    if (bands == null) return;
    final bandsNum = bands.length - 18;
    final center = Offset(size.width / 2, size.height / 2 - size.height / 10);
    final innerRadius = size.width / 6;
    final outerRadius = innerRadius + size.width / 100;
    final imgRadius = size.width / 8;
    final perAngle = 2 * pi / bandsNum;
    final midAngle = perAngle / 2;

    final sweepShader = ui.Gradient.sweep(
      center,
      [startColor!, endColor!, startColor!, endColor!],
      <double>[0.0, 0.25, 0.5, 0.75],
    );

    final brightPaint = Paint()
      ..shader = sweepShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square
      ..blendMode = BlendMode.screen;

    //Image
    final fadeShader = ui.Gradient.radial(
      center,
      imgRadius,
      [Colors.white, Colors.white.withValues(alpha: 0.0)],
      [0.3, 1.0],
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    final brightOuter = Path();
    final brightInner = Path();

    brightOuter.moveTo(center.dx + innerRadius, center.dy);
    brightInner.moveTo(center.dx + innerRadius, center.dy);

    for (int i = 0; i < bandsNum; i++) {
      final value = bands[i].clamp(0.0, 1.0);
      final rawAmp = outerRadius * ((value < 0.4) ? value / 4 : value / 3);

      final a = i * perAngle;

      brightOuter.lineTo(
        center.dx + (innerRadius + rawAmp) * cos(a + midAngle),
        center.dy + (innerRadius + rawAmp) * sin(a + midAngle),
      );
      brightInner.lineTo(
        center.dx + (innerRadius - rawAmp) * cos(a + midAngle),
        center.dy + (innerRadius - rawAmp) * sin(a + midAngle),
      );
    }

    brightOuter.close();
    brightInner.close();
    canvas.drawPath(brightOuter, brightPaint);
    canvas.drawPath(brightInner, brightPaint);

    canvas.restore();

    //封面图
    final coverBounds = Rect.fromCircle(center: center, radius: imgRadius);
    canvas.save();
    canvas.clipPath(Path()..addOval(coverBounds));

    canvas.saveLayer(coverBounds, Paint());

    canvas.drawCircle(center, imgRadius, Paint()..shader = fadeShader);

    final src = Rect.fromLTWH(
      0,
      0,
      image!.width.toDouble(),
      image!.height.toDouble(),
    );
    canvas.drawImageRect(
      image!,
      src,
      coverBounds,
      Paint()..blendMode = BlendMode.srcIn,
    );

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PolyVis old) =>
      old.spec != spec ||
      old.startColor != startColor ||
      old.endColor != endColor ||
      old.rotation != rotation ||
      old.progress != progress;
}
