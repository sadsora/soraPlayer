import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:soraplayer02/models/gradient_color.dart';
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
  bool get isPlaying => _audioService.isPlaying;
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
    coverImg = await Paletteservice.decodeImage(cover!);
    final palette = await Paletteservice.extract(coverImg!);
    vibrantColor = palette.vibrantColor;
    mutedColor = palette.mutedColor;
    notifyListeners();
    _loadFftDataInBackground(playlist[index]);
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
    notifyListeners();
  }

  Future<void> pause() async {
    if (_currentIndex < 0) return;
    await _audioService.fadeOutAndPause();
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
    coverImg = await Paletteservice.decodeImage(cover!);
    final palette = await Paletteservice.extract(coverImg!);
    vibrantColor = palette.vibrantColor;
    mutedColor = palette.mutedColor;
    notifyListeners();
    _loadFftDataInBackground(song);
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
    coverImg = await Paletteservice.decodeImage(cover!);
    final palette = await Paletteservice.extract(coverImg!);
    vibrantColor = palette.vibrantColor;
    mutedColor = palette.mutedColor;
    notifyListeners();
    _loadFftDataInBackground(song);
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
