import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/app_strings.dart';

const int _dailyReminderId = 0;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    const initSettings = InitializationSettings(
      android: android,
      iOS: ios,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    tz_data.initializeTimeZones();
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // App can listen or use GoRouter to navigate to /home
    }
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<void> scheduleDailyReminder(
    TimeOfDay timeOfDay, {
    int streakCount = 0,
  }) async {
    await _plugin.zonedSchedule(
      _dailyReminderId,
      AppStrings.dailyChallengeReminder,
      streakCount > 0
          ? AppStrings.streakReminder.replaceAll('%d', '$streakCount')
          : 'Keep your streak alive!',
      _nextTimeOfDay(timeOfDay),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily N-Back Reminder',
          channelDescription: 'Daily reminder for N-Back challenge',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextTimeOfDay(TimeOfDay timeOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }
}
