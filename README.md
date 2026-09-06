# Sora Player v0.4

一个基于 Flutter 的本地音频播放器，支持 FFT 实时频谱可视化。

## 功能

- **本地音频播放** — 支持 MP3 / FLAC / WAV 等常见格式，通过 media_kit（libmpv 后端）驱动
- **4 种 FFT 频谱可视化** — Line / Circle / Poly / Radial，实时跟随播放进度
- **专辑封面提取 + 自动配色** — 从音频元数据中读取封面，通过 PaletteGenerator 提取 vibrant/muted 色彩作为背景渐变
- **可切换的主题渐变** — 内置多套渐变色系，一键切换可视化配色
- **双循环模式** — 单曲循环 / 列表循环
- **手势 Seek** — 在可视化界面横向拖动跳转播放位置
- **多种导入方式** — 可单选/多选文件，也可通过 `.txt` 播放列表批量导入
- **沉浸式全屏** — Android 端 edge-to-edge，状态栏/导航栏透明覆盖
- **音频解码 (FFI)** — 通过 Dart FFI 调用原生 C 解码库（MP3 基于 minimp3、FLAC 基于 dr_flac），将音频转为 PCM 供 FFT 分析

## 平台支持

| 平台    | 状态       |
| ------- | ---------- |
| Windows | ✅ 已支持  |
| Android | ✅ 已支持  |
| iOS     | 未适配     |
| macOS   | 未适配     |
| Linux   | 未适配     |

## 技术栈

| 层       | 技术                                         |
| -------- | -------------------------------------------- |
| 框架     | Flutter (Dart SDK ^3.11.5)                   |
| 音频播放 | [media_kit](https://pub.dev/packages/media_kit) + libmpv |
| 音频解码 | `dart:ffi` → minimp3 (MP3) + dr_flac (FLAC) C 解码器 |
| FFT 分析 | [fftea](https://pub.dev/packages/fftea) (Dart 原生 FFT) |
| 封面配色 | `palette_generator_master`                    |
| 文件选择 | [file_picker](https://pub.dev/packages/file_picker) |
| 状态管理 | 单例 ViewModel + `ChangeNotifier` + `ListenableBuilder` |

## 架构概览

```
lib/
├── main.dart                     # 入口，初始化 media_kit，设置沉浸式
├── views/
│   ├── home_screen.dart          # 启动页
│   ├── play_screen.dart          # 播放主界面（封面、歌单、控制栏）
│   └── vis_screen.dart           # 频谱全屏可视化 + 手势 seek
├── view_models/
│   └── play_viewmodel.dart       # 播放状态中枢（单例 ChangeNotifier）
├── services/
│   ├── audio_reader_service.dart # media_kit 音频播放封装
│   ├── audio_metadata_reader.dart# ID3(MP3)/Vorbis(FLAC) 元数据读取
│   ├── fft_analyzer_service.dart # FFT 频谱分析（Isolate 异步）
│   ├── pcm_decoder_service.dart  # PCM 解码调度（MP3 / FLAC / WAV）
│   ├── mp3_decoder_ffi.dart      # FFI 桥接层（minimp3 C 解码器）
│   ├── flac_decoder_ffi.dart     # FFI 桥接层（dr_flac C 解码器）
│   └── PaletteService.dart       # 封面图像解码 + 调色板提取
├── models/
│   ├── song.dart                 # 歌曲数据模型
│   ├── fftdata.dart / fftframe.dart  # FFT 分析结果
│   ├── gradient_color.dart       # 渐变色定义
│   └── loop_mode.dart            # 循环模式枚举
├── widgets/
│   ├── vis_factory.dart          # 可视化工厂（按模式分发 painter）
│   ├── line_vis.dart             # 线性频谱图
│   ├── circle_vis.dart           # 圆形频谱图
│   ├── radial_vis.dart           # 径向频谱图
│   ├── poly_vis.dart             # 多边形频谱图
│   ├── progress_bar.dart         # 播放进度条
│   ├── glass_button.dart         # 毛玻璃按钮通用组件
│   └── fps_counter.dart          # FPS 指示器（仅 Debug）
└── constants/
    └── app_gradients.dart        # 预设渐变色方案
```

原生解码器位于 `native/`（通过 FFI 暴露给 Dart）：

```
native/
├── CMakeLists.txt                # 顶层：同时构建 mp3 + flac
├── mp3_decoder/
│   ├── mp3_decoder.c             # minimp3 解码器
│   ├── minimp3.h
│   └── CMakeLists.txt
└── flac_decoder/
    ├── flac_decoder.c            # dr_flac 解码器
    ├── dr_flac.h
    └── CMakeLists.txt
```

## 前置依赖

### Windows

需要 **libmpv-2.dll**（media_kit 的后端）。放置在：

```
windows/libmpv/libmpv-2.dll      # 开发时
build/windows/x64/runner/Debug/  # 运行时
```

还需要 **mp3_decoder.dll** 和 **flac_decoder.dll**（分别基于 minimp3 / dr_flac 的 C 解码器）。它们由 `native/` 下的 CMake 在构建时自动生成并拷贝到可执行目录，无需手动放置。

### Android

需要 `libmp3_decoder.so` 和 `libflac_decoder.so`（基于 minimp3 / dr_flac 的 C 解码器 Android 编译版本），由 `native/CMakeLists.txt` 构建。

### 所有平台

```bash
flutter pub get
```

## 快速开始

```bash
# 克隆项目
git clone https://github.com/sadsora/soraplayer.git
cd soraplayer

# 安装依赖
flutter pub get

# 运行
flutter run
```

在播放界面点击 ➕ 按钮添加音频文件，或长按 ➕ 导入 `.txt` 播放列表（每行一个文件路径）。

点击频谱按钮 🎵 进入全屏可视化，左右拖动切换播放进度，点击切换可视化模式。

## 运行测试

```bash
flutter test
```

## 开源许可

本项目以 [MIT License](LICENSE) 开源。

---

> 本项目正在活跃开发中
