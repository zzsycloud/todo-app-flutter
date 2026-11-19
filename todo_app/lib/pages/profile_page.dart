import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../notification_service.dart';
import '../pages/stats_list_page.dart';
import '../widgets/animated_counter.dart';
import '../widgets/text_input_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.state});

  final AppState state;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _expanded = false;

  static const List<String> _dayLabels = ['一', '二', '三', '四', '五', '六', '日'];
  static const double _expandHeight = 168;
  static const double _maxBarHeight = 72;

  AppState get _state => widget.state;

  /// 本周每天完成数量的柱高：全为 0 时保留一条基线
  List<double> _barHeights() {
    final counts = _state.weekDoneCounts;
    final maxCount = counts.fold<int>(0, (a, b) => b > a ? b : a);
    if (maxCount == 0) return List<double>.filled(7, 2);
    return [
      for (final count in counts)
        count == 0 ? 2 : 14 + (_maxBarHeight - 14) * count / maxCount,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildUser(cs),
          _buildStats(cs),
          _buildExpandCard(cs),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              '偏好设置',
              style: TextStyle(
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          _buildSettings(cs),
          const SizedBox(height: 24),
          Text(
            '版本 1.2.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.33,
              color: cs.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUser(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          InkWell(
            onTap: _pickAvatar,
            customBorder: const CircleBorder(),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: cs.secondaryContainer,
                  backgroundImage: _state.avatarPath == null
                      ? null
                      : FileImage(File(_state.avatarPath!)),
                  child: _state.avatarPath == null
                      ? Icon(
                          Icons.person,
                          size: 32,
                          color: cs.onSecondaryContainer,
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 2),
                    ),
                    child: Icon(
                      Icons.photo_camera,
                      size: 12,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _state.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _editName,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: '修改姓名',
                  visualDensity: VisualDensity.compact,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 1,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            _stat('已完成', _state.doneCount, cs, StatsFilter.done),
            _statDivider(cs),
            _stat('进行中', _state.pendingCount, cs, StatsFilter.pending),
            _statDivider(cs),
            _stat('累计项', _state.totalCount, cs, StatsFilter.all),
          ],
        ),
      ),
    );
  }

  /// 9.1：0 → 目标值计数（Controller + Tween + Curve）
  Widget _stat(
    String label,
    int value,
    ColorScheme cs,
    StatsFilter filter,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StatsListPage(state: _state, filter: filter),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              AnimatedCounter(
                target: value,
                style: TextStyle(
                  fontSize: 22,
                  height: 1.27,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.33,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statDivider(ColorScheme cs) {
    return Container(width: 1, height: 24, color: cs.outlineVariant);
  }

  Widget _buildExpandCard(ColorScheme cs) {
    final counts = _state.weekDoneCounts;
    final weekTotal = counts.fold<int>(0, (a, b) => a + b);
    final todayIndex = DateTime.now().weekday - 1;
    final heights = _barHeights();
    final elapsedDays = todayIndex + 1;
    final dailyAvg = elapsedDays == 0
        ? '0'
        : (weekTotal / elapsedDays).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 1,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '本周完成情况',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '周一至周日 · 本周共 $weekTotal 项',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.33,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          // 9.7 隐式动画：展开高度与柱状条高度同时过渡
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _expanded ? _expandHeight : 0,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(color: Colors.transparent),
            child: SizedBox(
              height: _expandHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 128,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < heights.length; i++)
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    width: 24,
                                    height: _expanded ? heights[i] : 0,
                                    decoration: BoxDecoration(
                                      color: i == todayIndex
                                          ? cs.primary
                                          : cs.primary.withValues(alpha: 0.45),
                                      borderRadius:
                                          const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _dayLabels[i],
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.33,
                                      fontWeight: i == todayIndex
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: i == todayIndex
                                          ? cs.onSurface
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        weekTotal == 0
                            ? '本周还没有完成的待办，勾选一条试试看。'
                            : '本周累计完成 $weekTotal 项，日均 $dailyAvg 项。',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.33,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 1,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.notifications_none, color: cs.onSurfaceVariant),
            title: const Text('通知提醒'),
            value: _state.notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          Divider(height: 1, indent: 56, color: cs.outlineVariant),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: cs.onSurfaceVariant),
            title: const Text('深色模式'),
            value: _state.darkMode,
            onChanged: (value) => _state.setDarkMode(value),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      await _state.saveAvatar(picked.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法打开手机相册：$e')),
      );
    }
  }

  Future<void> _editName() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => TextInputDialog(
        title: '修改姓名',
        hint: '请输入姓名',
        initialValue: _state.userName,
        maxLength: 20,
        confirmLabel: '保存',
      ),
    );
    if (result == null) return;
    await _state.setUserName(result);
  }

  Future<void> _toggleNotifications(bool value) async {
    if (!value) {
      await _state.setNotificationsEnabled(false);
      return;
    }
    final granted = await NotificationService.requestPermission();
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未获得通知权限，请到系统设置中允许通知')),
      );
      return;
    }
    await _state.setNotificationsEnabled(true);
    await NotificationService.show(
      title: '通知提醒已开启',
      body: '之后新增待办时会收到悬浮通知',
    );
  }
}
