import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Box<Habit> get _habitsBox => Hive.box<Habit>(AppConstants.habitsBox);
  Box<HabitCompletion> get _completionsBox =>
      Hive.box<HabitCompletion>(AppConstants.completionsBox);

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  // ── HABITS CRUD ──────────────────────────────────────────────────────────

  Future<Habit> createHabit({
    required String userId,
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
    final habit = Habit(
      id: _uuid.v4(),
      userId: userId,
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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: colorIndex,
    );

    await _habitsBox.put(habit.id, habit);

    if (await _isOnline()) {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.habitsCollection)
          .doc(habit.id)
          .set(habit.toFirestore());
    }

    return habit;
  }

  Future<void> updateHabit(Habit habit) async {
    final updated = habit.copyWith(updatedAt: DateTime.now());
    await _habitsBox.put(updated.id, updated);

    if (await _isOnline()) {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(habit.userId)
          .collection(AppConstants.habitsCollection)
          .doc(habit.id)
          .update(updated.toFirestore());
    }
  }

  Future<void> deleteHabit(String habitId, String userId) async {
    await _habitsBox.delete(habitId);

    // Delete completions locally
    final toDelete = _completionsBox.values
        .where((c) => c.habitId == habitId)
        .toList();
    for (final c in toDelete) {
      await _completionsBox.delete(c.id);
    }

    if (await _isOnline()) {
      final batch = _firestore.batch();
      final habitRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.habitsCollection)
          .doc(habitId);
      batch.delete(habitRef);

      // Delete remote completions
      final completionsSnap = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.completionsCollection)
          .where('habitId', isEqualTo: habitId)
          .get();
      for (final doc in completionsSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  List<Habit> getHabitsForUser(String userId) {
    return _habitsBox.values
        .where((h) => h.userId == userId && !h.isArchived)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<Habit> getHabitsForToday(String userId) {
    final today = DateTime.now();
    return getHabitsForUser(userId)
        .where((h) => h.isScheduledForDay(today))
        .toList();
  }

  // ── COMPLETIONS ──────────────────────────────────────────────────────────

  Future<HabitCompletion> logCompletion({
    required String habitId,
    required String userId,
    required DateTime date,
    required double value,
    String? note,
  }) async {
    final dateKey = startOfDay(date);

    // Check if there's already a completion for this date
    final existing = _completionsBox.values.firstWhere(
      (c) => c.habitId == habitId && c.date.isSameDay(date),
      orElse: () => HabitCompletion(
        id: '',
        habitId: habitId,
        userId: userId,
        date: dateKey,
        value: 0,
        createdAt: DateTime.now(),
      ),
    );

    final completion = HabitCompletion(
      id: existing.id.isEmpty ? _uuid.v4() : existing.id,
      habitId: habitId,
      userId: userId,
      date: dateKey,
      value: value,
      note: note,
      createdAt: existing.createdAt.isAtSameMomentAs(DateTime.fromMillisecondsSinceEpoch(0))
          ? DateTime.now()
          : existing.createdAt,
    );

    await _completionsBox.put(completion.id, completion);

    if (await _isOnline()) {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.completionsCollection)
          .doc(completion.id)
          .set(completion.toFirestore());
    }

    return completion;
  }

  Future<void> deleteCompletion(String completionId, String userId) async {
    await _completionsBox.delete(completionId);

    if (await _isOnline()) {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.completionsCollection)
          .doc(completionId)
          .delete();
    }
  }

  List<HabitCompletion> getCompletionsForHabit(String habitId) {
    return _completionsBox.values
        .where((c) => c.habitId == habitId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  HabitCompletion? getCompletionForDate(String habitId, DateTime date) {
    try {
      return _completionsBox.values.firstWhere(
        (c) => c.habitId == habitId && c.date.isSameDay(date),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns number of completions in the last 7 days across all habits
  int getCompletionsForAllHabits(List<Habit> habits) {
    int count = 0;
    final now = DateTime.now();
    for (final habit in habits) {
      for (int d = 0; d < 7; d++) {
        final day = now.subtract(Duration(days: d));
        if (!habit.isScheduledForDay(day)) continue;
        final c = getCompletionForDate(habit.id, day);
        if (c != null && c.value >= habit.goalValue) count++;
      }
    }
    return count;
  }

  double getTodayProgress(String habitId, double goalValue) {
    final today = DateTime.now();
    final completion = getCompletionForDate(habitId, today);
    if (completion == null) return 0;
    return (completion.value / goalValue).clamp(0.0, 1.0);
  }

  // ── STREAKS ──────────────────────────────────────────────────────────────

  int calculateStreak(String habitId, Habit habit) {
    int streak = 0;
    var date = startOfDay(DateTime.now());

    while (true) {
      if (habit.isScheduledForDay(date)) {
        final completion = getCompletionForDate(habitId, date);
        if (completion != null && completion.value >= habit.goalValue) {
          streak++;
        } else if (date.isSameDay(DateTime.now())) {
          // Today is allowed to be incomplete (grace)
          date = date.subtract(const Duration(days: 1));
          continue;
        } else {
          break;
        }
      }
      date = date.subtract(const Duration(days: 1));
      if (date.isBefore(habit.createdAt.subtract(const Duration(days: 1)))) break;
    }
    return streak;
  }

  // ── CHARTS DATA ──────────────────────────────────────────────────────────

  /// Returns 7 values (Mon-Sun) for current week's completion percentage
  List<double> getWeeklyCompletionData(String habitId, Habit habit) {
    final now = DateTime.now();
    final weekStart = startOfWeek(now);
    return List.generate(7, (i) {
      final day = weekStart.add(Duration(days: i));
      if (!habit.isScheduledForDay(day)) return -1; // not scheduled
      final completion = getCompletionForDate(habitId, day);
      if (completion == null) return 0;
      return (completion.value / habit.goalValue).clamp(0.0, 1.0);
    });
  }

  /// Returns 30 days of completion percentage for monthly trend
  List<MapEntry<DateTime, double>> getMonthlyTrendData(String habitId, Habit habit) {
    final now = DateTime.now();
    return List.generate(30, (i) {
      final day = now.subtract(Duration(days: 29 - i));
      if (!habit.isScheduledForDay(day)) {
        return MapEntry(day, -1.0);
      }
      final completion = getCompletionForDate(habitId, day);
      if (completion == null) return MapEntry(day, 0.0);
      return MapEntry(day, (completion.value / habit.goalValue).clamp(0.0, 1.0));
    });
  }

  // ── SYNC ────────────────────────────────────────────────────────────────

  Future<void> syncFromFirestore(String userId) async {
    if (!await _isOnline()) return;

    try {
      // Sync habits
      final habitsDocs = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.habitsCollection)
          .get();
      for (final doc in habitsDocs.docs) {
        final habit = Habit.fromFirestore(doc.data());
        await _habitsBox.put(habit.id, habit);
      }

      // Sync completions (last 90 days)
      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      final completionsDocs = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.completionsCollection)
          .where('date', isGreaterThan: cutoff.toIso8601String())
          .get();
      for (final doc in completionsDocs.docs) {
        final completion = HabitCompletion.fromFirestore(doc.data());
        await _completionsBox.put(completion.id, completion);
      }
    } catch (e) {
      // Silent sync failure for offline-first
      debugPrint('Sync error: $e');
    }
  }

  // ── EXPORT ───────────────────────────────────────────────────────────────

  List<List<String>> exportToCsv(String userId) {
    final rows = <List<String>>[];
    rows.add(['Habit', 'Type', 'Date', 'Value', 'Goal', 'Unit', 'Completed']);

    final habits = getHabitsForUser(userId);
    for (final habit in habits) {
      final completions = getCompletionsForHabit(habit.id);
      for (final c in completions) {
        rows.add([
          habit.title,
          habit.type.displayName,
          c.date.toIso8601String().substring(0, 10),
          c.value.toString(),
          habit.goalValue.toString(),
          habit.goalUnit,
          c.value >= habit.goalValue ? 'Yes' : 'No',
        ]);
      }
    }
    return rows;
  }
}
