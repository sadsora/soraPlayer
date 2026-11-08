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

  /// 现场画一张纯色方图，作为“无封面 / 封面损坏”时的兜底图。
  /// 不依赖任何图片资源，所以不用往 pubspec 里加 assets。
  static Future<ui.Image> solidColorImage(
    Color color, {
    int size = 512,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final side = size.toDouble();
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, side, side),
      ui.Paint()..color = color,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    picture.dispose();
    return image;
  }

  /// 同上，但直接产出 PNG 字节，方便塞进 `Image.memory` / `MemoryImage`。
  static Future<Uint8List?> solidColorPng(
    Color color, {
    int size = 512,
  }) async {
    final image = await solidColorImage(color, size: size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return null;
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
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
