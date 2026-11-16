import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/todo_item.dart';
import '../pages/detail_page.dart';

enum StatsFilter { done, pending, all }

/// “我的”页统计卡片点进来的明细列表
class StatsListPage extends StatelessWidget {
  const StatsListPage({
    super.key,
    required this.state,
    required this.filter,
  });

  final AppState state;
  final StatsFilter filter;

  String get _title => switch (filter) {
    StatsFilter.done => '已完成',
    StatsFilter.pending => '进行中',
    StatsFilter.all => '累计项',
  };

  List<TodoItem> _items() => switch (filter) {
    StatsFilter.done => state.todos.where((item) => item.done).toList(),
    StatsFilter.pending => state.todos.where((item) => !item.done).toList(),
    StatsFilter.all => state.todos,
  };

  String _formatDate(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.month} 月 ${date.day} 日 $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final items = _items();

        return Scaffold(
          appBar: AppBar(title: Text('$_title · ${items.length}')),
          body: items.isEmpty
              ? Center(
                  child: Text(
                    '暂无记录',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.43,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _buildItem(context, items[index], cs),
                ),
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, TodoItem item, ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      elevation: 1,
      color: item.done ? cs.surfaceContainer : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailPage(state: state, item: item),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          child: Row(
            children: [
              Checkbox(
                value: item.done,
                onChanged: (_) => state.toggleDone(item),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: item.done
                            ? cs.onSurfaceVariant
                            : cs.onSurface,
                        decoration: item.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.group} · ${item.category} · 创建于 ${_formatDate(item.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.33,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
