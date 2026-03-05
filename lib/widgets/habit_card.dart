import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../utils/app_theme.dart';
import 'progress_circle.dart';
import '../screens/habit/habit_detail_screen.dart';

class HabitCard extends ConsumerWidget {
  final Habit habit;
  final DateTime date;

  const HabitCard({super.key, required this.habit, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = AppTheme.habitColors[habit.colorIndex % AppTheme.habitColors.length];
    final progress = habit.getProgressForDate(date);
    final isCompleted = habit.isCompletedForDate(date);
    final streak = habit.currentStreak;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HabitDetailScreen(habit: habit),
          ),
        );
      },
      child: Hero(
        tag: 'habit_${habit.id}',
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: isCompleted
                  ? Border.all(color: color.withOpacity(0.3), width: 1.5)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Type icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        habit.type.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Habit info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            decoration: isCompleted
                                ? TextDecoration.none
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${habit.goalValue.toStringAsFixed(habit.goalValue.truncateToDouble() == habit.goalValue ? 0 : 1)} ${habit.goalUnit}',
                              style: theme.textTheme.bodySmall,
                            ),
                            if (streak > 0) ...[
                              const SizedBox(width: 12),
                              const Text('🔥', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 2),
                              Text(
                                '$streak day${streak == 1 ? '' : 's'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.warningColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: color.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted ? AppTheme.successColor : color,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Progress circle & toggle
                  Column(
                    children: [
                      ProgressCircle(
                        progress: progress,
                        size: 52,
                        color: isCompleted ? AppTheme.successColor : color,
                        label:
                            isCompleted
                                ? '✓'
                                : '${(progress * 100).round()}%',
                        strokeWidth: 5,
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(habitNotifierProvider.notifier)
                              .toggleCompletion(habit.id, date);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                isCompleted
                                    ? AppTheme.successColor
                                    : Colors.transparent,
                            border: Border.all(
                              color:
                                  isCompleted
                                      ? AppTheme.successColor
                                      : color,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: isCompleted
                              ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
