import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// [useBlur] 为 true 时启用 BackdropFilter，适合背后有纹理/图片的场景（如 VisScreen）
/// PlayScreen 等纯色背景场景用 false，用半透明背景模拟玻璃感即可
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.onLongPress,
    this.size = 44,
    this.iconSize = 22,
    this.color = Colors.white,
    this.label,
    this.useBlur = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double size;
  final double iconSize;
  final Color color;
  final String? label;
  final bool useBlur;

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    final bg = Colors.white.withValues(alpha: 0.1);
    final border = Colors.white.withValues(alpha: 0.15);

    Widget btn = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          onLongPress: onLongPress,
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Center(
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );

    if (useBlur) {
      btn = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: btn,
        ),
      );
    }

    if (label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn,
          const SizedBox(height: 6),
          Text(
            label!,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      );
    }

    return btn;
  }
}
