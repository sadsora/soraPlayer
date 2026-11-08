import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../view_models/play_viewmodel.dart';
import '../services/immersive_service.dart';
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

  //自动隐藏 UI(无操作 N 秒后淡出,点击任意处重新显示)
  bool _uiVisible = true;
  Timer? _hideTimer;
  static const _hideAfter = Duration(seconds: 3);

  // ticker

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final delta = (elapsed - _lastElapsed).inMilliseconds;
      _lastElapsed = elapsed;
      _viewmodel.tick(delta);
    })..start();
    _resetUiTimer();
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

  void _resetUiTimer() {
    _hideTimer?.cancel();
    if (!_uiVisible) {
      setState(() => _uiVisible = true);
    }
    _hideTimer = Timer(_hideAfter, () {
      if (mounted) {
        setState(() => _uiVisible = false);
      }
    });
  }

  Widget _uiFade(Widget child) {
    return AnimatedOpacity(
      opacity: _uiVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(ignoring: !_uiVisible, child: child),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewmodel,
      builder: (context, child) {
        final double barProgress = _viewmodel.progress ?? 0.0;

        return Scaffold(
          body: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _resetUiTimer(),
            child: Stack(
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

                //频谱可视化
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _getCurrentMode(barProgress),
                      size: Size.infinite,
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
                  child: _uiFade(
                    SafeArea(
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
                ),

                //进度条
                Positioned(
                  bottom: 72,
                  left: 0,
                  right: 0,
                  child: _uiFade(const ProgressBar()),
                ),

                //底部按钮
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: _uiFade(
                    SafeArea(
                      top: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GlassButton(
                            icon: Icons.change_circle_outlined,
                            onPressed: _switchMode,
                            useBlur: true,
                          ),
                          const SizedBox(width: 24),
                          GlassButton(
                            icon: _viewmodel.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            onPressed: () {
                              if (_viewmodel.isPlaying) {
                                _viewmodel.pause();
                              } else {
                                _viewmodel.resume();
                              }
                            },
                            useBlur: true,
                          ),
                          const SizedBox(width: 24),
                          GlassButton(
                            icon: Icons.palette,
                            onPressed: () => _viewmodel.setColor(),
                            // label: "主题色",
                            useBlur: true,
                          ),
                          //无边框全屏开关(仅桌面端，安卓无此概念)
                          if (ImmersiveService.instance.supported) ...[
                            const SizedBox(width: 24),
                            ListenableBuilder(
                              listenable: ImmersiveService.instance,
                              builder: (context, _) => GlassButton(
                                icon: ImmersiveService.instance.isImmersive
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                onPressed: () =>
                                    ImmersiveService.instance.toggle(),
                                useBlur: true,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
