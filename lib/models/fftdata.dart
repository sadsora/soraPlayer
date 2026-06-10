import 'fftframe.dart';

class FftData {
  final List<FftFrame> frames;
  final double msPerFrame;
  FftData({required this.frames, required this.msPerFrame});

  FftFrame? frameAt(int ms) {
    final idx = (ms / msPerFrame).round();
    if (idx < 0 || idx >= frames.length) return null;
    return frames[idx];
  }
}
