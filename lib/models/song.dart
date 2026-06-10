import 'dart:typed_data';
import 'fftdata.dart';

class Song {
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final Uint8List? cover;
  FftData? fftData;

  // FftFrame? currentSpectrum(int idx) {
  //   if (fftData == null) return null;
  //   return fftData!.frameAt(idx);
  // }

  Song({
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    required this.cover,
  });
}
