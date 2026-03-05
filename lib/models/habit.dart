import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

part 'habit.g.dart';

@HiveType(typeId: 1)
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
  custom;

  String get displayName {
    switch (this) {
      case HabitType.readBook: return 'Read Book';
      case HabitType.exercise: return 'Exercise';
      case HabitType.run: return 'Run';
      case HabitType.sleep: return 'Sleep';
      case HabitType.custom: return 'Custom';
    }
  }

  String get defaultUnit {
    switch (this) {
      case HabitType.readBook: return 'pages';
      case HabitType.exercise: return 'mins';
      case HabitType.run: return 'km';
      case HabitType.sleep: return 'hours';
      case HabitType.custom: return 'units';
    }
  }

  String get icon {
    switch (this) {
      case HabitType.readBook: return '📚';
      case HabitType.exercise: return '💪';
      case HabitType.run: return '🏃';
      case HabitType.sleep: return '😴';
      case HabitType.custom: return '⭐';
    }
  }

  Color get color {
    switch (this) {
      case HabitType.readBook: return const Color(0xFF6C63FF);
      case HabitType.exercise: return const Color(0xFF43E97B);
      case HabitType.run: return const Color(0xFFFF6584);
      case HabitType.sleep: return const Color(0xFF4FC3F7);
      case HabitType.custom: return const Color(0xFFFF9F43);
    }
  }

  String get goalLabel {
    switch (this) {
      case HabitType.readBook: return 'Pages to read';
      case HabitType.exercise: return 'Minutes to exercise';
      case HabitType.run: return 'Distance (km)';
      case HabitType.sleep: return 'Hours of sleep';
      case HabitType.custom: return 'Goal value';
    }
  }
}

@HiveType(typeId: 2)
enum GoalPeriod {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly;

  String get displayName {
    switch (this) {
      case GoalPeriod.daily: return 'Daily';
      case GoalPeriod.weekly: return 'Weekly';
      case GoalPeriod.monthly: return 'Monthly';
    }
  }
}

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  String title;

  @HiveField(3)
  HabitType type;

  @HiveField(4)
  GoalPeriod goalPeriod;

  @HiveField(5)
  double goalValue;

  @HiveField(6)
  String goalUnit;

  @HiveField(7)
  List<int> trackDays; // 1=Mon, 7=Sun (ISO weekday)

  @HiveField(8)
  DateTime? startTime;

  @HiveField(9)
  DateTime? endTime;

  @HiveField(10)
  DateTime? reminderTime;

  @HiveField(11)
  bool reminderEnabled;

  @HiveField(12)
  bool locationEnabled;

  @HiveField(13)
  double? locationLat;

  @HiveField(14)
  double? locationLng;

  @HiveField(15)
  String? locationName;

  @HiveField(16)
  DateTime createdAt;

  @HiveField(17)
  DateTime updatedAt;

  @HiveField(18)
  int colorIndex;

  @HiveField(19)
  bool isArchived;

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.goalPeriod,
    required this.goalValue,
    required this.goalUnit,
    required this.trackDays,
    this.startTime,
    this.endTime,
    this.reminderTime,
    this.reminderEnabled = false,
    this.locationEnabled = false,
    this.locationLat,
    this.locationLng,
    this.locationName,
    required this.createdAt,
    required this.updatedAt,
    this.colorIndex = 0,
    this.isArchived = false,
  });

  bool isScheduledForDay(DateTime date) {
    return trackDays.contains(date.weekday);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'type': type.name,
      'goalPeriod': goalPeriod.name,
      'goalValue': goalValue,
      'goalUnit': goalUnit,
      'trackDays': trackDays,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'reminderTime': reminderTime?.toIso8601String(),
      'reminderEnabled': reminderEnabled,
      'locationEnabled': locationEnabled,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'locationName': locationName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'colorIndex': colorIndex,
      'isArchived': isArchived,
    };
  }

  factory Habit.fromFirestore(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      type: HabitType.values.firstWhere((e) => e.name == map['type']),
      goalPeriod: GoalPeriod.values.firstWhere((e) => e.name == map['goalPeriod']),
      goalValue: (map['goalValue'] as num).toDouble(),
      goalUnit: map['goalUnit'] as String,
      trackDays: List<int>.from(map['trackDays'] as List),
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime'] as String) : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      reminderTime: map['reminderTime'] != null ? DateTime.parse(map['reminderTime'] as String) : null,
      reminderEnabled: map['reminderEnabled'] as bool? ?? false,
      locationEnabled: map['locationEnabled'] as bool? ?? false,
      locationLat: (map['locationLat'] as num?)?.toDouble(),
      locationLng: (map['locationLng'] as num?)?.toDouble(),
      locationName: map['locationName'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      colorIndex: map['colorIndex'] as int? ?? 0,
      isArchived: map['isArchived'] as bool? ?? false,
    );
  }

  Habit copyWith({
    String? title,
    HabitType? type,
    GoalPeriod? goalPeriod,
    double? goalValue,
    String? goalUnit,
    List<int>? trackDays,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? reminderTime,
    bool? reminderEnabled,
    bool? locationEnabled,
    double? locationLat,
    double? locationLng,
    String? locationName,
    DateTime? updatedAt,
    int? colorIndex,
    bool? isArchived,
  }) {
    return Habit(
      id: id,
      userId: userId,
      title: title ?? this.title,
      type: type ?? this.type,
      goalPeriod: goalPeriod ?? this.goalPeriod,
      goalValue: goalValue ?? this.goalValue,
      goalUnit: goalUnit ?? this.goalUnit,
      trackDays: trackDays ?? this.trackDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      locationName: locationName ?? this.locationName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      colorIndex: colorIndex ?? this.colorIndex,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}

@HiveType(typeId: 3)
class HabitCompletion extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String habitId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  double value;

  @HiveField(5)
  String? note;

  @HiveField(6)
  final DateTime createdAt;

  HabitCompletion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    required this.value,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'habitId': habitId,
      'userId': userId,
      'date': date.toIso8601String(),
      'value': value,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HabitCompletion.fromFirestore(Map<String, dynamic> map) {
    return HabitCompletion(
      id: map['id'] as String,
      habitId: map['habitId'] as String,
      userId: map['userId'] as String,
      date: DateTime.parse(map['date'] as String),
      value: (map['value'] as num).toDouble(),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
