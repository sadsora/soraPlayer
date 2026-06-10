import 'package:flutter/material.dart';
import '../view_models/play_viewmodel.dart';

class ProgressBar extends StatefulWidget {
  const ProgressBar({super.key});

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  final PlayViewmodel _vm = PlayViewmodel.instance;
  bool _isDragging = false;
  double _dragValue = 0.0;

  String _formatTime(int ms) {
    final totalSeconds = (ms / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final value = _isDragging ? _dragValue : (_vm.progress ?? 0.0);
        final activeColor = _vm.currColor.start;
        final inactiveColor = Colors.white.withValues(alpha: 0.15);

        return Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                _formatTime(_vm.currentTime),
                style: const TextStyle(fontSize: 12, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: activeColor,
                  inactiveTrackColor: inactiveColor,
                  thumbColor: Colors.white,
                  overlayColor: activeColor.withValues(alpha: 0.2),
                  trackHeight: 4,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: _isDragging ? 8 : 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Slider(
                  value: value.clamp(0.0, 1.0),
                  onChanged: (v) => _dragValue = v,
                  onChangeStart: (_) {
                    _isDragging = true;
                    _dragValue = _vm.progress ?? 0.0;
                  },
                  onChangeEnd: (v) {
                    _isDragging = false;
                    _vm.seek((v * _vm.duration).toInt());
                  },
                ),
              ),
            ),
            SizedBox(
              width: 42,
              child: Text(
                _formatTime(_vm.duration),
                style: const TextStyle(fontSize: 12, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}
