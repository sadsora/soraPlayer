import '../services/pcm_decoder_service.dart';
import 'package:fftea/fftea.dart';
import 'dart:math';
import 'dart:typed_data';
import '../models/fftdata.dart';
import '../models/fftframe.dart';

class FftConfig {
  final int windowSize;
  final int targetFps;
  final int numBands;
  const FftConfig({
    this.windowSize = 4096,
    this.targetFps = 120,
    this.numBands = 128,
  });
}

class FftAnalyzerService {
  final FftConfig config;

  FftAnalyzerService({this.config = const FftConfig()});
  static Future<FftData> computeFft(String filePath) async {
    final decoder = PCMDecoderService();
    final analyzer = FftAnalyzerService();
    final wav = await decoder.decode(filePath);
    return analyzer.analyze(wav);
  }

  FftData analyze(WavInfo wav) {
    final pcm = wav.pcmData;
    final sampleRate = wav.sampleRate;
    final hopSize = sampleRate ~/ config.targetFps;

    final fft = FFT(config.windowSize);
    final window = _hanningWindow(config.windowSize);
    final frames = <FftFrame>[];
    int offset = 0;
    while (offset + config.windowSize <= pcm.length) {
      final rawWindow = Float64List(config.windowSize);
      for (int i = 0; i < config.windowSize; i++) {
        rawWindow[i] = pcm[offset + i] * window[i];
      }
      final complex = fft.realFft(rawWindow);
      // 实信号的 FFT 具有共轭对称性，只有前 N/2+1 个 bin 是唯一的，
      // 后半部分是前半的镜像副本，必须截掉，否则高频段会混入低频能量。
      final uniqueBins = config.windowSize ~/ 2 + 1;
      final spectrum = Float64List(uniqueBins);
      for (int i = 0; i < uniqueBins; i++) {
        final re = complex[i].x;
        final im = complex[i].y;
        spectrum[i] = sqrt(re * re + im * im);
      }
      final bands = _mergeToLogBands(spectrum, sampleRate, config.windowSize);
      final mapped = bands.map((v) => _amplitudeMap(v)).toList();
      frames.add(FftFrame(mapped));
      offset += hopSize;
    }

    // 全局归一化：使用整首歌的最大值，保留动态范围
    double globalMax = 0;
    for (final frame in frames) {
      for (final v in frame.bands) {
        if (v > globalMax) globalMax = v;
      }
    }
    if (globalMax > 0) {
      for (final frame in frames) {
        for (int i = 0; i < frame.bands.length; i++) {
          frame.bands[i] /= globalMax;
        }
      }
    }

    return FftData(frames: frames, msPerFrame: hopSize / sampleRate * 1000.0);
  }

  Float64List _hanningWindow(int size) {
    final w = Float64List(size);
    for (int i = 0; i < size; i++) {
      w[i] = 0.5 * (1 - cos(2 * pi * i / (size - 1)));
    }
    return w;
  }

  double _amplitudeMap(double v) {
    return sqrt(v);
  }

  // 对数映射指数：<1 时低频段更宽、高频段更窄，视觉上频谱更均衡
  static const _logExponent = 2;

  List<double> _mergeToLogBands(
    Float64List spectrum,
    int sampleRate,
    int windowSize,
  ) {
    final numBins = spectrum.length;
    final nyquist = sampleRate / 2;
    final binWidth = sampleRate / windowSize;
    final result = Float64List(config.numBands);

    for (int b = 0; b < config.numBands; b++) {
      final t = b / (config.numBands - 1);
      final lowHz = (pow(t, _logExponent) * nyquist).toDouble();
      final highHz =
          (pow((b + 1) / (config.numBands - 1), _logExponent) * nyquist)
              .toDouble();

      final lowBin = (lowHz / binWidth).round().clamp(0, numBins - 1);
      final highBin = (highHz / binWidth).round().clamp(0, numBins - 1);
      double sumSq = 0;
      int count = 0;
      for (int i = lowBin; i <= highBin; i++) {
        sumSq += spectrum[i] * spectrum[i];
        count++;
      }
      result[b] = count > 0 ? sqrt(sumSq / count) : 0.0;

      // 频率补偿：抵消音频天然的 1/f 衰减，让高低频视觉均衡
      const gamma = 0.35;
      final centerHz = (lowHz + highHz) / 2;
      result[b] *= pow(centerHz / nyquist, gamma);
    }
    return result;
  }
}
