import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

class FpsCounter extends StatefulWidget {
  const FpsCounter({super.key});

  @override
  State<FpsCounter> createState() => _FpsCounterState();
}

class _FpsCounterState extends State<FpsCounter>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<int> _fpsNotifier = ValueNotifier(0);
  int _fpsCount = 0;
  int _fpsLastSecond = -1;
  //Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _fpsCount++;
      final sec = elapsed.inSeconds;
      if (sec != _fpsLastSecond) {
        _fpsNotifier.value = _fpsCount;
        _fpsCount = 0;
        _fpsLastSecond = sec;
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _fpsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return ValueListenableBuilder<int>(
      valueListenable: _fpsNotifier,
      builder: (_, fps, _) => Text(
        '$fps fps',
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
