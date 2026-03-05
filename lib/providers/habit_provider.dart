import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../services/notification_service.dart';

final habitServiceProvider = Provider<HabitService>((ref) => HabitService());

final habitsProvider = StateNotifierProvider.family<HabitsNotifier, AsyncValue<List<Habit>>, String>(
  (ref, userId) => HabitsNotifier(
    ref.watch(habitServiceProvider),
    ref.watch(notificationServiceProvider),
    userId,
  ),
);

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

final todayHabitsProvider = Provider.family<List<Habit>, String>((ref, userId) {
  final habitsAsync = ref.watch(habitsProvider(userId));
  return habitsAsync.when(
    data: (habits) {
      final today = DateTime.now();
      return habits.where((h) => h.isScheduledForDay(today)).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final habitCompletionsProvider = Provider.family<List<HabitCompletion>, String>((ref, habitId) {
  final service = ref.watch(habitServiceProvider);
  return service.getCompletionsForHabit(habitId);
});

final todayProgressProvider = Provider.family<double, ({String habitId, double goalValue})>((ref, args) {
  final service = ref.watch(habitServiceProvider);
  return service.getTodayProgress(args.habitId, args.goalValue);
});

final habitStreakProvider = Provider.family<int, ({String habitId, String userId})>((ref, args) {
  final service = ref.watch(habitServiceProvider);
  final habitsAsync = ref.watch(habitsProvider(args.userId));
  return habitsAsync.when(
    data: (habits) {
      try {
        final habit = habits.firstWhere((h) => h.id == args.habitId);
        return service.calculateStreak(args.habitId, habit);
      } catch (_) {
        return 0;
      }
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final weeklyChartDataProvider = Provider.family<List<double>, ({String habitId, String userId})>((ref, args) {
  final service = ref.watch(habitServiceProvider);
  final habitsAsync = ref.watch(habitsProvider(args.userId));
  return habitsAsync.when(
    data: (habits) {
      try {
        final habit = habits.firstWhere((h) => h.id == args.habitId);
        return service.getWeeklyCompletionData(args.habitId, habit);
      } catch (_) {
        return List.filled(7, 0.0);
      }
    },
    loading: () => List.filled(7, 0.0),
    error: (_, __) => List.filled(7, 0.0),
  );
});

final overallWeeklyDataProvider = Provider.family<List<double>, String>((ref, userId) {
  final service = ref.watch(habitServiceProvider);
  final habits = service.getHabitsForToday(userId);
  if (habits.isEmpty) return List.filled(7, 0.0);

  final now = DateTime.now();
  // Monday = 1, Sunday = 7
  final weekStart = now.subtract(Duration(days: now.weekday - 1));

  return List.generate(7, (i) {
    final day = weekStart.add(Duration(days: i));
    final dayHabits = habits.where((h) => h.isScheduledForDay(day)).toList();
    if (dayHabits.isEmpty) return 0.0;

    double total = 0;
    for (final h in dayHabits) {
      final c = service.getCompletionForDate(h.id, day);
      if (c != null && c.value >= h.goalValue) total += 1;
    }
    return total / dayHabits.length;
  });
});

class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final HabitService _service;
  final NotificationService _notificationService;
  final String _userId;

  HabitsNotifier(this._service, this._notificationService, this._userId)
      : super(const AsyncValue.loading()) {
    _loadHabits();
  }

  void _loadHabits() {
    try {
      final habits = _service.getHabitsForUser(_userId);
      state = AsyncValue.data(habits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Habit> addHabit({
    required String title,
    required HabitType type,
    required GoalPeriod goalPeriod,
    required double goalValue,
    required String goalUnit,
    required List<int> trackDays,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? reminderTime,
    bool reminderEnabled = false,
    bool locationEnabled = false,
    double? locationLat,
    double? locationLng,
    String? locationName,
    int colorIndex = 0,
  }) async {
    final habit = await _service.createHabit(
      userId: _userId,
      title: title,
      type: type,
      goalPeriod: goalPeriod,
      goalValue: goalValue,
      goalUnit: goalUnit,
      trackDays: trackDays,
      startTime: startTime,
      endTime: endTime,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
      locationEnabled: locationEnabled,
      locationLat: locationLat,
      locationLng: locationLng,
      locationName: locationName,
      colorIndex: colorIndex,
    );

    if (reminderEnabled && reminderTime != null) {
      await _notificationService.scheduleHabitReminder(habit);
    }

    _loadHabits();
    return habit;
  }

  Future<void> updateHabit(Habit habit) async {
    await _service.updateHabit(habit);
    if (habit.reminderEnabled && habit.reminderTime != null) {
      await _notificationService.scheduleHabitReminder(habit);
    } else {
      await _notificationService.cancelHabitReminder(habit.id);
    }
    _loadHabits();
  }

  Future<void> deleteHabit(String habitId) async {
    await _notificationService.cancelHabitReminder(habitId);
    await _service.deleteHabit(habitId, _userId);
    _loadHabits();
  }

  Future<HabitCompletion> logCompletion({
    required String habitId,
    required DateTime date,
    required double value,
    String? note,
  }) async {
    final completion = await _service.logCompletion(
      habitId: habitId,
      userId: _userId,
      date: date,
      value: value,
      note: note,
    );
    _loadHabits();
    return completion;
  }

  Future<void> syncFromFirestore() async {
    await _service.syncFromFirestore(_userId);
    _loadHabits();
  }

  void refresh() => _loadHabits();
}
