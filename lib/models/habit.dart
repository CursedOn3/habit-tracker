import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
enum HabitType {
  @HiveField(0)
  readBook,
  @HiveField(1)
  exercise,
  @HiveField(2)
  run,
  @HiveField(3)
  sleep,
  @HiveField(4)
  custom,
}

extension HabitTypeExtension on HabitType {
  String get displayName {
    switch (this) {
      case HabitType.readBook:
        return 'Read Book';
      case HabitType.exercise:
        return 'Exercise';
      case HabitType.run:
        return 'Run';
      case HabitType.sleep:
        return 'Sleep';
      case HabitType.custom:
        return 'Custom';
    }
  }

  String get goalUnit {
    switch (this) {
      case HabitType.readBook:
        return 'pages';
      case HabitType.exercise:
        return 'mins';
      case HabitType.run:
        return 'km';
      case HabitType.sleep:
        return 'hours';
      case HabitType.custom:
        return 'units';
    }
  }

  String get icon {
    switch (this) {
      case HabitType.readBook:
        return '📚';
      case HabitType.exercise:
        return '💪';
      case HabitType.run:
        return '🏃';
      case HabitType.sleep:
        return '😴';
      case HabitType.custom:
        return '⭐';
    }
  }
}

@HiveType(typeId: 1)
enum GoalPeriod {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
}

extension GoalPeriodExtension on GoalPeriod {
  String get displayName {
    switch (this) {
      case GoalPeriod.daily:
        return 'Daily';
      case GoalPeriod.weekly:
        return 'Weekly';
      case GoalPeriod.monthly:
        return 'Monthly';
    }
  }
}

@HiveType(typeId: 2)
class HabitLocation extends HiveObject {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final String? address;

  HabitLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };

  factory HabitLocation.fromMap(Map<String, dynamic> map) => HabitLocation(
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    address: map['address'] as String?,
  );
}

@HiveType(typeId: 3)
class Habit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  HabitType type;

  @HiveField(3)
  GoalPeriod goalPeriod;

  @HiveField(4)
  double goalValue;

  @HiveField(5)
  List<int> trackDays; // 0=Mon, 1=Tue, ... 6=Sun

  @HiveField(6)
  String? startTime; // "HH:mm"

  @HiveField(7)
  String? endTime; // "HH:mm"

  @HiveField(8)
  String? reminderTime; // "HH:mm"

  @HiveField(9)
  bool reminderEnabled;

  @HiveField(10)
  bool locationEnabled;

  @HiveField(11)
  HabitLocation? location;

  @HiveField(12)
  Map<String, double> completions; // "yyyy-MM-dd" -> value

  @HiveField(13)
  DateTime createdAt;

  @HiveField(14)
  String? userId;

  @HiveField(15)
  int colorIndex;

  @HiveField(16)
  String? customUnit;

  Habit({
    required this.id,
    required this.title,
    required this.type,
    required this.goalPeriod,
    required this.goalValue,
    required this.trackDays,
    this.startTime,
    this.endTime,
    this.reminderTime,
    this.reminderEnabled = false,
    this.locationEnabled = false,
    this.location,
    Map<String, double>? completions,
    DateTime? createdAt,
    this.userId,
    this.colorIndex = 0,
    this.customUnit,
  }) : completions = completions ?? {},
       createdAt = createdAt ?? DateTime.now();

  String get goalUnit =>
      type == HabitType.custom ? (customUnit ?? 'units') : type.goalUnit;

  double getCompletionForDate(DateTime date) {
    final key = _dateKey(date);
    return completions[key] ?? 0.0;
  }

  bool isCompletedForDate(DateTime date) {
    return getCompletionForDate(date) >= goalValue;
  }

  double getProgressForDate(DateTime date) {
    if (goalValue <= 0) return 0.0;
    return (getCompletionForDate(date) / goalValue).clamp(0.0, 1.0);
  }

  void logCompletion(DateTime date, double value) {
    completions[_dateKey(date)] = value;
  }

  int get currentStreak {
    int streak = 0;
    DateTime date = DateTime.now();
    while (true) {
      if (isCompletedForDate(date)) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  bool isScheduledForDay(DateTime date) {
    if (trackDays.isEmpty) return true;
    final weekday = date.weekday - 1; // 0=Mon
    return trackDays.contains(weekday);
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'type': type.index,
    'goalPeriod': goalPeriod.index,
    'goalValue': goalValue,
    'trackDays': trackDays,
    'startTime': startTime,
    'endTime': endTime,
    'reminderTime': reminderTime,
    'reminderEnabled': reminderEnabled,
    'locationEnabled': locationEnabled,
    'location': location?.toMap(),
    'completions': completions,
    'createdAt': createdAt.toIso8601String(),
    'userId': userId,
    'colorIndex': colorIndex,
    'customUnit': customUnit,
  };

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      title: map['title'] as String,
      type: HabitType.values[map['type'] as int],
      goalPeriod: GoalPeriod.values[map['goalPeriod'] as int],
      goalValue: (map['goalValue'] as num).toDouble(),
      trackDays: List<int>.from(map['trackDays'] as List),
      startTime: map['startTime'] as String?,
      endTime: map['endTime'] as String?,
      reminderTime: map['reminderTime'] as String?,
      reminderEnabled: map['reminderEnabled'] as bool? ?? false,
      locationEnabled: map['locationEnabled'] as bool? ?? false,
      location:
          map['location'] != null
              ? HabitLocation.fromMap(
                Map<String, dynamic>.from(map['location'] as Map),
              )
              : null,
      completions: Map<String, double>.from(
        (map['completions'] as Map? ?? {}).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      userId: map['userId'] as String?,
      colorIndex: map['colorIndex'] as int? ?? 0,
      customUnit: map['customUnit'] as String?,
    );
  }

  Habit copyWith({
    String? id,
    String? title,
    HabitType? type,
    GoalPeriod? goalPeriod,
    double? goalValue,
    List<int>? trackDays,
    String? startTime,
    String? endTime,
    String? reminderTime,
    bool? reminderEnabled,
    bool? locationEnabled,
    HabitLocation? location,
    Map<String, double>? completions,
    DateTime? createdAt,
    String? userId,
    int? colorIndex,
    String? customUnit,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      goalPeriod: goalPeriod ?? this.goalPeriod,
      goalValue: goalValue ?? this.goalValue,
      trackDays: trackDays ?? List<int>.from(this.trackDays),
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      location: location ?? this.location,
      completions: completions ?? Map<String, double>.from(this.completions),
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      colorIndex: colorIndex ?? this.colorIndex,
      customUnit: customUnit ?? this.customUnit,
    );
  }
}
