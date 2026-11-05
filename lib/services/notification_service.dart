import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._init();

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notifications.initialize(settings: initSettings);
      _isInitialized = true;
      debugPrint("NotificationService initialisiert.");
    } catch (e) {
      debugPrint("NotificationService init error: $e");
    }
  }

  Future<bool> requestPermission() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  Future<void> showTestNotification({int streak = 0}) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'brush_reminders',
      'Putz-Erinnerungen',
      channelDescription: 'Erinnerung an deine tägliche Zahnreinigung',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);

    final title = streak > 0 ? "🔥 $streak Tage Streak schützen!" : "🦷 Zeit fürs Zähneputzen!";
    const body = "Deine Oclean X Elite wartet auf dich. 2 Minuten für gesunde Zähne.";

    await _notifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // Einstellungen laden
  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('reminder_enabled') ?? false,
      'morning_hour': prefs.getInt('reminder_morning_hour') ?? 8,
      'morning_minute': prefs.getInt('reminder_morning_minute') ?? 0,
      'evening_hour': prefs.getInt('reminder_evening_hour') ?? 21,
      'evening_minute': prefs.getInt('reminder_evening_minute') ?? 30,
    };
  }

  // Einstellungen speichern
  Future<void> saveSettings({
    required bool enabled,
    required int morningHour,
    required int morningMinute,
    required int eveningHour,
    required int eveningMinute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', enabled);
    await prefs.setInt('reminder_morning_hour', morningHour);
    await prefs.setInt('reminder_morning_minute', morningMinute);
    await prefs.setInt('reminder_evening_hour', eveningHour);
    await prefs.setInt('reminder_evening_minute', eveningMinute);
  }
}
