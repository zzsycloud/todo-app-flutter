import 'package:flutter/material.dart';

/// 9.1 显式动画：AnimationController + Tween + CurvedAnimation。
/// 从 0 计数到 target，使用 easeOutCubic 节奏。
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.target,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final int target;
  final TextStyle? style;
  final Duration duration;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  /// 上一次动画结束时的数值，作为下一次动画的起点
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _from = _displayed;
      _controller
        ..reset()
        ..forward();
    }
  }

  double get _displayed => _from + (widget.target - _from) * _animation.value;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _displayed.round();
        return Text('$value', style: widget.style);
      },
    );
  }
}
