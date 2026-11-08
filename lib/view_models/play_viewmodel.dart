import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:soraplayer/models/gradient_color.dart';
import '../models/song.dart';
import '../models/fftframe.dart';
import '../services/audio_reader_service.dart';
import '../services/audio_metadata_reader.dart';
import '../services/fft_analyzer_service.dart';
import 'dart:ui' as ui;
import '../constants/app_gradients.dart';
import 'dart:isolate';
import '../models/loop_mode.dart';
import '../services/PaletteService.dart';

class PlayViewmodel extends ChangeNotifier {
  static final PlayViewmodel instance = PlayViewmodel._();
  PlayViewmodel._() {
    _audioService.onCompleted.listen((isCompleted) {
      if (isCompleted) {
        if (_loopMode == LoopMode.one) {
          _audioService.playAudio(playlist[_currentIndex]);
        } else {
          playNext();
        }
      }
    });
    _audioService.onPosition.listen((Duration position) {
      _currentTime = position.inMilliseconds;
      notifyListeners();
    });
    _audioService.onDuration.listen((Duration d) {
      _duration = d.inMilliseconds;
      notifyListeners();
    });
    _audioService.onPlaying.listen((playing) {
      if (playing) {
        isPlaying = true;
        print("[isPlaying changing]:$isPlaying");
      } else {
        isPlaying = false;
        print("[isPlaying changing]:$isPlaying");
      }
      notifyListeners();
    });
  }

  final AudioReaderService _audioService = AudioReaderService.instance;
  final Color _bgColor = const Color.fromARGB(255, 255, 255, 255);
  Color get bgColor => _bgColor;
  Color? vibrantColor;
  Color? mutedColor;
  GradientColor currColor = AppGradients.allGradients[3];
  int gradintIdx = 3;
  int _currentIndex = -1;
  LoopMode _loopMode = LoopMode.all;
  ui.Image? coverImg;

  List<Song> playlist = [];
  int _currentTime = 0;
  int _duration = 0;
  FftFrame? get spectrum {
    if (_currentIndex < 0 || _currentTime < 0) return null;
    return playlist[_currentIndex].fftData?.frameAt(_currentTime);
  }

  String title = "";
  String artist = "";
  String album = "";
  Uint8List? cover;
  bool isPlaying = false;
  LoopMode get loopMode => _loopMode;
  int get currentTime => _currentTime;
  int get duration => _duration;

  double? get progress {
    if (_duration == 0) return null;
    return _currentTime / _duration;
  }

  Future<void> setSong(Song song) async {
    final index = playlist.indexWhere((s) => s.filePath == song.filePath);
    if (index < 0) return;
    _currentIndex = index;
    title = song.title;
    artist = song.artist;
    album = song.album;
    cover = song.cover;
    await _audioService.playAudio(song);
    // 先把解码派发出去，封面缺失/损坏不再阻断 FFT/PCM 这条链
    _loadFftDataInBackground(song);
    await _applyCoverArt();
    notifyListeners();
  }

  /// 无封面或封面无法解码时使用的淡色底图颜色。
  /// 取接近页面背景的浅灰蓝，改这一处即可换颜色。
  static const Color _fallbackCoverColor = Color(0xFFF2F3F5);

  /// 兜底纯色图的 PNG 字节，只生成一次
  static Uint8List? _fallbackCoverBytes;

  /// 解析封面并取色；封面缺失或损坏时退化为一张纯色图。
  Future<void> _applyCoverArt() async {
    ui.Image? image;
    Color? vibrant;
    Color? muted;

    final bytes = cover;
    if (bytes != null) {
      try {
        image = await Paletteservice.decodeImage(bytes);
        final palette = await Paletteservice.extract(image);
        vibrant = palette.vibrantColor;
        muted = palette.mutedColor;
      } catch (e) {
        debugPrint('封面解析失败，使用淡色底图兜底: $e');
        image = null;
      }
    }

    if (image == null) {
      // 现场生成纯色图，不需要任何资源文件
      image = await Paletteservice.solidColorImage(_fallbackCoverColor);
      vibrant ??= _fallbackCoverColor;
      muted ??= _fallbackCoverColor;
      // 让圆形封面、可视化页的模糊背景也用同一张纯色图，而不是音符占位
      cover = _fallbackCoverBytes ??=
          await Paletteservice.solidColorPng(_fallbackCoverColor);
    }

    coverImg = image;
    vibrantColor = vibrant;
    mutedColor = muted;
  }

  Future<void> removeSong(Song song) async {
    await _audioService.stop();
    playlist.removeWhere((s) => s.filePath == song.filePath);
    _currentIndex = -1;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_currentIndex < 0) return;

    await _audioService.resume();
    print("[resume] isPlaying:$isPlaying");
    notifyListeners();
  }

  Future<void> pause() async {
    if (_currentIndex < 0) return;
    await _audioService.fadeOutAndPause();
    print("[pause] isPlaying:$isPlaying");
    notifyListeners();
  }

  Future<void> seek(int pos) async {
    if (_currentIndex < 0) return;
    await _audioService.seek(pos);
    notifyListeners();
  }

  Future<void> stop() async {
    await _audioService.stop();
    _currentIndex = -1;
    print("[stop] isPlaying:$isPlaying");
    notifyListeners();
  }

  Future<void> _loadFftDataInBackground(Song song) async {
    if (song.fftData != null) return;
    try {
      final filePath = song.filePath;
      song.fftData = await Isolate.run(
        () => FftAnalyzerService.computeFft(filePath),
      );
      print('FFT done ${song.fftData?.frames.length}');
      notifyListeners();
    } catch (e) {
      print('FFT计算失败');
    }
  }

  Future<void> playNext() async {
    if (playlist.isEmpty) return;
    if (_currentIndex < 0) return;
    _currentIndex = (_currentIndex + 1) >= playlist.length
        ? 0
        : _currentIndex + 1;
    final song = playlist[_currentIndex];
    title = song.title;
    artist = song.artist;
    album = song.album;
    cover = song.cover;
    await _audioService.playAudioWithFadeIn(song);
    _loadFftDataInBackground(song);
    await _applyCoverArt();
    notifyListeners();
  }

  Future<void> playLast() async {
    if (playlist.isEmpty) return;
    if (_currentIndex < 0) return;
    _currentIndex = (_currentIndex - 1) == -1
        ? playlist.length - 1
        : _currentIndex - 1;
    final song = playlist[_currentIndex];
    title = song.title;
    artist = song.artist;
    album = song.album;
    cover = song.cover;
    await _audioService.playAudio(song);
    _loadFftDataInBackground(song);
    await _applyCoverArt();
    notifyListeners();
  }

  Future<void> addFromPaths(List<String> paths) async {
    for (final path in paths) {
      final song = await AudioMetadataReader.readMetadata(path);
      if (song != null) {
        playlist.add(song);
      }
    }
    notifyListeners();
  }

  Future<void> setLoopMode() async {
    switch (_loopMode) {
      case LoopMode.one:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
    }
    notifyListeners();
  }

  Future<void> setColor() async {
    if (gradintIdx + 1 >= AppGradients.allGradients.length) {
      gradintIdx = 0;
    } else {
      gradintIdx++;
    }
    currColor = AppGradients.allGradients[gradintIdx];
    notifyListeners();
  }

  void tick(int deltaMs) {
    if (!isPlaying) return;
    final oldFrame = spectrum;
    _currentTime += deltaMs;
    final newFrame = spectrum;
    if (oldFrame != newFrame) {
      notifyListeners();
    }
  }
}
