import 'package:flutter/material.dart';

import '../models/todo_item.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({
    super.key,
    this.initial,
    required this.onSave,
    this.onDelete,
    this.defaultGroup = '今天',
  });

  /// 为空表示新建；不为空表示编辑同一条待办
  final TodoItem? initial;
  final ValueChanged<TodoItem> onSave;
  final VoidCallback? onDelete;

  /// 新建待办时使用的默认分组（在“我的”中设置）
  final String defaultGroup;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _noteCtrl;
  late String _group;
  late String _category;
  late String _priority;
  bool _titleError = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _titleCtrl = TextEditingController(text: item?.title ?? '');
    _timeCtrl = TextEditingController(text: item?.time ?? '');
    _noteCtrl = TextEditingController(text: item?.note ?? '');
    _group = item?.group ?? widget.defaultGroup;
    _category = item?.category ?? '学习';
    _priority = item?.priority ?? '中';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = true);
      return;
    }

    final time = _timeCtrl.text.trim().isEmpty
        ? (_group == '明天' ? '明天 12:00' : '今天 18:00')
        : _timeCtrl.text.trim();
    final note = _noteCtrl.text.trim();

    if (widget.initial == null) {
      widget.onSave(
        TodoItem(
          id: 't${DateTime.now().microsecondsSinceEpoch}',
          title: title,
          time: time,
          group: _group,
          category: _category,
          priority: _priority,
          note: note,
        ),
      );
    } else {
      final item = widget.initial!;
      item
        ..title = title
        ..time = time
        ..group = _group
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
          _block(
            '时间',
            cs,
            TextField(
              controller: _timeCtrl,
              decoration: _decoration('今天 18:00', cs),
            ),
          ),
          _block(
            '分组',
            cs,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _choice('今天', _group == '今天',
                    () => setState(() => _group = '今天')),
                _choice('明天', _group == '明天',
                    () => setState(() => _group = '明天')),
              ],
            ),
          ),
          _block(
            '分类',
            cs,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in ['学习', '生活', '工作'])
                  _choice(c, _category == c, () => setState(() => _category = c)),
              ],
            ),
          ),
          _block(
            '优先级',
            cs,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in ['低', '中', '高'])
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
