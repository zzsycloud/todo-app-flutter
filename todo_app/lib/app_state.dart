import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/todo_item.dart';

/// 全局状态：待办数据、用户资料与偏好设置，统一写入本地存储。
class AppState extends ChangeNotifier {
  static const String _storageKey = 'todo_app_state_v1';

  /// 本地数据结构版本：2 表示子任务 / 完成时间 / 不再写入示例待办
  static const int _schemaVersion = 2;

  final List<TodoItem> _todos = [];

  String _userName = '张同学';
  String? _avatarPath;
  bool _darkMode = false;
  bool _notificationsEnabled = false;
  final List<String> _customCategories = [];

  /// 每个日期独立的排序方式，key 为 yyyy-MM-dd
  final Map<String, TodoSortMode> _sortModes = {};

  List<TodoItem> get todos => List.unmodifiable(_todos);
  String get userName => _userName;
  String? get avatarPath => _avatarPath;
  bool get darkMode => _darkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  List<String> get customCategories => List.unmodifiable(_customCategories);

  int get totalCount => _todos.length;
  int get doneCount => _todos.where((item) => item.done).length;
  int get pendingCount => totalCount - doneCount;

  /// 首页按日期分组展示：今天、明天之后按日期升序排列
  List<DateTime> get todoDays {
    final days = <DateTime>{};
    for (final item in _todos) {
      days.add(_dayOnly(item.dueAt));
    }
    final list = days.toList()..sort();
    return list;
  }

  List<TodoItem> todosOn(DateTime day) {
    final items = _todos
        .where((item) => _dayOnly(item.dueAt) == _dayOnly(day))
        .toList();
    return sortTodos(items, sortModeFor(day));
  }

  /// 按排序方式排列：时间升序，或四象限优先级权重升序
  List<TodoItem> sortTodos(List<TodoItem> items, TodoSortMode mode) {
    final sorted = List<TodoItem>.of(items);
    if (mode == TodoSortMode.time) {
      sorted.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    } else {
      sorted.sort((a, b) {
        final rank = priorityRank(a.priority)
            .compareTo(priorityRank(b.priority));
        if (rank != 0) return rank;
        return a.dueAt.compareTo(b.dueAt);
      });
    }
    return sorted;
  }

  TodoSortMode sortModeFor(DateTime day) {
    return _sortModes[_dayKey(day)] ?? TodoSortMode.priority;
  }

  Future<void> setSortMode(DateTime day, TodoSortMode mode) async {
    _sortModes[_dayKey(day)] = mode;
    await _save();
    notifyListeners();
  }

  /// 本周（周一至周日）每天的完成数量，供“我的”页柱状图使用
  List<int> get weekDoneCounts {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final counts = List<int>.filled(7, 0);
    for (final item in _todos) {
      final completedAt = item.completedAt;
      if (completedAt == null) continue;
      final diff = _dayOnly(completedAt).difference(monday).inDays;
      if (diff >= 0 && diff < 7) counts[diff]++;
    }
    return counts;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    _todos.clear();
    if (raw == null) {
      // 首次安装：不预置任何示例待办，交给用户自己创建
      return;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _userName = json['userName'] as String? ?? '张同学';
      _avatarPath = json['avatarPath'] as String?;
      _darkMode = json['darkMode'] as bool? ?? false;
      _notificationsEnabled =
          json['notificationsEnabled'] as bool? ?? false;
      _customCategories
        ..clear()
        ..addAll(
          (json['customCategories'] as List<dynamic>? ?? [])
              .map((e) => e.toString()),
        );
      _sortModes.clear();
      final modes = json['sortModes'] as Map<String, dynamic>? ?? {};
      for (final entry in modes.entries) {
        _sortModes[entry.key] = entry.value == 'time'
            ? TodoSortMode.time
            : TodoSortMode.priority;
      }
      final list = json['todos'] as List<dynamic>? ?? [];
      final items = list
          .map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
          .toList();
      // 1.1.0 及更早版本首次安装会写入示例待办（id 为 t1~t8）。
      // 1.2.0 起不再生成示例，老版本升级时一并清理，保证首页为空白。
      if ((json['schema'] as int? ?? 1) < _schemaVersion) {
        items.removeWhere((item) => _seedIds.contains(item.id));
      }
      _todos.addAll(items);
    } catch (_) {
      _todos.clear();
    }
    await _save();
    notifyListeners();
  }

  Future<void> addTodo(TodoItem item) async {
    _todos.insert(0, item);
    await _save();
    notifyListeners();
  }

  /// 编辑页修改的是同一个实例，这里只需要落盘并通知界面
  Future<void> updateTodo(TodoItem item) async {
    await _save();
    notifyListeners();
  }

  Future<void> toggleDone(TodoItem item) async {
    item.setDone(!item.done);
    await _save();
    notifyListeners();
  }

  /// 勾选 / 取消子任务，并同步父待办的完成状态
  Future<void> toggleSubtask(TodoItem item, int index) async {
    if (index < 0 || index >= item.subtasks.length) return;
    final subtask = item.subtasks[index];
    subtask.done = !subtask.done;
    item.syncDoneWithSubtasks();
    await _save();
    notifyListeners();
  }

  Future<void> addSubtask(TodoItem item, String title) async {
    final name = title.trim();
    if (name.isEmpty) return;
    item.subtasks.add(
      Subtask(id: _newSubtaskId(), title: name),
    );
    item.syncDoneWithSubtasks();
    await _save();
    notifyListeners();
  }

  Future<void> deleteSubtask(TodoItem item, int index) async {
    if (index < 0 || index >= item.subtasks.length) return;
    item.subtasks.removeAt(index);
    item.syncDoneWithSubtasks();
    await _save();
    notifyListeners();
  }

  Future<void> deleteTodo(TodoItem item) async {
    _todos.removeWhere((e) => e.id == item.id);
    await _save();
    notifyListeners();
  }

  Future<void> setUserName(String value) async {
    final name = value.trim();
    if (name.isEmpty) return;
    _userName = name;
    await _save();
    notifyListeners();
  }

  /// 把相册选中的图片复制到应用目录，避免临时文件被系统清理
  Future<void> saveAvatar(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final extension = sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.'))
        : '.jpg';
    final target = File(
      '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}$extension',
    );
    await File(sourcePath).copy(target.path);
    final old = _avatarPath;
    _avatarPath = target.path;
    await _save();
    notifyListeners();
    if (old != null && old != target.path) {
      try {
        await File(old).delete();
      } catch (_) {
        // 旧头像文件已不存在时忽略
      }
    }
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _save();
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _save();
    notifyListeners();
  }

  Future<void> addCustomCategory(String value) async {
    final name = value.trim();
    if (name.isEmpty || _customCategories.contains(name)) return;
    _customCategories.add(name);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'schema': _schemaVersion,
        'userName': _userName,
        'avatarPath': _avatarPath,
        'darkMode': _darkMode,
        'notificationsEnabled': _notificationsEnabled,
        'customCategories': _customCategories,
        'sortModes': {
          for (final entry in _sortModes.entries)
            entry.key: entry.value == TodoSortMode.time ? 'time' : 'priority',
        },
        'todos': _todos.map((e) => e.toJson()).toList(),
      }),
    );
  }

  DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dayKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _newSubtaskId() => 's${DateTime.now().microsecondsSinceEpoch}';

  /// 1.1.0 及更早版本内置的示例待办 id
  static const Set<String> _seedIds = {
    't1',
    't2',
    't3',
    't4',
    't5',
    't6',
    't7',
    't8',
  };
}
