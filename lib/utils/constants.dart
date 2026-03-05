class AppConstants {
  static const String appName = 'HabitFlow';
  static const String appVersion = '1.0.0';

  // Hive boxes
  static const String habitsBox = 'habits';
  static const String completionsBox = 'completions';
  static const String settingsBox = 'settings';

  // Settings keys
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_done';
  static const String notificationsEnabledKey = 'notifications_enabled';

  // Notification channels
  static const String habitReminderChannelId = 'habit_reminders';
  static const String habitReminderChannelName = 'Habit Reminders';
  static const String habitReminderChannelDesc =
      'Notifications to remind you of your habits';

  // Google Maps placeholder API key
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // Days of the week
  static const List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> weekDaysFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
}
