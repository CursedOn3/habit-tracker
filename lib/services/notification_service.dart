import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import '../models/habit.dart';
import '../utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createNotificationChannel();
    _initialized = true;
  }

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      AppConstants.habitReminderChannelId,
      AppConstants.habitReminderChannelName,
      description: AppConstants.habitReminderChannelDesc,
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - navigate to habit
  }

  Future<bool> requestPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    bool granted = false;
    if (android != null) {
      final result = await android.requestNotificationsPermission();
      granted = result ?? false;
    }
    if (ios != null) {
      final result = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = result ?? false;
    }
    return granted;
  }

  Future<void> scheduleHabitReminder(Habit habit) async {
    if (!habit.reminderEnabled || habit.reminderTime == null) return;

    final parts = habit.reminderTime!.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    for (final dayIndex in habit.trackDays) {
      final notificationId = _generateNotificationId(habit.id, dayIndex);

      await _notifications.zonedSchedule(
        notificationId,
        '🎯 Time for ${habit.title}!',
        'Your goal: ${habit.goalValue} ${habit.goalUnit}. Keep the streak going!',
        _nextInstanceOfDayTime(dayIndex, hour, minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.habitReminderChannelId,
            AppConstants.habitReminderChannelName,
            channelDescription: AppConstants.habitReminderChannelDesc,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(
              'Your goal: ${habit.goalValue} ${habit.goalUnit}. Keep the streak going!',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelHabitReminders(Habit habit) async {
    for (int i = 0; i < 7; i++) {
      final notificationId = _generateNotificationId(habit.id, i);
      await _notifications.cancel(notificationId);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await _notifications.show(
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
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfDayTime(int dayIndex, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    // dayIndex: 0=Mon, 6=Sun; DateTime weekday: 1=Mon, 7=Sun
    final targetWeekday = dayIndex + 1;
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduled.weekday != targetWeekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _generateNotificationId(String habitId, int dayIndex) {
    return '${habitId}_$dayIndex'.hashCode.abs() % 100000;
  }
}
