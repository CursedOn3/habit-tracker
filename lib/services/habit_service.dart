import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../utils/constants.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Box<Habit> _habitsBox;

  Future<void> init() async {
    _habitsBox = await Hive.openBox<Habit>(AppConstants.habitsBox);
  }

  Box<Habit> get habitsBox => _habitsBox;

  // Local operations
  List<Habit> getLocalHabits({String? userId}) {
    final habits = _habitsBox.values.toList();
    if (userId != null) {
      return habits.where((h) => h.userId == userId).toList();
    }
    return habits;
  }

  Future<void> saveHabitLocally(Habit habit) async {
    await _habitsBox.put(habit.id, habit);
  }

  Future<void> deleteHabitLocally(String habitId) async {
    await _habitsBox.delete(habitId);
  }

  Future<void> updateCompletionLocally(
    String habitId,
    DateTime date,
    double value,
  ) async {
    final habit = _habitsBox.get(habitId);
    if (habit != null) {
      habit.logCompletion(date, value);
      await habit.save();
    }
  }

  // Firestore operations
  Future<void> syncHabitToFirestore(Habit habit) async {
    await _firestore
        .collection('users')
        .doc(habit.userId)
        .collection('habits')
        .doc(habit.id)
        .set(habit.toMap());
  }

  Future<void> deleteHabitFromFirestore(
    String userId,
    String habitId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .doc(habitId)
        .delete();
  }

  Future<List<Habit>> fetchHabitsFromFirestore(String userId) async {
    final snapshot =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('habits')
            .get();

    return snapshot.docs
        .map((doc) => Habit.fromMap(doc.data()))
        .toList();
  }

  Future<void> syncFromFirestore(String userId) async {
    final remoteHabits = await fetchHabitsFromFirestore(userId);
    for (final habit in remoteHabits) {
      final local = _habitsBox.get(habit.id);
      if (local == null ||
          habit.createdAt.isAfter(local.createdAt)) {
        await _habitsBox.put(habit.id, habit);
      }
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchHabits(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .snapshots();
  }

  // CSV Export
  String exportToCsv(List<Habit> habits) {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Title,Type,Goal Period,Goal Value,Goal Unit,Created At,Current Streak',
    );
    for (final habit in habits) {
      buffer.writeln(
        '${habit.id},'
        '"${habit.title}",'
        '${habit.type.displayName},'
        '${habit.goalPeriod.displayName},'
        '${habit.goalValue},'
        '${habit.goalUnit},'
        '${habit.createdAt.toIso8601String()},'
        '${habit.currentStreak}',
      );
    }
    return buffer.toString();
  }
}
