import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/todo_item.dart';
import '../pages/editor_page.dart';
import '../widgets/category_art.dart';
import '../widgets/menu_row.dart';
import '../widgets/text_input_dialog.dart';

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
    duration: const Duration(milliseconds: 900),
  );

  // 9.1 动画四角色：Controller 当时钟，Tween 映射值域，Curve 控制节奏
  late Animation<double> _animation;
  late bool _done = widget.item.done;

  @override
  void initState() {
    super.initState();
    // 完成度完全由真实数据推导：没有子任务时只有 0% 或 100%
    _animation = Tween<double>(
      begin: 0,
      end: widget.item.progressPercent.toDouble(),
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

  /// 数据变化后统一刷新本地状态与进度动画
  void _refresh() {
    setState(() {
      _done = widget.item.done;
      _animateTo(widget.item.progressPercent.toDouble());
    });
  }

  void _toggleDone() {
    widget.state.toggleDone(widget.item);
    _refresh();
  }

  void _toggleSubtask(int index) {
    widget.state.toggleSubtask(widget.item, index);
    _refresh();
  }

  Future<void> _addSubtask() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const TextInputDialog(
        title: '添加子任务',
        hint: '例如：整理素材',
        maxLength: 40,
        confirmLabel: '添加',
      ),
    );
    if (!mounted || result == null) return;
    final title = result.trim();
    if (title.isEmpty) return;
    await widget.state.addSubtask(widget.item, title);
    if (!mounted) return;
    _refresh();
  }

  Future<void> _deleteSubtask(int index) async {
    await widget.state.deleteSubtask(widget.item, index);
    if (!mounted) return;
    _refresh();
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
          customCategories: widget.state.customCategories,
          onAddCategory: widget.state.addCustomCategory,
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
    _refresh();
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
                        text: item.priority,
                        background: _priorityBackground(cs, item.priority),
                        foreground: _priorityForeground(cs, item.priority),
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
                _buildSubtaskCard(cs),
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
    final item = widget.item;
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
                        item.progressLabel,
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

  Widget _buildSubtaskCard(ColorScheme cs) {
    final item = widget.item;
    final subtasks = item.subtasks;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 1,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '子任务',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.43,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                if (subtasks.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${item.subtaskDoneCount} / ${item.subtaskTotal}',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.33,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: _addSubtask,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            if (subtasks.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 8, 4),
                child: Text(
                  '把这件事拆成几个小步骤，勾选后完成度会自动更新。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (var i = 0; i < subtasks.length; i++)
                _buildSubtaskRow(cs, subtasks[i], i),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtaskRow(ColorScheme cs, Subtask subtask, int index) {
    return InkWell(
      onTap: () => _toggleSubtask(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: subtask.done ? cs.primary : Colors.transparent,
                border: subtask.done
                    ? null
                    : Border.all(color: cs.outline, width: 1.5),
              ),
              child: subtask.done
                  ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subtask.title,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.43,
                  color: subtask.done ? cs.onSurfaceVariant : cs.onSurface,
                  decoration: subtask.done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _deleteSubtask(index),
              icon: const Icon(Icons.close, size: 16),
              tooltip: '删除子任务',
              color: cs.onSurfaceVariant,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
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

  Color _priorityBackground(ColorScheme cs, String priority) {
    return switch (priority) {
      '重要且紧急' => cs.errorContainer,
      '重要但不紧急' => cs.primaryContainer,
      '紧急但不重要' => cs.tertiaryContainer,
      _ => cs.surfaceContainerHighest,
    };
  }

  Color _priorityForeground(ColorScheme cs, String priority) {
    return switch (priority) {
      '重要且紧急' => cs.onErrorContainer,
      '重要但不紧急' => cs.onPrimaryContainer,
      '紧急但不重要' => cs.onTertiaryContainer,
      _ => cs.onSurfaceVariant,
    };
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
