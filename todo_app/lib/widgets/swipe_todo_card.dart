import 'package:flutter/material.dart';

/// 左滑显示「编辑 / 标记完成 / 删除」三个快捷操作。
/// 卡片本身仍然可以点击进入详情，三个点菜单也保留。
class SwipeTodoCard extends StatefulWidget {
  const SwipeTodoCard({
    super.key,
    required this.child,
    required this.done,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final Widget child;
  final bool done;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  State<SwipeTodoCard> createState() => _SwipeTodoCardState();
}

class _SwipeTodoCardState extends State<SwipeTodoCard> {
  static const double _actionWidth = 68;
  static const double _actionSpan = _actionWidth * 3;

  double _offset = 0;
  bool _dragging = false;

  void _reset() => setState(() => _offset = 0);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _action(
                      '编辑',
                      Icons.edit_outlined,
                      cs.secondaryContainer,
                      cs.onSecondaryContainer,
                      () {
                        _reset();
                        widget.onEdit();
                      },
                    ),
                    _action(
                      widget.done ? '取消完成' : '标记完成',
                      widget.done ? Icons.undo : Icons.check,
                      cs.primaryContainer,
                      cs.onPrimaryContainer,
                      () {
                        _reset();
                        widget.onToggle();
                      },
                    ),
                    _action(
                      '删除',
                      Icons.delete_outline,
                      cs.errorContainer,
                      cs.onErrorContainer,
                      () {
                        _reset();
                        widget.onDelete();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragStart: (_) =>
                setState(() => _dragging = true),
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragging = true;
                _offset = (_offset + details.delta.dx)
                    .clamp(-_actionSpan, 0)
                    .toDouble();
              });
            },
            onHorizontalDragEnd: (_) {
              setState(() {
                _dragging = false;
                _offset = _offset < -_actionSpan / 2 ? -_actionSpan : 0;
              });
            },
            child: AnimatedContainer(
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_offset, 0, 0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
    String label,
    IconData icon,
    Color background,
    Color foreground,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: _actionWidth,
      height: 64,
      child: Material(
        color: background,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 11, height: 1.2, color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
