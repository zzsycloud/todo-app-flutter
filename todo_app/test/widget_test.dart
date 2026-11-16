import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:todo_app/app_state.dart';
import 'package:todo_app/main.dart';

void main() {
  testWidgets('首页渲染待办列表', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();

    await tester.pumpWidget(TodoApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('待办事项'), findsOneWidget);
    expect(find.text('提交移动软件动画课程作业'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });
}
