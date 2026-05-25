import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Payload constants
const String _kMorningPayload = 'standup_morning';
const String _kEveningPayload = 'standup_evening';

// Notification IDs
const int _kMorningId = 100;
const int _kEveningId = 101;

/// Callback set by main.dart to switch tabs when a notification is tapped.
/// Index 0 = Chat, 1 = Pipeline, 2 = Outreach, 3 = Tracker, 4 = Mood
typedef TabSwitcher = void Function(int tabIndex);

class StandupService {
  static final StandupService _instance = StandupService._internal();
  factory StandupService() => _instance;
  StandupService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Set this from main.dart after ProviderScope is ready.
  /// Called with tab index 0 (Chat) when a standup notification is tapped.
  static TabSwitcher? onNotificationTap;

  // ─── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    // Handle FCM foreground messages (app is open)
    FirebaseMessaging.onMessage.listen(_onFcmForegroundMessage);

    // Handle FCM notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_onFcmNotificationOpened);
  }

  // ─── Permission Request ──────────────────────────────────────────────────────

  /// Call this after the user completes onboarding to request notification permission.
  Future<bool> requestPermissions() async {
    // Android 13+ (API 33+) requires explicit POST_NOTIFICATIONS permission
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    bool granted = false;
    if (androidPlugin != null) {
      granted = await androidPlugin.requestNotificationsPermission() ?? false;
    }

    // iOS permission
    final IOSFlutterLocalNotificationsPlugin? iosPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    // Also request FCM permission (iOS + Android 13+)
    final NotificationSettings fcmSettings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
        'FCM permission: ${fcmSettings.authorizationStatus}, Local: $granted');
    return granted;
  }

  // ─── Schedule Notifications ──────────────────────────────────────────────────

  /// Schedules both morning (9 AM) and evening (9 PM) daily standups.
  Future<void> scheduleDailyStandups() async {
    await _scheduleMorningStandup();
    await _scheduleEveningCheckin();
    debugPrint('StandupService: Both daily standups scheduled.');
  }

  Future<void> _scheduleMorningStandup() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'standup_morning_channel',
      'Morning Standup',
      channelDescription: 'Daily 9 AM founder check-in',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF0B3A22),
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _localNotifications.zonedSchedule(
      _kMorningId,
      'Good morning. Time to focus.',
      'What is the single biggest blocker keeping you from growing today?',
      _nextInstanceOf(9, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _kMorningPayload,
    );
  }

  Future<void> _scheduleEveningCheckin() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'standup_evening_channel',
      'Evening Check-in',
      channelDescription: 'Daily 9 PM founder wind-down',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: Color(0xFF6D28D9),
      enableVibration: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _localNotifications.zonedSchedule(
      _kEveningId,
      'End-of-day check-in',
      'What got done? What got blocked? Socio is ready to debrief.',
      _nextInstanceOf(21, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _kEveningPayload,
    );
  }

  // ─── Cancel ─────────────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
    debugPrint('StandupService: All notifications cancelled.');
  }

  // ─── Test Notifications (for demo) ──────────────────────────────────────────

  /// Fire a morning standup notification immediately — use this in the demo.
  Future<void> showTestMorningStandup() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'standup_test_channel',
      'Test Standup',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFF0B3A22),
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      _kMorningId + 10,
      'Good morning. Time to focus.',
      'What is the single biggest blocker keeping you from growing today?',
      details,
      payload: _kMorningPayload,
    );
  }

  /// Fire an evening check-in notification immediately — use this in the demo.
  Future<void> showTestEveningCheckin() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'standup_test_channel',
      'Test Check-in',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: Color(0xFF6D28D9),
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      _kEveningId + 10,
      'End-of-day check-in',
      'What got done? What got blocked? Socio is ready to debrief.',
      details,
      payload: _kEveningPayload,
    );
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    _routeFromPayload(response.payload);
  }

  void _onFcmForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground message: ${message.notification?.title}');
    // Show a local notification for foreground FCM messages
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        999,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_channel',
            'Socio Notifications',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFF0B3A22),
          ),
        ),
        payload: message.data['payload'] ?? _kMorningPayload,
      );
    }
  }

  void _onFcmNotificationOpened(RemoteMessage message) {
    debugPrint('FCM notification opened: ${message.notification?.title}');
    _routeFromPayload(message.data['payload'] ?? _kMorningPayload);
  }

  void _routeFromPayload(String? payload) {
    // Both morning and evening route to Chat tab (index 0)
    if (payload == _kMorningPayload || payload == _kEveningPayload) {
      onNotificationTap?.call(0);
    }
  }
}

// Top-level function required by flutter_local_notifications for background taps
@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse response) {
  // Background taps can't call Riverpod — store the intent for next launch
  debugPrint('Background notification tapped: ${response.payload}');
}