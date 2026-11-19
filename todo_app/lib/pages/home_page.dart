import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/todo_item.dart';
import '../notification_service.dart';
import '../pages/calendar_page.dart';
import '../pages/detail_page.dart';
import '../pages/editor_page.dart';
import '../pages/profile_page.dart';
import '../widgets/category_art.dart';
import '../widgets/menu_row.dart';
import '../widgets/swipe_todo_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.state});

  final AppState state;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  AppState get _state => widget.state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(_tab == 0 ? '待办事项' : '我的'),
          actions: _tab == 0
              ? [
                  IconButton(
                    onPressed: _openCalendar,
                    icon: const Icon(Icons.calendar_month_outlined),
                    tooltip: '日历',
                  ),
                ]
              : null,
        ),
        body: _tab == 0
            ? _buildTodoList()
            : ProfilePage(state: _state),
        floatingActionButton: _tab == 0
            ? FloatingActionButton(
                onPressed: _createTodo,
                tooltip: '新增待办',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: '待办',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoList() {
    final days = _state.todoDays;

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      children: [
        _buildOverview(),
        if (_state.todos.isEmpty) _buildBlankState() else ...[
          for (final day in days) _buildDaySection(day),
        ],
      ],
    );
  }

  /// 首次打开应用时没有任何数据，这里给出明确的引导
  Widget _buildBlankState() {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Column(
        children: [
          Icon(
            Icons.playlist_add_check_circle_outlined,
            size: 56,
            color: cs.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有待办',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '点击右下角的 + 新建第一条待办',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(DateTime day) {
    final items = _state.todosOn(day);
    final mode = _state.sortModeFor(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(day, items.length, mode),
        if (items.isEmpty) _buildEmpty(),
        ...items.map(_buildTodoCard),
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        '暂无待办',
        style: TextStyle(
          fontSize: 12,
          height: 1.33,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// 9.6 AnimatedSwitcher：剩余数量变化时缩放切换
  Widget _buildOverview() {
    final cs = Theme.of(context).colorScheme;
    final done = _state.doneCount;
    final total = _state.totalCount;
    final remaining = _state.pendingCount;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 0,
      color: cs.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: _switcherTransition,
                  child: Text(
                    '$remaining',
                    key: ValueKey('remaining-$remaining'),
                    style: TextStyle(
                      fontSize: 36,
                      height: 1.2,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                Text(
                  '项剩余待办',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.33,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '已完成 $done / 共 $total',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.33,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                    color: cs.onPrimaryContainer,
                    backgroundColor: cs.onPrimaryContainer.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 日期分组标题：日期 + 条数 + 该日独立的排序切换
  Widget _buildSectionHeader(DateTime day, int count, TodoSortMode mode) {
    final cs = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: 14,
      height: 1.43,
      color: cs.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _dayLabel(day),
              style: style.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text('$count', style: style),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _state.setSortMode(
              day,
              mode == TodoSortMode.time
                  ? TodoSortMode.priority
                  : TodoSortMode.time,
            ),
            icon: const Icon(Icons.swap_vert, size: 16),
            label: Text(
              mode == TodoSortMode.time ? '按时间' : '按优先级',
              style: TextStyle(fontSize: 12, height: 1.33, color: cs.primary),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    const week = ['一', '二', '三', '四', '五', '六', '日'];
    return '${day.month} 月 ${day.day} 日 · 周${week[day.weekday - 1]}';
  }

  Color _priorityColor(ColorScheme cs, String priority) {
    return switch (priority) {
      '重要且紧急' => cs.error,
      '重要但不紧急' => cs.primary,
      '紧急但不重要' => cs.tertiary,
      _ => cs.onSurfaceVariant,
    };
  }

  Widget _buildTodoCard(TodoItem item) {
    final cs = Theme.of(context).colorScheme;
    final subStyle = TextStyle(
      fontSize: 12,
      height: 1.33,
      color: cs.onSurfaceVariant,
    );

    return SwipeTodoCard(
      done: item.done,
      onEdit: () => _editTodo(item),
      onToggle: () => _state.toggleDone(item),
      onDelete: () => _state.deleteTodo(item),
      child: Card(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        elevation: 1,
        color: item.done ? cs.surfaceContainer : cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetail(item),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              children: [
                Checkbox(
                  value: item.done,
                  onChanged: (_) => _state.toggleDone(item),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 9.7 隐式动画：完成态文字变灰 + 删除线
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color:
                              item.done ? cs.onSurfaceVariant : cs.onSurface,
                          decoration: item.done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(item.time, style: subStyle),
                          _dot(cs),
                          Text(item.category, style: subStyle),
                          _dot(cs),
                          Flexible(
                            child: Text(
                              item.priority,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: subStyle.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _priorityColor(cs, item.priority),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (item.hasSubtasks) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SizedBox(
                              width: 56,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0,
                                  end: item.progress,
                                ),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                builder: (context, value, _) =>
                                    LinearProgressIndicator(
                                      value: value,
                                      minHeight: 3,
                                      borderRadius: BorderRadius.circular(2),
                                      backgroundColor: cs.surfaceContainerHighest,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '子任务 ${item.subtaskDoneCount}/${item.subtaskTotal}',
                              style: subStyle.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // 9.4 Hero 起飞点
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Hero(
                    tag: 'todo-art-${item.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: item.done ? 0.55 : 1,
                        child: CategoryArt(category: item.category),
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: '更多',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _onMenuSelected(value, item),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: MenuRow(icon: Icons.edit_outlined, label: '编辑'),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: MenuRow(
                        icon: item.done ? Icons.undo : Icons.check,
                        label: item.done ? '标记未完成' : '标记完成',
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
          ),
        ),
      ),
    );
  }

  Widget _dot(ColorScheme cs) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(color: cs.outline, shape: BoxShape.circle),
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

  void _onMenuSelected(String value, TodoItem item) {
    switch (value) {
      case 'edit':
        _editTodo(item);
      case 'toggle':
        _state.toggleDone(item);
      case 'delete':
        _state.deleteTodo(item);
    }
  }

  Future<void> _openDetail(TodoItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailPage(state: _state, item: item),
      ),
    );
  }

  Future<void> _createTodo() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorPage(
          customCategories: _state.customCategories,
          onAddCategory: _state.addCustomCategory,
          onSave: (item) async {
            await _state.addTodo(item);
            if (_state.notificationsEnabled) {
              await NotificationService.show(
                title: '已添加待办',
                body: item.title,
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _editTodo(TodoItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditorPage(
          initial: item,
          customCategories: _state.customCategories,
          onAddCategory: _state.addCustomCategory,
          onSave: (_) => _state.updateTodo(item),
          onDelete: () => _state.deleteTodo(item),
        ),
      ),
    );
  }

  Future<void> _openCalendar() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CalendarPage(state: _state)),
    );
  }
}
