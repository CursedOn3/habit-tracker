import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/habit.dart';
import '../utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap - navigate to habit detail
    // This is handled via app navigation
  }

  Future<bool> requestPermissions() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<void> scheduleHabitReminder(Habit habit) async {
    if (!habit.reminderEnabled || habit.reminderTime == null) return;
    await cancelHabitReminder(habit.id);

    final reminderTime = habit.reminderTime!;

    for (final weekDay in habit.trackDays) {
      final notifId = _getNotificationId(habit.id, weekDay);
      final scheduledTime = _nextWeekdayTime(
        weekDay,
        reminderTime.hour,
        reminderTime.minute,
      );

      await _plugin.zonedSchedule(
        notifId,
        '🎯 Time for: ${habit.title}',
        'Keep your streak going! Goal: ${habit.goalValue} ${habit.goalUnit}',
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.habitReminderChannelId,
            AppConstants.habitReminderChannelName,
            channelDescription: 'Reminders for your habits',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
            color: const Color(0xFF6C63FF),
            styleInformation: BigTextStyleInformation(
              'Keep your streak going! Goal: ${habit.goalValue} ${habit.goalUnit}',
              summaryText: habit.type.displayName,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelHabitReminder(String habitId) async {
    for (int day = 1; day <= 7; day++) {
      await _plugin.cancel(_getNotificationId(habitId, day));
    }
  }

  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.habitReminderChannelId,
          AppConstants.habitReminderChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  tz.TZDateTime _nextWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Find next occurrence of the specified weekday
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _getNotificationId(String habitId, int weekday) {
    // Generate a unique int ID from habit ID + weekday
    return habitId.hashCode.abs() % 100000 + weekday;
  }

  Future<void> scheduleAllReminders(List<Habit> habits) async {
    for (final habit in habits) {
      if (habit.reminderEnabled) {
        await scheduleHabitReminder(habit);
      }
    }
  }
}
