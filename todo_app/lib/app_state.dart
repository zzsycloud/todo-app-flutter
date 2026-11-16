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

  List<TodoItem> get todos => List.unmodifiable(_todos);
  String get userName => _userName;
  String? get avatarPath => _avatarPath;
  bool get darkMode => _darkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get defaultGroup => _defaultGroup;

  int get totalCount => _todos.length;
  int get doneCount => _todos.where((item) => item.done).length;
  int get pendingCount => totalCount - doneCount;

  List<TodoItem> get todayTodos =>
      _todos.where((item) => item.group == '今天').toList();

  List<TodoItem> get tomorrowTodos =>
      _todos.where((item) => item.group == '明天').toList();

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
        'todos': _todos.map((e) => e.toJson()).toList(),
      }),
    );
  }

  List<TodoItem> _seedTodos() {
    final now = DateTime.now();
    TodoItem seed(
      String id,
      String title,
      String time,
      String group,
      String category,
      String priority,
      int daysAgo,
      int hour,
      int minute, {
      bool done = false,
    }) {
      return TodoItem(
        id: id,
        title: title,
        time: time,
        group: group,
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
      seed('t1', '提交移动软件动画课程作业', '今天 18:00', '今天', '学习', '高', 0, 9, 12),
      seed('t2', '整理 Flutter 动画笔记', '今天 20:00', '今天', '学习', '中', 0, 10, 30),
      seed('t3', '给室友带一杯咖啡', '今天 09:30', '今天', '生活', '低', 1, 8, 40, done: true),
      seed('t4', '预约图书馆自习座位', '今天 21:00', '今天', '生活', '中', 2, 11, 5),
      seed('t5', '完成 Hero 转场练习 Demo', '今天 22:00', '今天', '学习', '高', 3, 14, 20),
      seed('t6', '复习 AnimationController 生命周期', '明天 10:00', '明天', '学习', '中', 4, 16, 45),
      seed('t7', '交电费', '明天 12:00', '明天', '生活', '低', 5, 19, 10),
      seed('t8', '小组周会 · 进度对齐', '明天 15:00', '明天', '工作', '高', 6, 20, 0),
    ];
  }
}
