/// 待办数据模型：字段可写入本地存储（JSON）。
class TodoItem {
  TodoItem({
    required this.id,
    required this.title,
    required this.time,
    required this.group,
    required this.category,
    required this.priority,
    this.note = '',
    this.done = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Hero tag 依赖该值，创建后保持不变
  final String id;

  String title;
  String time;
  String group; // 今天 / 明天
  String category; // 学习 / 生活 / 工作
  String priority; // 低 / 中 / 高
  String note;
  bool done;

  /// 创建日期：日历页按此字段统计每天新增的待办
  DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'time': time,
    'group': group,
    'category': category,
    'priority': priority,
    'note': note,
    'done': done,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    time: json['time'] as String? ?? '',
    group: json['group'] as String? ?? '今天',
    category: json['category'] as String? ?? '学习',
    priority: json['priority'] as String? ?? '中',
    note: json['note'] as String? ?? '',
    done: json['done'] as bool? ?? false,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.now(),
  );
}
