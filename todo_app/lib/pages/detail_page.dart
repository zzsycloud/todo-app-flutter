import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/todo_item.dart';
import '../pages/editor_page.dart';
import '../widgets/category_art.dart';
import '../widgets/menu_row.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.state, required this.item});

  final AppState state;
  final TodoItem item;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  // 9.1 动画四角色：Controller 当时钟，Tween 映射值域，Curve 控制节奏
  late Animation<double> _animation;
  late bool _done = widget.item.done;

  @override
  void initState() {
    super.initState();
    _animation = Tween<double>(
      begin: 0,
      end: _done ? 100 : 60,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final from = _animation.value;
    _animation = Tween<double>(begin: from, end: target)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller
      ..reset()
      ..forward();
  }

  void _toggleDone() {
    setState(() {
      _done = !_done;
      _animateTo(_done ? 100 : 60);
    });
    widget.state.toggleDone(widget.item);
  }

  void _deleteItem() {
    widget.state.deleteTodo(widget.item);
    Navigator.of(context).pop();
  }

  Future<void> _edit() async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditorPage(
          initial: widget.item,
          defaultGroup: widget.state.defaultGroup,
          onSave: (_) => widget.state.updateTodo(widget.item),
          onDelete: () => widget.state.deleteTodo(widget.item),
        ),
      ),
    );
    if (!mounted) return;
    if (deleted == true) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;
    final note = item.note.trim().isEmpty ? '暂无备注' : item.note;

    return Scaffold(
      appBar: AppBar(
        title: const Text('待办详情'),
        actions: [
          PopupMenuButton<String>(
            tooltip: '更多',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _edit();
                case 'toggle':
                  _toggleDone();
                case 'delete':
                  _deleteItem();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: MenuRow(icon: Icons.edit_outlined, label: '编辑'),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: MenuRow(
                  icon: _done ? Icons.undo : Icons.check,
                  label: _done ? '标记未完成' : '标记完成',
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: MenuRow(
                  icon: Icons.delete_outline,
                  label: '删除',
                  danger: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  // 9.4 Hero 落点：与列表缩略图同 tag
                  child: Hero(
                    tag: 'todo-art-${item.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 160,
                        child: CategoryArt(category: item.category),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.27,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(
                        text: '${item.priority}优先级',
                        background: item.priority == '高'
                            ? cs.errorContainer
                            : cs.surfaceContainerHighest,
                        foreground: item.priority == '高'
                            ? cs.onErrorContainer
                            : cs.onSurfaceVariant,
                      ),
                      // 9.6 AnimatedSwitcher：状态文字切换
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: _switcherTransition,
                        child: _pill(
                          key: ValueKey('state-$_done'),
                          text: _done ? '已完成' : '进行中',
                          background: _done
                              ? cs.secondaryContainer
                              : cs.surfaceContainerHighest,
                          foreground: _done
                              ? cs.onSecondaryContainer
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildProgressCard(cs),
                _buildMetaList(cs),
                _buildNotesCard(cs, note),
              ],
            ),
          ),
          _buildBottomBar(cs),
        ],
      ),
    );
  }

  Widget _buildProgressCard(ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 1,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = _animation.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '完成度',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.33,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${value.round()}%',
                      style: TextStyle(
                        fontSize: 36,
                        height: 1.2,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '3 / 5 子任务',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.33,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: value / 100,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetaList(ColorScheme cs) {
    final item = widget.item;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _meta(Icons.calendar_today_outlined, '截止时间', item.time, cs),
          Divider(height: 1, color: cs.outlineVariant),
          _meta(Icons.folder_outlined, '所属分组', item.group, cs),
          Divider(height: 1, color: cs.outlineVariant),
          _meta(Icons.local_offer_outlined, '分类', item.category, cs),
          Divider(height: 1, color: cs.outlineVariant),
          _meta(Icons.schedule, '创建时间', _formatDate(item.createdAt), cs),
        ],
      ),
    );
  }

  Widget _buildNotesCard(ColorScheme cs, String note) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      elevation: 1,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '备注',
              style: TextStyle(
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note,
              style: TextStyle(
                fontSize: 14,
                height: 1.57,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme cs) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: [
            OutlinedButton(onPressed: _edit, child: const Text('编辑')),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _toggleDone,
                style: _done
                    ? FilledButton.styleFrom(
                        backgroundColor: cs.secondaryContainer,
                        foregroundColor: cs.onSecondaryContainer,
                      )
                    : null,
                child: Text(_done ? '已完成' : '标记完成'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String label, String value, ColorScheme cs) {
    final style = TextStyle(
      fontSize: 14,
      height: 1.43,
      color: cs.onSurfaceVariant,
    );
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Icon(icon, size: 24, color: cs.onSurfaceVariant),
          const SizedBox(width: 16),
          Text(label, style: style),
          const Spacer(),
          Text(
            value,
            style: style.copyWith(color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.month} 月 ${date.day} 日 $hour:$minute';
  }

  Widget _pill({
    required String text,
    Key? key,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      key: key,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontSize: 12, height: 1.33, color: foreground),
      ),
    );
  }

  Widget _switcherTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
        child: child,
      ),
    );
  }
}
