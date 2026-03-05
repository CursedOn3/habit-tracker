import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../utils/theme.dart';

class ProgressSummary extends ConsumerWidget {
  final String userId;
  final List<Habit> todayHabits;

  const ProgressSummary({
    super.key,
    required this.userId,
    required this.todayHabits,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final service = ref.watch(habitServiceProvider);

    int completedToday = 0;
    int totalStreaks = 0;

    for (final habit in todayHabits) {
      final completion = service.getCompletionForDate(habit.id, DateTime.now());
      if (completion != null && completion.value >= habit.goalValue) {
        completedToday++;
      }
      totalStreaks += service.calculateStreak(habit.id, habit);
    }

    final allHabits = service.getHabitsForUser(userId);
    final completionRate = allHabits.isEmpty
        ? 0.0
        : (service.getCompletionsForAllHabits(allHabits) / (allHabits.length * 7.0)).clamp(0.0, 1.0);

    return Row(
      children: [
        _StatCard(
          emoji: '✅',
          value: completedToday.toString(),
          label: 'Done Today',
          subLabel: '/ ${todayHabits.length}',
          color: AppTheme.success,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _StatCard(
          emoji: '🔥',
          value: totalStreaks.toString(),
          label: 'Total Streak',
          subLabel: 'days',
          color: AppTheme.warning,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _StatCard(
          emoji: '📈',
          value: '${(completionRate * 100).round()}%',
          label: 'This Week',
          subLabel: '',
          color: AppTheme.primary,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final String subLabel;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.subLabel,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1,
                  ),
                ),
                if (subLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      subLabel,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
