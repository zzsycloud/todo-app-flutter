import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 本地通知：授权后由 App 直接弹出系统通知（悬浮横幅）。
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static int _nextId = 1;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// 请求通知权限；返回是否获得授权
  static Future<bool> requestPermission() async {
    try {
      await _ensureInitialized();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await android?.requestNotificationsPermission();
        return granted ?? true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> show({
    required String title,
    required String body,
  }) async {
    try {
      await _ensureInitialized();
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_reminders',
          '待办提醒',
          channelDescription: '待办事项与完成状态提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.show(_nextId++, title, body, details);
    } catch (_) {
      // 权限未开启或平台不支持时静默失败，不影响主流程
    }
  }
}
