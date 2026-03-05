class AppConstants {
  static const String appName = 'HabitFlow';
  static const String appVersion = '1.0.0';

  // Hive Box Names
  static const String habitsBox = 'habits_box';
  static const String completionsBox = 'completions_box';
  static const String userPrefsBox = 'user_prefs_box';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String habitsCollection = 'habits';
  static const String completionsCollection = 'completions';

  // SharedPrefs Keys
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_done';
  static const String userIdKey = 'user_id';

  // Notification Channels
  static const String habitReminderChannelId = 'habit_reminder';
  static const String habitReminderChannelName = 'Habit Reminders';
  static const int habitReminderNotificationId = 1000;

  // Google Maps
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Replace in production

  // Pagination
  static const int pageSize = 20;

  // Animation Durations
  static const Duration shortAnim = Duration(milliseconds: 200);
  static const Duration mediumAnim = Duration(milliseconds: 350);
  static const Duration longAnim = Duration(milliseconds: 600);

  // Geofence radius in meters
  static const double geofenceRadius = 100.0;

  // Days of week
  static const List<String> weekDaysFull = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  static const List<String> weekDaysShort = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
}
