import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:soraplayer/services/fft_analyzer_service.dart';
import 'package:soraplayer/services/pcm_decoder_service.dart';

void main() {
  test('FFT analysis produces correct number of frames', () {
    final wav = WavInfo(
      sampleRate: 44100,
      channels: 1,
      bitsPerSample: 16,
      pcmSamples: Float64List(44100), // 1 秒静音
    );
    final analyzer = FftAnalyzerService();
    final result = analyzer.analyze(wav);

    // windowSize=4096, targetFps=120, 每帧 128 bands
    expect(result.frames.length, closeTo(120, 5)); // 约 120 帧
    expect(result.frames.first.bands.length, 128);
  });

  test('FFT energy should be zero for silence', () {
    final wav = WavInfo(
      sampleRate: 44100,
      channels: 1,
      bitsPerSample: 16,
      pcmSamples: Float64List(44100),
    );
    final analyzer = FftAnalyzerService();
    final result = analyzer.analyze(wav);

    for (final frame in result.frames) {
      for (final band in frame.bands) {
        expect(band, lessThan(1e-10));
      }
    }
  });
}
