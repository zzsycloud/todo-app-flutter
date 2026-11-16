import 'package:flutter/material.dart';

import 'app_state.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  runApp(TodoApp(state: state));
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key, required this.state});

  final AppState state;

  ThemeData _theme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: brightness,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => MaterialApp(
        title: '今日待办',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: HomePage(state: state),
      ),
    );
  }
}
