import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/todo_item.dart';

/// 全局状态：待办数据、用户资料与偏好设置，统一写入本地存储。
class AppState extends ChangeNotifier {
  static const String _storageKey = 'todo_app_state_v1';

  final List<TodoItem> _todos = [];

  String _userName = '张同学';
  String? _avatarPath;
  bool _darkMode = false;
  bool _notificationsEnabled = false;
  String _defaultGroup = '今天';
  final List<String> _customCategories = [];

  /// 每个日期独立的排序方式，key 为 yyyy-MM-dd
  final Map<String, TodoSortMode> _sortModes = {};

  List<TodoItem> get todos => List.unmodifiable(_todos);
  String get userName => _userName;
  String? get avatarPath => _avatarPath;
  bool get darkMode => _darkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get defaultGroup => _defaultGroup;
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

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _userName = json['userName'] as String? ?? '张同学';
        _avatarPath = json['avatarPath'] as String?;
        _darkMode = json['darkMode'] as bool? ?? false;
        _notificationsEnabled =
            json['notificationsEnabled'] as bool? ?? false;
        _defaultGroup = json['defaultGroup'] as String? ?? '今天';
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
        _todos
          ..clear()
          ..addAll(
            list.map(
              (e) => TodoItem.fromJson(e as Map<String, dynamic>),
            ),
          );
      } catch (_) {
        _todos
          ..clear()
          ..addAll(_seedTodos());
      }
    } else {
      _todos
        ..clear()
        ..addAll(_seedTodos());
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
    item.done = !item.done;
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

  Future<void> setDefaultGroup(String value) async {
    _defaultGroup = value;
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
        'userName': _userName,
        'avatarPath': _avatarPath,
        'darkMode': _darkMode,
        'notificationsEnabled': _notificationsEnabled,
        'defaultGroup': _defaultGroup,
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

  List<TodoItem> _seedTodos() {
    final now = DateTime.now();
    TodoItem seed(
      String id,
      String title,
      int dayOffset,
      int hour,
      int minute,
      String category,
      String priority,
      int daysAgo, {
      bool done = false,
    }) {
      return TodoItem(
        id: id,
        title: title,
        dueAt: DateTime(
          now.year,
          now.month,
          now.day + dayOffset,
          hour,
          minute,
        ),
        category: category,
        priority: priority,
        done: done,
        createdAt: DateTime(
          now.year,
          now.month,
          now.day - daysAgo,
          hour,
          minute,
        ),
      );
    }

    return [
      seed('t1', '提交移动软件动画课程作业', 0, 18, 0, '学习', '重要且紧急', 0),
      seed('t2', '整理 Flutter 动画笔记', 0, 20, 0, '学习', '重要但不紧急', 0),
      seed(
        't3',
        '给室友带一杯咖啡',
        0,
        9,
        30,
        '生活',
        '既不重要也不紧急',
        1,
        done: true,
      ),
      seed('t4', '预约图书馆自习座位', 0, 21, 0, '生活', '紧急但不重要', 2),
      seed('t5', '完成 Hero 转场练习 Demo', 0, 22, 0, '学习', '重要且紧急', 3),
      seed('t6', '复习 AnimationController 生命周期', 1, 10, 0, '学习', '重要但不紧急', 4),
      seed('t7', '交电费', 1, 12, 0, '生活', '既不重要也不紧急', 5),
      seed('t8', '小组周会 · 进度对齐', 2, 15, 0, '工作', '重要且紧急', 6),
    ];
  }
}
