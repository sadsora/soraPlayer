import 'dart:math';
import 'dart:typed_data';
import 'package:soraplayer/services/pcm_decoder_service.dart';
import 'package:soraplayer/services/fft_analyzer_service.dart';

void main() {
  // ---- 1. 生成 440Hz 正弦波（A4 音），时长 2 秒 ----
  const sampleRate = 44100;
  const durationSec = 2;
  const freq = 440.0; // 预期 FFT 峰值应该出现在 ≈440Hz 附近
  final pcm = Float64List(sampleRate * durationSec);

  for (int i = 0; i < pcm.length; i++) {
    final t = i / sampleRate; // 时间（秒）
    pcm[i] = sin(2 * pi * freq * t); // 纯正弦波
  }

  // ---- 2. 包成 WavInfo（假装是解码出来的 PCM） ----
  final wav = WavInfo(
    sampleRate: sampleRate,
    channels: 1,
    bitsPerSample: 16,
    pcmSamples: pcm,
  );

  // ---- 3. 跑 FFT 分析 ----
  final analyzer = FftAnalyzerService(
    config: const FftConfig(windowSize: 1024, targetFps: 30, numBands: 32),
  );
  final fftData = analyzer.analyze(wav);

  // ---- 4. 验证 ----
  print('总帧数: ${fftData.frames.length}');
  print('每帧间隔: ${fftData.msPerFrame.toStringAsFixed(1)} ms');

  // 取第一帧看频段分布
  final firstFrame = fftData.frames.first;
  print('\n第一帧频谱（${firstFrame.bands.length} 个频段）:');
  for (int i = 0; i < firstFrame.bands.length; i++) {
    final bar = '█' * (firstFrame.bands[i] * 40).round(); // 简易柱状图
    print(
      '  band ${i.toString().padLeft(2)}: $bar (${firstFrame.bands[i].toStringAsFixed(3)})',
    );
  }

  // 预期：低频段（band 0~3 左右）应该有明显峰值，因为 440Hz 在低频区
  // 高频段幅值应该接近于 0
  print('\n✅ 如果低频段有明显的柱子、高频段接近 0，说明 FFT 工作正常');
}
