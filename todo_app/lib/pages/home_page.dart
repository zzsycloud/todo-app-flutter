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
    final today = _state.todayTodos;
    final tomorrow = _state.tomorrowTodos;

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      children: [
        _buildOverview(),
        _buildSectionHeader('今天', today.length),
        if (today.isEmpty) _buildEmpty(),
        ...today.map(_buildTodoCard),
        _buildSectionHeader('明天', tomorrow.length),
        if (tomorrow.isEmpty) _buildEmpty(),
        ...tomorrow.map(_buildTodoCard),
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

  Widget _buildSectionHeader(String title, int count) {
    final cs = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: 14,
      height: 1.43,
      color: cs.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: style.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text('$count', style: style),
        ],
      ),
    );
  }

  Widget _buildTodoCard(TodoItem item) {
    final cs = Theme.of(context).colorScheme;
    final subStyle = TextStyle(
      fontSize: 12,
      height: 1.33,
      color: cs.onSurfaceVariant,
    );

    return Card(
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
                        color: item.done ? cs.onSurfaceVariant : cs.onSurface,
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
                        Text(
                          item.priority,
                          style: subStyle.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: item.priority == '高' ? cs.error : null,
                          ),
                        ),
                      ],
                    ),
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
          defaultGroup: _state.defaultGroup,
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
          defaultGroup: _state.defaultGroup,
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
