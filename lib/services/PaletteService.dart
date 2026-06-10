import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

class PaletteResult {
  final Color? vibrantColor;
  final Color? mutedColor;
  PaletteResult({this.vibrantColor, this.mutedColor});
}

class Paletteservice {
  static Future<ui.Image> decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  static Future<PaletteResult> extract(ui.Image image) async {
    final palette = await PaletteGeneratorMaster.fromImage(image);
    final dominant = palette.dominantColor?.color;
    final vibrantColor =
        palette.vibrantColor?.color ??
        palette.lightVibrantColor?.color ??
        palette.darkVibrantColor?.color ??
        dominant;
    final mutedColor =
        palette.mutedColor?.color ??
        palette.lightMutedColor?.color ??
        palette.darkMutedColor?.color ??
        dominant;
    return PaletteResult(vibrantColor: vibrantColor, mutedColor: mutedColor);
  }
}
