import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/todo_item.dart';

/// 日历页：按月查看每天新增的待办
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.state});

  final AppState state;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const List<String> _weekLabels = ['一', '二', '三', '四', '五', '六', '日'];

  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<TodoItem> _createdOn(DateTime day) => widget.state.todos
      .where((item) => _isSameDay(item.createdAt, day))
      .toList();

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selected = DateTime(_month.year, _month.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final selectedItems = _createdOn(_selected);

        return Scaffold(
          appBar: AppBar(
            title: Text('${_month.year} 年 ${_month.month} 月'),
            actions: [
              IconButton(
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_left),
                tooltip: '上个月',
              ),
              IconButton(
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_right),
                tooltip: '下个月',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _buildWeekHeader(cs),
              _buildGrid(cs),
              Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant),
              _buildSelectedHeader(cs, selectedItems.length),
              if (selectedItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    '这一天没有新增待办',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.33,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ...selectedItems.map((item) => _buildItem(item, cs)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekHeader(ColorScheme cs) {
    final style = TextStyle(
      fontSize: 12,
      height: 1.33,
      color: cs.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          for (final label in _weekLabels)
            Expanded(
              child: Center(child: Text(label, style: style)),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(ColorScheme cs) {
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final leading = firstWeekday - 1;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((leading + days) / 7).ceil();

    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: _dayCell(cs, row * 7 + column - leading + 1, days),
                ),
            ],
          ),
      ],
    );
  }

  Widget _dayCell(ColorScheme cs, int day, int daysInMonth) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 48);

    final date = DateTime(_month.year, _month.month, day);
    final items = _createdOn(date);
    final selected = _isSameDay(date, _selected);
    final today = _isSameDay(date, DateTime.now());

    return InkWell(
      onTap: () => setState(() => _selected = date),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? cs.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.43,
                  color: selected
                      ? cs.onPrimary
                      : (today ? cs.primary : cs.onSurface),
                  fontWeight: today || selected
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: items.isEmpty
                    ? Colors.transparent
                    : (selected ? cs.primary : cs.tertiary),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedHeader(ColorScheme cs, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selected.month} 月 ${_selected.day} 日',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ),
          Text(
            '新增 $count 项',
            style: TextStyle(
              fontSize: 12,
              height: 1.33,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(TodoItem item, ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      elevation: 1,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: item.done ? cs.onSurfaceVariant : cs.onSurface,
            decoration: item.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${item.time} · ${item.category} · ${item.priority}优先级',
          style: TextStyle(
            fontSize: 12,
            height: 1.33,
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          item.done ? '已完成' : '进行中',
          style: TextStyle(
            fontSize: 12,
            height: 1.33,
            color: item.done ? cs.secondary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
