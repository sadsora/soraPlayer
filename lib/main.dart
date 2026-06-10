import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'views/home_screen.dart';
import 'views/play_screen.dart';
import 'views/vis_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Android: 沉浸式全屏，状态栏/导航栏透明覆盖在内容上
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "sora player v0.3",
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
    );
  }
}
