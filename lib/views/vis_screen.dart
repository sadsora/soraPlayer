import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../view_models/play_viewmodel.dart';
import '../widgets/glass_button.dart';
import '../widgets/progress_bar.dart';
import '../widgets/fps_counter.dart';
import '../widgets/vis_factory.dart';
import '../constants/app_gradients.dart';
import 'dart:ui' as ui;

class VisScreen extends StatefulWidget {
  const VisScreen({super.key});

  @override
  State<VisScreen> createState() => _VisScreenState();
}

class _VisScreenState extends State<VisScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _viewmodel = PlayViewmodel.instance;
  Duration _lastElapsed = Duration.zero;
  VisMode _currentMode = VisMode.radial;

  //手势 seek
  bool _isDragging = false;
  double _dragValue = 0.0;

  // ticker

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final delta = (elapsed - _lastElapsed).inMilliseconds;
      _lastElapsed = elapsed;
      _viewmodel.tick(delta);
    })..start();
  }

  CustomPainter _getCurrentMode(double progress) {
    final rotation = _lastElapsed.inMilliseconds / 1000.0 * 0.25;

    return createVisPainter(
      mode: _currentMode,
      spectrum: _viewmodel.spectrum,
      gradient: AppGradients.allGradients[_viewmodel.gradintIdx],
      coverImg: _viewmodel.coverImg,
      rotation: rotation,
      progress: progress,
    );
  }

  void _switchMode() {
    setState(() {
      switch (_currentMode) {
        case VisMode.line:
          _currentMode = VisMode.circle;
        case VisMode.circle:
          _currentMode = VisMode.poly;
        case VisMode.poly:
          _currentMode = VisMode.radial;
        case VisMode.radial:
          _currentMode = VisMode.line;
      }
    });
  }

  //手势seek
  void _onDragStart(DragStartDetails _) {
    setState(() {
      _isDragging = true;
      _dragValue = _viewmodel.progress ?? 0.0;
    });
  }

  void _onDragUpdate(DragUpdateDetails d, double screenWidth) {
    setState(() {
      _dragValue = (_dragValue + d.delta.dx / screenWidth).clamp(0.0, 1.0);
    });
  }

  void _onDragEnd(DragEndDetails _) {
    setState(() => _isDragging = false);
    _viewmodel.seek((_dragValue * _viewmodel.duration).toInt());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewmodel,
      builder: (context, child) {
        final double screenW = MediaQuery.of(context).size.width;
        final double barProgress = _isDragging
            ? _dragValue
            : (_viewmodel.progress ?? 0.0);

        return Scaffold(
          body: Stack(
            children: [
              //全屏模糊封面背景
              Positioned.fill(
                child: _viewmodel.cover != null
                    ? RepaintBoundary(
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 30,
                            sigmaY: 30,
                          ),
                          child: Image.memory(
                            _viewmodel.cover!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Container(color: _viewmodel.bgColor),
              ),

              //暗色遮罩
              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: 0.7)),
              ),

              //频谱可视化 手势seek层
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: (d) => _onDragUpdate(d, screenW),
                  onHorizontalDragEnd: _onDragEnd,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _getCurrentMode(barProgress),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),

              //拖拽时显示浮动时间
              if (_isDragging)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatDragTime(
                          (_dragValue * _viewmodel.duration).toInt(),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

              //FPS指示器（仅debug）
              const Positioned(top: 8, right: 20, child: FpsCounter()),
              //顶部返回按钮
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        GlassButton(
                          icon: Icons.keyboard_backspace_rounded,
                          onPressed: () => Navigator.pop(context),
                          useBlur: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              //进度条
              Positioned(
                bottom: 72,
                left: 0,
                right: 0,
                child: const ProgressBar(),
              ),

              //底部按钮
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GlassButton(
                        icon: Icons.change_circle_outlined,
                        onPressed: _switchMode,
                        // label: _currentModeIdx == 1
                        //     ? "Line"
                        //     : _currentModeIdx == 2
                        //     ? "Circle"
                        //     : "Poly",
                        useBlur: true,
                      ),
                      const SizedBox(width: 24),
                      GlassButton(
                        icon: Icons.palette,
                        onPressed: () => _viewmodel.setColor(),
                        // label: "主题色",
                        useBlur: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatDragTime(int ms) {
  final totalSec = (ms / 1000).round();
  final min = totalSec ~/ 60;
  final sec = totalSec % 60;
  return '$min:${sec.toString().padLeft(2, '0')}';
}
