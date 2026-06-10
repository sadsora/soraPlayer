import 'dart:ui' as ui;

import '../models/fftframe.dart';
import '../models/gradient_color.dart';
import 'package:flutter/material.dart';
import 'line_vis.dart';
import 'circle_vis.dart';
import 'radial_vis.dart';
import 'poly_vis.dart';

enum VisMode { line, circle, poly, radial }

CustomPainter createVisPainter({
  required VisMode mode,
  required FftFrame? spectrum,
  required GradientColor gradient,
  ui.Image? coverImg,
  double rotation = 0,
  double progress = 0,
}) {
  switch (mode) {
    case VisMode.line:
      return LineVis(spectrum, gradient.start, gradient.end);
    case VisMode.circle:
      return CircleVis(spectrum, coverImg, gradient.start, gradient.end);
    case VisMode.poly:
      return PolyVis(
        spectrum,
        coverImg,
        gradient.start,
        gradient.end,
        rotation,
        progress: progress,
      );
    case VisMode.radial:
      return Radial(
        spectrum,
        coverImg,
        gradient.start,
        gradient.end,
        rotation,
        progress: progress,
      );
  }
}
