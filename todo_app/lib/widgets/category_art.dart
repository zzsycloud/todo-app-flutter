import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 待办封面：纯色渐变 + 居中分类图标。
/// 尺寸完全由父级约束决定，图标取短边的 50%，
/// 因此放进 Hero 后可以随容器一起缩放（9.4）。
class CategoryArt extends StatelessWidget {
  const CategoryArt({super.key, required this.category});

  final String category;

  static const Map<String, List<Color>> _gradients = {
    '学习': [Color(0xFF6750A4), Color(0xFF9280C9)],
    '生活': [Color(0xFF7D5260), Color(0xFFAC8794)],
    '工作': [Color(0xFF625B71), Color(0xFF8D8699)],
  };

  static const Map<String, IconData> _icons = {
    '学习': Icons.book,
    '生活': Icons.home,
    '工作': Icons.work_outline,
  };

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[category] ?? _gradients['学习']!;
    final icon = _icons[category] ?? Icons.book;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(constraints.maxWidth, constraints.maxHeight);
          return Center(
            child: Icon(icon, size: side * 0.5, color: Colors.white),
          );
        },
      ),
    );
  }
}
