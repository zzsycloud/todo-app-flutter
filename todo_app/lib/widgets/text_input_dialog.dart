import 'package:flutter/material.dart';

/// 单行文本输入对话框。
///
/// 控制器由对话框自己持有，在对话框真正销毁时才释放：如果调用方在
/// showDialog 返回后立即 dispose，关闭动画期间重建 TextField 会访问到
/// 已释放的控制器并抛异常。
class TextInputDialog extends StatefulWidget {
  const TextInputDialog({
    super.key,
    required this.title,
    this.hint,
    this.initialValue = '',
    this.maxLength = 20,
    this.confirmLabel = '保存',
  });

  final String title;
  final String? hint;
  final String initialValue;
  final int maxLength;
  final String confirmLabel;

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
