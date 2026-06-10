import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:soraplayer/services/pcm_decoder_service.dart';

final DynamicLibrary _lib = Platform.isAndroid
    ? DynamicLibrary.open('libmp3_decoder.so')
    : DynamicLibrary.open('mp3_decoder.dll');

typedef Mp3DecodeFileC =
    Int32 Function(
      Pointer<Utf8> path,
      Pointer<Pointer<Float>> out,
      Pointer<Int32> outSr,
      Pointer<Int32> outCh,
    );
typedef Mp3DecodeFileDart =
    int Function(
      Pointer<Utf8> path,
      Pointer<Pointer<Float>> out,
      Pointer<Int32> outSr,
      Pointer<Int32> outCh,
    );

typedef Mp3FreeC = Void Function(Pointer<Float>);
typedef Mp3FreeDart = void Function(Pointer<Float>);

final _decodeFile = _lib.lookupFunction<Mp3DecodeFileC, Mp3DecodeFileDart>(
  'mp3_decode_file',
);
final _free = _lib.lookupFunction<Mp3FreeC, Mp3FreeDart>('mp3_free');

WavInfo decodeMp3(String filePath) {
  final pathPtr = filePath.toNativeUtf8();
  final outPtr = calloc<Pointer<Float>>();
  final srPtr = calloc<Int32>();
  final chPtr = calloc<Int32>();
  final totalSamples = _decodeFile(pathPtr, outPtr, srPtr, chPtr);
  if (totalSamples < 0) {
    calloc.free(pathPtr);
    calloc.free(outPtr);
    calloc.free(srPtr);
    calloc.free(chPtr);
    throw Exception('MP3 解码失败');
  }
  final floatPtr = outPtr.value;
  final pcmFloat32 = floatPtr.asTypedList(totalSamples);
  final sampleRate = srPtr.value;
  final channels = chPtr.value;

  final Float64List monoSamples;
  if (channels == 2) {
    final monoLength = totalSamples ~/ 2;
    monoSamples = Float64List(monoLength);
    for (int i = 0; i < monoLength; i++) {
      monoSamples[i] = (pcmFloat32[i * 2] + pcmFloat32[i * 2 + 1]) / 2.0;
    }
  } else {
    monoSamples = Float64List.fromList(pcmFloat32);
  }

  _free(floatPtr);
  calloc.free(pathPtr);
  calloc.free(outPtr);
  calloc.free(srPtr);
  calloc.free(chPtr);
  return WavInfo(
    sampleRate: sampleRate,
    channels: channels,
    bitsPerSample: 32,
    pcmSamples: monoSamples,
  );
}
