/// 待办的排序方式：按时间 / 按优先级（四象限）
enum TodoSortMode { time, priority }

/// 四象限法则的四个优先级，顺序即排序权重
const List<String> kPriorityLevels = [
  '重要且紧急',
  '重要但不紧急',
  '紧急但不重要',
  '既不重要也不紧急',
];

/// 优先级权重：数值越小越靠前
int priorityRank(String priority) {
  final index = kPriorityLevels.indexOf(priority);
  return index < 0 ? kPriorityLevels.length - 1 : index;
}

/// 子任务：挂在待办下面，勾选情况决定父待办的完成度。
class Subtask {
  Subtask({
    required this.id,
    required this.title,
    this.done = false,
  });

  /// 列表 key 依赖该值，创建后保持不变
  final String id;
  String title;
  bool done;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
  };

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as String? ??
          's${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      done: json['done'] as bool? ?? false,
    );
  }
}

/// 待办数据模型：字段可写入本地存储（JSON）。
class TodoItem {
  TodoItem({
    required this.id,
    required this.title,
    required this.dueAt,
    required this.category,
    required this.priority,
    this.note = '',
    this.done = false,
    DateTime? createdAt,
    List<Subtask>? subtasks,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       subtasks = subtasks ?? <Subtask>[];

  /// Hero tag 依赖该值，创建后保持不变
  final String id;

  String title;

  /// 截止时间（含日期与时刻），分组由它推导
  DateTime dueAt;

  /// 分类：学习 / 生活 / 工作 / 自定义
  String category;

  /// 优先级：四象限法则
  String priority;
  String note;
  bool done;

  /// 创建日期：日历页按此字段统计每天新增的待办
  DateTime createdAt;

  /// 子任务列表，勾选后即时影响完成度
  final List<Subtask> subtasks;

  /// 最近一次标记完成的时间：“我的”页本周完成柱状图按它统计
  DateTime? completedAt;

  /// 今天 / 明天 / 其他（根据 dueAt 实时计算）
  String get group {
    final diff = _dayDiff(dueAt);
    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    return '其他';
  }

  /// 列表里展示的时间文案
  String get time {
    final hour = dueAt.hour.toString().padLeft(2, '0');
    final minute = dueAt.minute.toString().padLeft(2, '0');
    final label = switch (group) {
      '今天' => '今天',
      '明天' => '明天',
      _ => '${dueAt.month} 月 ${dueAt.day} 日',
    };
    return '$label $hour:$minute';
  }

  int get subtaskTotal => subtasks.length;

  int get subtaskDoneCount => subtasks.where((s) => s.done).length;

  bool get hasSubtasks => subtasks.isNotEmpty;

  /// 完成度：有子任务时按子任务勾选比例，没有子任务时按完成状态
  double get progress {
    if (subtasks.isEmpty) return done ? 1 : 0;
    return subtaskDoneCount / subtasks.length;
  }

  /// 完成度百分比（四舍五入到整数）
  int get progressPercent => (progress * 100).round();

  /// 完成度附注文案
  String get progressLabel {
    if (subtasks.isEmpty) return done ? '已完成' : '未开始';
    return '$subtaskDoneCount / ${subtasks.length} 子任务';
  }

  /// 依据子任务勾选情况同步完成状态：全部勾选才算完成
  void syncDoneWithSubtasks() {
    if (subtasks.isEmpty) return;
    final allDone = subtasks.every((s) => s.done);
    if (allDone == done) return;
    done = allDone;
    completedAt = allDone ? DateTime.now() : null;
  }

  /// 整体标记完成 / 未完成：连带勾选或取消所有子任务
  void setDone(bool value) {
    done = value;
    completedAt = value ? DateTime.now() : null;
    for (final subtask in subtasks) {
      subtask.done = value;
    }
  }

  int _dayDiff(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(value.year, value.month, value.day);
    return day.difference(today).inDays;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dueAt': dueAt.toIso8601String(),
    'category': category,
    'priority': priority,
    'note': note,
    'done': done,
    'createdAt': createdAt.toIso8601String(),
    'subtasks': subtasks.map((e) => e.toJson()).toList(),
    if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    final dueAt = _parseDueAt(json);
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      dueAt: dueAt,
      category: json['category'] as String? ?? '学习',
      priority: _normalizePriority(json['priority'] as String?),
      note: json['note'] as String? ?? '',
      done: json['done'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      subtasks: (json['subtasks'] as List<dynamic>? ?? [])
          .map((e) => Subtask.fromJson(e as Map<String, dynamic>))
          .toList(),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }

  /// 兼容 1.0.0 的数据：旧版只有 group + time 文案（如“今天 18:00”）
  static DateTime _parseDueAt(Map<String, dynamic> json) {
    final raw = json['dueAt'] as String?;
    if (raw != null) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    final now = DateTime.now();
    final group = json['group'] as String? ?? '今天';
    final text = json['time'] as String? ?? '';
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text);
    final hour = match == null ? 18 : int.parse(match.group(1)!);
    final minute = match == null ? 0 : int.parse(match.group(2)!);
    final offset = group == '明天' ? 1 : 0;
    return DateTime(now.year, now.month, now.day + offset, hour, minute);
  }

  static String _normalizePriority(String? raw) {
    switch (raw) {
      case '高':
        return '重要且紧急';
      case '中':
        return '重要但不紧急';
      case '低':
        return '既不重要也不紧急';
    }
    if (raw != null && kPriorityLevels.contains(raw)) return raw;
    return '重要但不紧急';
  }
}
