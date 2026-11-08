import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// 沉浸式全屏控制。
///
/// - 桌面端(Windows/macOS/Linux)：走 window_manager 的 setFullScreen，
///   效果是无边框铺满整个显示器(含任务栏区域)，退出时还原原始窗口样式与位置。
/// - 安卓端：不做开关，启动即 immersiveSticky 常驻隐藏状态栏/导航栏，
///   所以 [supported] 为 false，可视化页不会渲染全屏按钮。
class ImmersiveService extends ChangeNotifier {
  ImmersiveService._();

  static final ImmersiveService instance = ImmersiveService._();

  bool _isImmersive = false;
  bool get isImmersive => _isImmersive;

  /// 是否支持运行时切换无边框全屏(仅桌面端)。
  bool get supported {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return true;
      default:
        return false;
    }
  }

  /// 必须在 runApp 之前调用(桌面端)。
  Future<void> init() async {
    if (!supported) return;
    await windowManager.ensureInitialized();
  }

  /// 安卓端启动即生效：隐藏状态栏与导航栏，用户从边缘滑动才会临时唤出。
  static Future<void> applyAndroidDefault() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> toggle() => _isImmersive ? exit() : enter();

  Future<void> enter() async {
    if (_isImmersive) return;
    if (supported) await windowManager.setFullScreen(true);
    _isImmersive = true;
    notifyListeners();
  }

  Future<void> exit() async {
    if (!_isImmersive) return;
    if (supported) await windowManager.setFullScreen(false);
    _isImmersive = false;
    notifyListeners();
  }
}
