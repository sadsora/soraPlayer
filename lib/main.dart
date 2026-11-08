import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'services/immersive_service.dart';
import 'views/home_screen.dart';
import 'views/play_screen.dart';
import 'views/vis_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // 桌面端：初始化窗口管理，供可视化页切换无边框全屏
  await ImmersiveService.instance.init();

  // 安卓：启动即全屏，状态栏/导航栏直接不显示
  await ImmersiveService.applyAndroidDefault();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _ImmersiveShortcuts(
      child: MaterialApp(
        title: "sora player v0.4",
        theme: ThemeData(
          fontFamily: 'PingFang',
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromARGB(255, 126, 169, 196),
            brightness: Brightness.dark,
          ),

          sliderTheme: SliderThemeData(
            trackHeight: 4,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: const Color.fromARGB(255, 0, 170, 255),
            thumbColor: const Color.fromARGB(255, 218, 228, 10),
          ),
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/play': (context) => const PlayScreen(),
          '/vis': (context) => const VisScreen(),
        },
      ),
    );
  }
}

/// 沉浸式全局快捷键：F11 切换无边框全屏，Esc 退出。
///
/// 用 HardwareKeyboard 的全局 handler 而非 Focus.onKeyEvent，
/// 这样焦点转移到任意组件后快捷键依然有效，保证"任何时候都退得出来"。
class _ImmersiveShortcuts extends StatefulWidget {
  const _ImmersiveShortcuts({required this.child});

  final Widget child;

  @override
  State<_ImmersiveShortcuts> createState() => _ImmersiveShortcutsState();
}

class _ImmersiveShortcutsState extends State<_ImmersiveShortcuts> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (!ImmersiveService.instance.supported) return false;
    // 只认首次按下，过滤长按产生的 KeyRepeatEvent
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.f11) {
      ImmersiveService.instance.toggle();
      return true;
    }
    // Esc 只在沉浸状态下接管，避免抢走对话框等组件对 Esc 的使用
    if (key == LogicalKeyboardKey.escape &&
        ImmersiveService.instance.isImmersive) {
      ImmersiveService.instance.exit();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
