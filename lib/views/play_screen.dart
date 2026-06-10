import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../view_models/play_viewmodel.dart';
import '../widgets/progress_bar.dart';
import '../widgets/glass_button.dart';
import '../models/loop_mode.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});
  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final PlayViewmodel _viewmodel = PlayViewmodel.instance;

  Future<void> _pickAudioFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final paths = result.files
          .where((f) => f.path != null)
          .map((f) => f.path!)
          .toList();
      await _viewmodel.addFromPaths(paths);
    }
  }

  Future<void> _pickAudioList() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      allowedExtensions: ['txt'],
    );
    if (result != null && result.files.isNotEmpty) {
      final txtPath = result.files.single.path;
      if (txtPath == null) return;
      final lines = await File(txtPath).readAsLines();
      final paths = lines
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (paths.isNotEmpty) {
        await _viewmodel.addFromPaths(paths);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewmodel,
      builder: (context, _) {
        final bgStart = _viewmodel.vibrantColor ?? _viewmodel.bgColor;
        final bgEnd = _viewmodel.mutedColor ?? _viewmodel.bgColor;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Sora player"),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          extendBodyBehindAppBar: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgStart.withValues(alpha: 0.5),
                  bgEnd.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // ——— 封面 ———
                  if (_viewmodel.cover != null)
                    CircleAvatar(
                      backgroundImage: MemoryImage(_viewmodel.cover!),
                      radius: 80,
                    )
                  else
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.music_note,
                        size: 50,
                        color: Colors.white54,
                      ),
                    ),
                  const SizedBox(height: 16),
                  // ——— 歌曲信息 ———
                  Text(
                    _viewmodel.title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _viewmodel.artist,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  Text(
                    _viewmodel.album,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 20),

                  // ——— 歌单 ———
                  Expanded(
                    child: ListView.builder(
                      itemCount: _viewmodel.playlist.length,
                      itemBuilder: (context, index) {
                        final song = _viewmodel.playlist[index];
                        return ListTile(
                          title: Text(
                            song.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            song.artist,
                            style: const TextStyle(color: Colors.white54),
                          ),
                          onTap: () => _viewmodel.setSong(song),
                          onLongPress: () => _viewmodel.removeSong(song),
                        );
                      },
                    ),
                  ),

                  // ——— 进度条 ———
                  const ProgressBar(),

                  const SizedBox(height: 12),

                  // ——— 控制按钮 ———
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 添加歌曲
                        GlassButton(
                          icon: Icons.add,
                          onPressed: _pickAudioFiles,
                          onLongPress: _pickAudioList,
                          label: "添加",
                        ),
                        // 上一首
                        GlassButton(
                          icon: Icons.skip_previous,
                          label: "上一首",
                          onPressed: () => _viewmodel.playLast(),
                        ),
                        // 播放/暂停 — 主操作，稍大一圈
                        GlassButton(
                          icon: _viewmodel.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 52,
                          iconSize: 26,
                          onPressed: () {
                            if (_viewmodel.isPlaying) {
                              _viewmodel.pause();
                            } else {
                              _viewmodel.resume();
                            }
                          },
                        ),
                        // 下一首
                        GlassButton(
                          icon: Icons.skip_next,
                          onPressed: () => _viewmodel.playNext(),
                          label: "下一首",
                        ),
                        // 停止
                        GlassButton(
                          icon: Icons.stop,
                          onPressed: () => _viewmodel.stop(),
                          label: "停止",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ——— 辅助按钮行 ———
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GlassButton(
                        icon: Icons.loop,
                        onPressed: () => _viewmodel.setLoopMode(),
                        label: _viewmodel.loopMode == LoopMode.one
                            ? "单曲循环"
                            : "列表循环",
                      ),
                      const SizedBox(width: 16),
                      GlassButton(
                        icon: Icons.music_note_outlined,
                        onPressed: _viewmodel.spectrum != null
                            ? () => Navigator.pushNamed(context, '/vis')
                            : null,
                        //label: "可视化",
                      ),
                      const SizedBox(width: 16),
                      GlassButton(
                        icon: Icons.palette,
                        onPressed: () => _viewmodel.setColor(),
                        label: "主题色",
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
