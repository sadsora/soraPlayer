import 'dart:async';
import 'package:media_kit/media_kit.dart';
import '../models/song.dart';

class AudioReaderService {
  static final AudioReaderService instance = AudioReaderService._();
  AudioReaderService._() {
    //print("AudioReaderService initialized");
    _player.stream.playing.listen((playing) {
      if (playing) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
      }
    });
  }

  final Player _player = Player();
  Player get player => _player;
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  static const double _defaultTargetVolume = 60.0;
  static const Duration _defaultFadeDuration = Duration(seconds: 2);
  Timer? _fadeTimer;

  Stream<bool> get onCompleted => _player.stream.completed;
  Stream<Duration> get onPosition => _player.stream.position;
  Stream<Duration> get onDuration => _player.stream.duration;

  /// 普通播放
  Future<void> playAudio(Song song) async {
    await playAudioWithFadeIn(
      song,
      targetVolume: _defaultTargetVolume,
      fadeDuration: Duration.zero,
    );
  }

  /// 带渐入效果的播放
  /// [targetVolume] 最终音量，0.0~100.0 或更高，默认 100.0
  /// [fadeDuration] 渐入持续时间，例如 Duration(seconds: 2)
  Future<void> playAudioWithFadeIn(
    Song song, {
    double targetVolume = _defaultTargetVolume,
    Duration fadeDuration = _defaultFadeDuration,
  }) async {
    // 取消正在进行的渐入
    _fadeTimer?.cancel();

    print('fading in');
    await _player.setVolume(0);
    await _player.open(Media('file://${song.filePath}'));
    await _player.play();

    if (fadeDuration == Duration.zero) {
      // 不需要渐入
      await _player.setVolume(targetVolume);
      return;
    }

    // 渐入：在 fadeDuration 内将音量从 0 线性提升到 targetVolume
    const int tickMs = 50; // 每 50ms 更新一次音量
    final int totalTicks = (fadeDuration.inMilliseconds / tickMs).ceil();
    final double volumeStep = targetVolume / totalTicks;
    int tickCount = 0;

    _fadeTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      tickCount++;
      final double newVolume = (volumeStep * tickCount).clamp(0, targetVolume);
      _player.setVolume(newVolume);

      if (tickCount >= totalTicks) {
        _player.setVolume(targetVolume); // 确保最终精确值
        timer.cancel();
        _fadeTimer = null;
      }
    });
  }

  Future<void> fadeOutAndPause({
    Duration duration = const Duration(seconds: 1),
  }) async {
    _fadeTimer?.cancel();
    const int tickMs = 50;
    final double currentVolume = (_player.state.volume).clamp(
      0,
      _defaultTargetVolume,
    );
    final int totalTicks = (duration.inMilliseconds / tickMs).ceil();
    final double volumeStep = currentVolume / totalTicks;
    int tickCount = 0;
    _fadeTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      tickCount++;
      final double newVolume = (currentVolume - volumeStep * tickCount).clamp(
        0,
        currentVolume,
      );
      _player.setVolume(newVolume);

      if (tickCount >= totalTicks) {
        _player.setVolume(0);
        timer.cancel();
        _fadeTimer = null;
        _player.pause();
      }
    });
  }

  Future<void> resume() async {
    if (_isPlaying) return;
    _fadeTimer?.cancel();
    await _player.setVolume(0);
    await _player.play();

    // 渐入恢复播放
    const int tickMs = 50;
    final int totalTicks = (_defaultFadeDuration.inMilliseconds / tickMs)
        .ceil();
    final double volumeStep = _defaultTargetVolume / totalTicks;
    int tickCount = 0;

    _fadeTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      tickCount++;
      final double newVolume = (volumeStep * tickCount).clamp(
        0,
        _defaultTargetVolume,
      );
      _player.setVolume(newVolume);

      if (tickCount >= totalTicks) {
        _player.setVolume(_defaultTargetVolume);
        timer.cancel();
        _fadeTimer = null;
      }
    });
  }

  Future<void> seek(int pos) async {
    await _player.seek(Duration(milliseconds: pos));
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _fadeTimer?.cancel();
    _player.dispose();
  }
}
