import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

final habitServiceProvider = Provider<HabitService>((ref) => HabitService());

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

class HabitState {
  final List<Habit> habits;
  final bool isLoading;
  final String? error;

  const HabitState({
    this.habits = const [],
    this.isLoading = false,
    this.error,
  });

  HabitState copyWith({
    List<Habit>? habits,
    bool? isLoading,
    String? error,
  }) {
    return HabitState(
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HabitNotifier extends StateNotifier<HabitState> {
  final HabitService _habitService;
  final NotificationService _notificationService;
  final String? userId;

  HabitNotifier(this._habitService, this._notificationService, this.userId)
    : super(const HabitState(isLoading: true)) {
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      await _habitService.init();
      final habits = _habitService.getLocalHabits(userId: userId);
      state = HabitState(habits: habits);

      // Sync from Firestore if logged in
      if (userId != null) {
        await _habitService.syncFromFirestore(userId!);
        final synced = _habitService.getLocalHabits(userId: userId);
        state = HabitState(habits: synced);
      }
    } catch (e) {
      state = HabitState(error: e.toString());
    }
  }

  Future<void> addHabit(Habit habit) async {
    final newHabit = habit.copyWith(
      id: const Uuid().v4(),
      userId: userId,
    );

    await _habitService.saveHabitLocally(newHabit);

    if (userId != null) {
      await _habitService.syncHabitToFirestore(newHabit);
    }

    if (newHabit.reminderEnabled) {
      await _notificationService.scheduleHabitReminder(newHabit);
    }

    state = state.copyWith(habits: [...state.habits, newHabit]);
  }

  Future<void> updateHabit(Habit habit) async {
    await _habitService.saveHabitLocally(habit);

    if (userId != null) {
      await _habitService.syncHabitToFirestore(habit);
    }

    // Update notifications
    await _notificationService.cancelHabitReminders(habit);
    if (habit.reminderEnabled) {
      await _notificationService.scheduleHabitReminder(habit);
    }

    final index = state.habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      final updatedHabits = [...state.habits];
      updatedHabits[index] = habit;
      state = state.copyWith(habits: updatedHabits);
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final habit = state.habits.firstWhere((h) => h.id == habitId);
    await _notificationService.cancelHabitReminders(habit);
    await _habitService.deleteHabitLocally(habitId);

    if (userId != null) {
      await _habitService.deleteHabitFromFirestore(userId!, habitId);
    }

    state = state.copyWith(
      habits: state.habits.where((h) => h.id != habitId).toList(),
    );
  }

  Future<void> logCompletion(
    String habitId,
    DateTime date,
    double value,
  ) async {
    await _habitService.updateCompletionLocally(habitId, date, value);

    final index = state.habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final habit = state.habits[index];
      habit.logCompletion(date, value);

      if (userId != null) {
        await _habitService.syncHabitToFirestore(habit);
      }

      final updatedHabits = [...state.habits];
      updatedHabits[index] = habit;
      state = state.copyWith(habits: updatedHabits);
    }
  }

  Future<void> toggleCompletion(String habitId, DateTime date) async {
    final habit = state.habits.firstWhere((h) => h.id == habitId);
    final current = habit.getCompletionForDate(date);
    final newValue = current >= habit.goalValue ? 0.0 : habit.goalValue;
    await logCompletion(habitId, date, newValue);
  }

  Future<void> refreshHabits() async {
    await _loadHabits();
  }

  // Chart data helpers
  List<double> getWeeklyCompletionData() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (i) {
      final day = weekStart.add(Duration(days: i));
      final dayHabits =
          state.habits.where((h) => h.isScheduledForDay(day)).toList();
      if (dayHabits.isEmpty) return 0.0;
      final completed = dayHabits.where((h) => h.isCompletedForDate(day)).length;
      return completed / dayHabits.length;
    });
  }

  List<double> getMonthlyProgressData() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return List.generate(daysInMonth, (i) {
      final day = DateTime(now.year, now.month, i + 1);
      if (day.isAfter(now)) return -1.0; // Future day
      final dayHabits =
          state.habits.where((h) => h.isScheduledForDay(day)).toList();
      if (dayHabits.isEmpty) return 0.0;
      final completed =
          dayHabits.where((h) => h.isCompletedForDate(day)).length;
      return completed / dayHabits.length;
    });
  }

  List<Habit> getTodaysHabits() {
    final today = DateTime.now();
    return state.habits.where((h) => h.isScheduledForDay(today)).toList();
  }

  int getTotalStreak() {
    if (state.habits.isEmpty) return 0;
    return state.habits.fold(0, (sum, h) => sum + h.currentStreak);
  }
}

final habitNotifierProvider =
    StateNotifierProvider<HabitNotifier, HabitState>((ref) {
  final habitService = ref.watch(habitServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  return HabitNotifier(habitService, notificationService, userId);
});

// Convenience providers
final todaysHabitsProvider = Provider<List<Habit>>((ref) {
  return ref.watch(habitNotifierProvider.notifier).getTodaysHabits();
});

final weeklyDataProvider = Provider<List<double>>((ref) {
  ref.watch(habitNotifierProvider);
  return ref.watch(habitNotifierProvider.notifier).getWeeklyCompletionData();
});

final monthlyDataProvider = Provider<List<double>>((ref) {
  ref.watch(habitNotifierProvider);
  return ref.watch(habitNotifierProvider.notifier).getMonthlyProgressData();
});
