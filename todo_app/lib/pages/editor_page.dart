import 'package:flutter/material.dart';

import '../models/todo_item.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    this.initial,
    required this.onSave,
    this.onDelete,
    this.defaultGroup = '今天',
    this.customCategories = const [],
    this.onAddCategory,
  });

  /// 为空表示新建；不为空表示编辑同一条待办
  final TodoItem? initial;
  final ValueChanged<TodoItem> onSave;
  final VoidCallback? onDelete;

  /// 新建待办时使用的默认分组（在“我的”中设置）
  final String defaultGroup;

  /// 已保存的自定义分类
  final List<String> customCategories;
  final ValueChanged<String>? onAddCategory;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _dueAt;
  late String _category;
  late String _priority;
  bool _titleError = false;

  static const List<String> _defaultCategories = ['学习', '生活', '工作'];

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _titleCtrl = TextEditingController(text: item?.title ?? '');
    _noteCtrl = TextEditingController(text: item?.note ?? '');
    _dueAt = item?.dueAt ?? _defaultDue();
    _category = item?.category ?? _defaultCategories.first;
    _priority = item?.priority ?? '重要但不紧急';
  }

  DateTime _defaultDue() {
    final now = DateTime.now();
    final offset = switch (widget.defaultGroup) {
      '明天' => 1,
      '其他' => 2,
      _ => 0,
    };
    return DateTime(now.year, now.month, now.day + offset, 18, 0);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// 由截止时间推导出的分组（今天 / 明天 / 其他）
  String get _group {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(_dueAt.year, _dueAt.month, _dueAt.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    return '其他';
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = true);
      return;
    }
    final note = _noteCtrl.text.trim();

    if (widget.initial == null) {
      widget.onSave(
        TodoItem(
          id: 't${DateTime.now().microsecondsSinceEpoch}',
          title: title,
          dueAt: _dueAt,
          category: _category,
          priority: _priority,
          note: note,
        ),
      );
    } else {
      final item = widget.initial!;
      item
        ..title = title
        ..dueAt = _dueAt
        ..category = _category
        ..priority = _priority
        ..note = note;
      widget.onSave(item);
    }
    Navigator.of(context).pop(false);
  }

  void _delete() {
    widget.onDelete?.call();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: '关闭',
        ),
        title: Text(widget.initial == null ? '新建待办' : '编辑待办'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _block(
            '标题',
            cs,
            TextField(
              controller: _titleCtrl,
              decoration: _decoration(
                '例如：完成动画课程作业',
                cs,
                error: _titleError,
              ),
              onChanged: (_) {
                if (_titleError) setState(() => _titleError = false);
              },
            ),
          ),
          _block('截止时间', cs, _buildDuePicker(cs)),
          _block(
            '分组',
            cs,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _choice('今天', _group == '今天', () => _selectGroup('今天')),
                _choice('明天', _group == '明天', () => _selectGroup('明天')),
                _choice('其他', _group == '其他', () => _selectGroup('其他')),
              ],
            ),
          ),
          _block('分类', cs, _buildCategoryPicker(cs)),
          _block(
            '优先级（四象限法则）',
            cs,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in kPriorityLevels)
                  _choice(p, _priority == p, () => setState(() => _priority = p)),
              ],
            ),
          ),
          _block(
            '备注',
            cs,
            TextField(
              controller: _noteCtrl,
              maxLines: 4,
              minLines: 3,
              decoration: _decoration('补充说明（可选）', cs),
            ),
          ),
          if (widget.initial != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: TextButton.icon(
                  onPressed: _delete,
                  style: TextButton.styleFrom(foregroundColor: cs.error),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('删除待办'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDuePicker(ColorScheme cs) {
    final hour = _dueAt.hour.toString().padLeft(2, '0');
    final minute = _dueAt.minute.toString().padLeft(2, '0');
    final dateLabel = '${_dueAt.month} 月 ${_dueAt.day} 日';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: Text(dateLabel),
        ),
        OutlinedButton.icon(
          onPressed: _pickTime,
          icon: const Icon(Icons.schedule, size: 18),
          label: Text('$hour:$minute'),
        ),
        if (_group == '其他')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '晚于今天，可自由选择任意日期',
              style: TextStyle(
                fontSize: 12,
                height: 1.33,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryPicker(ColorScheme cs) {
    final categories = [
      ..._defaultCategories,
      ...widget.customCategories,
      if (!_defaultCategories.contains(_category) &&
          !widget.customCategories.contains(_category))
        _category,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in categories)
          _choice(c, _category == c, () => setState(() => _category = c)),
        ChoiceChip(
          label: const Text('自定义'),
          avatar: Icon(Icons.add, size: 18, color: cs.onSurfaceVariant),
          selected: false,
          onSelected: (_) => _addCustomCategory(),
        ),
      ],
    );
  }

  Future<void> _selectGroup(String group) async {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    switch (group) {
      case '今天':
        setState(
          () => _dueAt = DateTime(
            base.year,
            base.month,
            base.day,
            _dueAt.hour,
            _dueAt.minute,
          ),
        );
      case '明天':
        setState(
          () => _dueAt = DateTime(
            base.year,
            base.month,
            base.day + 1,
            _dueAt.hour,
            _dueAt.minute,
          ),
        );
      case '其他':
        final picked = await _pickDate();
        if (picked) setState(() {});
    }
  }

  /// 选择日期，限制不能早于今天
  Future<bool> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final initial = _dueAt.isBefore(firstDate) ? firstDate : _dueAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: '选择截止日期',
    );
    if (picked == null) return false;
    setState(
      () => _dueAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dueAt.hour,
        _dueAt.minute,
      ),
    );
    return true;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
      helpText: '选择截止时刻',
    );
    if (picked == null) return;
    setState(
      () => _dueAt = DateTime(
        _dueAt.year,
        _dueAt.month,
        _dueAt.day,
        picked.hour,
        picked.minute,
      ),
    );
  }

  Future<void> _addCustomCategory() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自定义分类'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 8,
          decoration: const InputDecoration(hintText: '例如：健身、阅读'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    final name = result.trim();
    if (name.isEmpty) return;
    widget.onAddCategory?.call(name);
    setState(() => _category = name);
  }

  Widget _block(String label, ColorScheme cs, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 1.33,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  InputDecoration _decoration(
    String hint,
    ColorScheme cs, {
    bool error = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide.none,
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: cs.error, width: 1),
    );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: cs.surfaceContainerHigh,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: cs.primary, width: 1),
      ),
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      errorText: error ? '请输入待办标题' : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }
}
