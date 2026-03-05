import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/habit.dart';

void main() {
  group('Habit model tests', () {
    late Habit habit;

    setUp(() {
      habit = Habit(
        id: 'test-1',
        title: 'Morning Run',
        type: HabitType.run,
        goalPeriod: GoalPeriod.daily,
        goalValue: 5.0,
        trackDays: [0, 1, 2, 3, 4, 5, 6],
      );
    });

    test('initial streak is 0', () {
      expect(habit.currentStreak, equals(0));
    });

    test('goalUnit returns correct unit for run', () {
      expect(habit.goalUnit, equals('km'));
    });

    test('goalUnit returns correct unit for readBook', () {
      final readHabit = Habit(
        id: 'test-2',
        title: 'Read',
        type: HabitType.readBook,
        goalPeriod: GoalPeriod.daily,
        goalValue: 30.0,
        trackDays: [0, 1, 2, 3, 4],
      );
      expect(readHabit.goalUnit, equals('pages'));
    });

    test('isCompletedForDate returns false when no completion', () {
      final today = DateTime.now();
      expect(habit.isCompletedForDate(today), isFalse);
    });

    test('logCompletion marks habit as completed', () {
      final today = DateTime.now();
      habit.logCompletion(today, 5.0);
      expect(habit.isCompletedForDate(today), isTrue);
    });

    test('logCompletion partial progress is not completed', () {
      final today = DateTime.now();
      habit.logCompletion(today, 2.5);
      expect(habit.isCompletedForDate(today), isFalse);
      expect(habit.getProgressForDate(today), equals(0.5));
    });

    test('isScheduledForDay respects trackDays', () {
      final habit = Habit(
        id: 'test-3',
        title: 'Weekday Habit',
        type: HabitType.custom,
        goalPeriod: GoalPeriod.daily,
        goalValue: 1.0,
        trackDays: [0, 1, 2, 3, 4], // Mon-Fri
      );
      // Monday (weekday=1 → index 0)
      final monday = DateTime(2025, 1, 6); // A Monday
      expect(habit.isScheduledForDay(monday), isTrue);
      // Saturday (weekday=6 → index 5)
      final saturday = DateTime(2025, 1, 11); // A Saturday
      expect(habit.isScheduledForDay(saturday), isFalse);
    });

    test('toMap and fromMap round-trip', () {
      final map = habit.toMap();
      final restored = Habit.fromMap(map);
      expect(restored.id, equals(habit.id));
      expect(restored.title, equals(habit.title));
      expect(restored.type, equals(habit.type));
      expect(restored.goalValue, equals(habit.goalValue));
    });

    test('currentStreak increments after completion', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();
      habit.logCompletion(yesterday, 5.0);
      habit.logCompletion(today, 5.0);
      expect(habit.currentStreak, greaterThanOrEqualTo(2));
    });

    test('HabitType displayName is correct', () {
      expect(HabitType.readBook.displayName, equals('Read Book'));
      expect(HabitType.exercise.displayName, equals('Exercise'));
      expect(HabitType.run.displayName, equals('Run'));
      expect(HabitType.sleep.displayName, equals('Sleep'));
      expect(HabitType.custom.displayName, equals('Custom'));
    });

    test('GoalPeriod displayName is correct', () {
      expect(GoalPeriod.daily.displayName, equals('Daily'));
      expect(GoalPeriod.weekly.displayName, equals('Weekly'));
      expect(GoalPeriod.monthly.displayName, equals('Monthly'));
    });
  });
}
