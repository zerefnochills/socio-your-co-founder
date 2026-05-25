import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// A service to handle the Daily FCM Standups and local push notifications.
class StandupService {
  static final StandupService _instance = StandupService._internal();
  factory StandupService() => _instance;
  StandupService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezones for scheduled notifications
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // For iOS we might need DarwinInitializationSettings in a real project
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response);
      },
    );
  }

  /// Schedules a daily standup notification at 9:00 AM
  Future<void> scheduleDailyStandup() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'standup_channel_id',
      'Daily Standups',
      channelDescription: 'Reminders for daily startup check-ins',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF6D28D9), // Primary purple
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.zonedSchedule(
      0, // Notification ID
      'Daily Founder Standup ☀️',
      'What is the single blocker keeping you from growing today?',
      _nextInstanceOfNineAM(),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily at this time
      payload: 'standup_prompt',
    );
  }

  /// Calculates the next instance of 9:00 AM
  tz.TZDateTime _nextInstanceOfNineAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    
    // If it's already past 9 AM today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Handles routing when a notification is tapped
  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload == 'standup_prompt') {
      // In a full implementation, this would use a GlobalKey<NavigatorState>
      // or Riverpod's navigation to push the ChatScreen.
      debugPrint("🔔 User tapped standup! Routing to chat to answer blockers.");
    }
  }

  /// Trigger a test notification immediately (useful for debugging)
  Future<void> showTestStandup() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'standup_test_id',
      'Test Standups',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await _localNotifications.show(
      1,
      'Test Standup Triggered',
      'How is your founder mind today? Time to validate!',
      platformDetails,
      payload: 'standup_prompt',
    );
  }
}
