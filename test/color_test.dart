import 'package:flutter/material.dart';

class GradientColorPreviewPage extends StatelessWidget {
  const GradientColorPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("颜色渐变预览")),
      body: Center(
        child: SizedBox(
          width: 60,
          height: 300,
          child: CustomPaint(painter: ColorTestPainter()),
        ),
      ),
    );
  }
}

// 核心测试画笔 只画单根渐变胶囊条
class ColorTestPainter extends CustomPainter {
  // ========== 只改这两个颜色！快速测试 ==========
  static const Color lowColor = Color(0xFF00BFFF); // 低值颜色
  static const Color highColor = Color(0xFFFF4500); // 高值颜色
  // ============================================

  @override
  void paint(Canvas canvas, Size size) {
    // 遍历高度 0~1 完整展示渐变全过程
    for (double progress = 0; progress <= 1; progress += 0.1) {
      final barH = size.height * progress;
      // 颜色插值
      final currColor = Color.lerp(lowColor, highColor, progress)!;
      final paint = Paint()
        ..color = currColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;

      // 上下半圆胶囊形状
      final radius = size.width / 2;
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 - barH / 2),
        width: size.width,
        height: barH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
