import 'package:flutter/material.dart';
import '../models/gradient_color.dart';

class AppGradients {
  AppGradients._();
  static const List<GradientColor> allGradients = [
    purpleBlue,
    orangeYellow,
    iceBlue,
    pinkPurple,
    white,
    future,
    blood,
  ];

  static const GradientColor purpleBlue = GradientColor(
    start: Color.fromARGB(255, 220, 72, 109),
    end: Color.fromARGB(255, 1, 188, 216),
  );
  static const GradientColor orangeYellow = GradientColor(
    start: Color.fromARGB(255, 120, 20, 3),
    end: Color(0xFFFBBF24),
  );
  static const GradientColor iceBlue = GradientColor(
    start: Color.fromARGB(255, 9, 29, 110),
    end: Color.fromARGB(255, 83, 197, 250),
  );
  static const GradientColor pinkPurple = GradientColor(
    start: Color.fromARGB(255, 72, 49, 127),
    end: Color(0xFFEC4899),
  );
  static const GradientColor white = GradientColor(
    start: Color.fromARGB(255, 238, 214, 226),
    end: Color.fromARGB(255, 89, 89, 101),
  );
  static const GradientColor future = GradientColor(
    start: Color.fromARGB(255, 250, 7, 185),
    end: Color.fromARGB(204, 23, 46, 136),
  );
  static const GradientColor blood = GradientColor(
    start: Color.fromARGB(255, 94, 5, 5),
    end: Color.fromARGB(255, 242, 9, 9),
  );
}
