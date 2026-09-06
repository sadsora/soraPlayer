import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:soraplayer/services/pcm_decoder_service.dart';

final DynamicLibrary _lib = Platform.isAndroid
    ? DynamicLibrary.open('libflac_decoder.so')
    : DynamicLibrary.open('flac_decoder.dll');

typedef FlacDecodeFileC =
    Int32 Function(
      Pointer<Utf8> path,
      Pointer<Pointer<Float>> out,
      Pointer<Int32> outSr,
      Pointer<Int32> outCh,
    );
typedef FlacDecodeFileDart =
    int Function(
      Pointer<Utf8> path,
      Pointer<Pointer<Float>> out,
      Pointer<Int32> outSr,
      Pointer<Int32> outCh,
    );

typedef FlacFreeC = Void Function(Pointer<Float>);
typedef FlacFreeDart = void Function(Pointer<Float>);

final _decodeFile = _lib.lookupFunction<FlacDecodeFileC, FlacDecodeFileDart>(
  'flac_decode_file',
);
final _free = _lib.lookupFunction<FlacFreeC, FlacFreeDart>('flac_free');

WavInfo decodeFlac(String filePath) {
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
    throw Exception('FLAC 解码失败');
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
