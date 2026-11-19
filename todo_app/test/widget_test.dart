import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:todo_app/app_state.dart';
import 'package:todo_app/main.dart';
import 'package:todo_app/models/todo_item.dart';
import 'package:todo_app/pages/detail_page.dart';
import 'package:todo_app/pages/profile_page.dart';

/// 把测试窗口设成手机尺寸，保证整页内容都在一屏内
void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('首次启动不预置示例待办，首页显示空状态', (tester) async {
    final state = AppState();
    await state.load();

    await tester.pumpWidget(TodoApp(state: state));
    await tester.pumpAndSettle();

    expect(state.todos, isEmpty);
    expect(find.text('还没有待办'), findsOneWidget);
    expect(find.text('提交移动软件动画课程作业'), findsNothing);
    expect(find.text('已完成 0 / 共 0'), findsOneWidget);
  });

  testWidgets('详情页完成度由子任务推导，不再是固定的 60%', (tester) async {
    usePhoneSurface(tester);
    final state = AppState();
    await state.load();
    final item = TodoItem(
      id: 'item-1',
      title: '写课程报告',
      dueAt: DateTime.now().add(const Duration(hours: 2)),
      category: '学习',
      priority: '重要但不紧急',
      subtasks: [
        Subtask(id: 's1', title: '收集资料'),
        Subtask(id: 's2', title: '写正文'),
      ],
    );
    await state.addTodo(item);

    await tester.pumpWidget(
      MaterialApp(home: DetailPage(state: state, item: item)),
    );
    await tester.pumpAndSettle();

    expect(find.text('0%'), findsOneWidget);
    expect(find.text('60%'), findsNothing);
    expect(find.text('0 / 2 子任务'), findsOneWidget);

    await tester.tap(find.text('收集资料'));
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsOneWidget);
    expect(item.done, isFalse);

    await tester.tap(find.text('写正文'));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
    expect(item.done, isTrue);
    expect(item.completedAt, isNotNull);
  });

  testWidgets('详情页可以添加子任务，完成度随之变化', (tester) async {
    usePhoneSurface(tester);
    final state = AppState();
    await state.load();
    final item = TodoItem(
      id: 'item-2',
      title: '准备答辩',
      dueAt: DateTime.now(),
      category: '学习',
      priority: '重要且紧急',
    );
    await state.addTodo(item);

    await tester.pumpWidget(
      MaterialApp(home: DetailPage(state: state, item: item)),
    );
    await tester.pumpAndSettle();

    // 没有子任务时完成度按勾选状态计算
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('未开始'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '添加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '整理讲稿');
    await tester.tap(find.widgetWithText(FilledButton, '添加'));
    await tester.pumpAndSettle();

    expect(item.subtasks.length, 1);
    expect(find.text('整理讲稿'), findsOneWidget);
    expect(find.text('0 / 1 子任务'), findsOneWidget);

    await tester.tap(find.text('整理讲稿'));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
    expect(item.done, isTrue);
  });

  testWidgets('“我的”页移除默认分组，版本号同步到 1.2.0', (tester) async {
    usePhoneSurface(tester);
    final state = AppState();
    await state.load();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ProfilePage(state: state))),
    );
    await tester.pumpAndSettle();

    expect(find.text('默认分组'), findsNothing);
    expect(find.text('版本 1.2.0'), findsOneWidget);
    expect(find.text('本周完成情况'), findsOneWidget);
    expect(find.text('周一至周日 · 本周共 0 项'), findsOneWidget);
  });
}
