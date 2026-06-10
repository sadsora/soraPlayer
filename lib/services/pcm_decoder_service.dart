import 'dart:typed_data';
import 'dart:io';
import 'mp3_decoder_ffi.dart';

class WavInfo {
  final int sampleRate;
  final int channels;
  final int bitsPerSample;
  final Float64List pcmSamples;

  WavInfo({
    required this.sampleRate,
    required this.channels,
    required this.bitsPerSample,
    required this.pcmSamples,
  });

  Float64List get pcmData => pcmSamples;
  int get sampleCount => pcmSamples.length;
}

class PCMDecoderService {
  Future<WavInfo> decode(String filePath) async {
    final ext = filePath.split('.').last.toLowerCase();
    if (ext != 'wav' && ext != 'wave') {
      if (ext == 'mp3') {
        return decodeMp3(filePath);
      }
    }
    return decodeWav(filePath);
  }

  Future<WavInfo> decodeWav(String filePath) async {
    final file = File(filePath);
    final raf = await file.open(mode: FileMode.read);

    try {
      final header = await raf.read(44);
      final data = ByteData.view(header.buffer);

      if (data.getUint8(0) != 0x52 || // R
          data.getUint8(1) != 0x49 || // I
          data.getUint8(2) != 0x46 || // F
          data.getUint8(3) != 0x46) {
        // F
        throw FormatException('不是有效的 WAV 文件');
      }

      final channels = data.getUint16(22, Endian.little);
      final sampleRate = data.getUint32(24, Endian.little);
      final bitsPerSample = data.getUint16(34, Endian.little);
      final dataSize = data.getUint32(40, Endian.little);

      final rawBytes = await raf.read(dataSize);
      final allSamples = _bytesToNormalizedFloats(rawBytes, bitsPerSample);
      final monoSamples = channels == 2
          ? _stereoToMono(allSamples)
          : allSamples;

      return WavInfo(
        sampleRate: sampleRate,
        channels: channels,
        bitsPerSample: bitsPerSample,
        pcmSamples: monoSamples,
      );
    } finally {
      await raf.close();
    }
  }

  // 字节 → 归一化 Float64List（-1.0 ~ 1.0）
  Float64List _bytesToNormalizedFloats(Uint8List bytes, int bitsPerSample) {
    final byteData = ByteData.view(bytes.buffer);
    final bytesPerSample = bitsPerSample ~/ 8;
    final sampleCount = bytes.length ~/ bytesPerSample;
    final result = Float64List(sampleCount);

    for (int i = 0; i < sampleCount; i++) {
      final offset = i * bytesPerSample;
      int rawValue;

      switch (bitsPerSample) {
        case 8:
          rawValue = bytes[offset] - 128;
          result[i] = rawValue / 128.0;
          break;
        case 16:
          rawValue = byteData.getInt16(offset, Endian.little);
          result[i] = rawValue / 32768.0;
          break;
        case 24:
          final b0 = bytes[offset];
          final b1 = bytes[offset + 1];
          final b2 = bytes[offset + 2];
          rawValue = b0 | (b1 << 8) | (b2 << 16);
          if (b2 & 0x80 != 0) rawValue |= 0xFF000000;
          result[i] = rawValue / 8388608.0;
          break;
        case 32:
          rawValue = byteData.getInt32(offset, Endian.little);
          result[i] = rawValue / 2147483648.0;
          break;
        default:
          throw UnsupportedError('不支持的位深: $bitsPerSample');
      }
    }

    return result;
  }

  // 立体声 → 单声道：左右声道取均值
  Float64List _stereoToMono(Float64List stereoSamples) {
    final monoLength = stereoSamples.length ~/ 2;
    final result = Float64List(monoLength);
    for (int i = 0; i < monoLength; i++) {
      result[i] = (stereoSamples[i * 2] + stereoSamples[i * 2 + 1]) / 2.0;
    }
    return result;
  }
}
