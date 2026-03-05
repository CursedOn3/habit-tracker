import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../services/habit_service.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/monthly_line_chart.dart';
import '../habit/add_edit_habit_screen.dart';
import 'package:intl/intl.dart';

class HabitHistoryScreen extends ConsumerStatefulWidget {
  final Habit habit;
  final String userId;

  const HabitHistoryScreen({
    super.key,
    required this.habit,
    required this.userId,
  });

  @override
  ConsumerState<HabitHistoryScreen> createState() => _HabitHistoryScreenState();
}

class _HabitHistoryScreenState extends ConsumerState<HabitHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final service = ref.watch(habitServiceProvider);
    final completions = ref.watch(habitCompletionsProvider(widget.habit.id));
    final streak = ref.watch(habitStreakProvider((habitId: widget.habit.id, userId: widget.userId)));
    final monthlyData = service.getMonthlyTrendData(widget.habit.id, widget.habit);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit.title),
        actions: [
          IconButton(
            onPressed: () => _openEdit(context),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Habit header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.habit.type.color, widget.habit.type.color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(widget.habit.type.icon, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        '${widget.habit.goalValue.toDisplayString()} ${widget.habit.goalUnit} / ${widget.habit.goalPeriod.displayName.toLowerCase()}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '🔥',
                      style: const TextStyle(fontSize: 24),
                    ),
                    Text(
                      '$streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      'streak',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Monthly chart
          MonthlyLineChart(
            data: monthlyData,
            lineColor: widget.habit.type.color,
          ),

          const SizedBox(height: 20),

          // Calendar grid
          _CalendarGrid(habit: widget.habit, service: service),

          const SizedBox(height: 20),

          // Completions history
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('History', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                if (completions.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('No completions yet', style: theme.textTheme.bodyMedium),
                    ),
                  )
                else
                  ...completions.take(30).map((c) => _CompletionTile(
                    completion: c,
                    habit: widget.habit,
                    isDark: isDark,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddEditHabitScreen(userId: widget.userId, habit: widget.habit),
    );
    if (result == true && mounted) {
      ref.read(habitsProvider(widget.userId).notifier).refresh();
    }
  }
}

class _CalendarGrid extends StatelessWidget {
  final Habit habit;
  final HabitService service;

  const _CalendarGrid({required this.habit, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = startOfDay(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 42 Days', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) => Text(
              AppConstants.weekDaysShort[i].substring(0, 1),
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            )),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: 42,
            itemBuilder: (ctx, i) {
              final day = today.subtract(Duration(days: 41 - i));
              final isToday = day.isSameDay(today);
              final isScheduled = habit.isScheduledForDay(day);
              final completion = service.getCompletionForDate(habit.id, day);
              final progress = completion != null
                  ? (completion.value / habit.goalValue).clamp(0.0, 1.0)
                  : 0.0;

              Color color;
              if (!isScheduled) {
                color = Colors.transparent;
              } else if (progress >= 1.0) {
                color = habit.type.color;
              } else if (progress > 0) {
                color = habit.type.color.withOpacity(0.4);
              } else {
                color = isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.15);
              }

              return AnimatedContainer(
                duration: AppConstants.shortAnim,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: isToday
                      ? Border.all(color: habit.type.color, width: 2)
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            children: [
              _LegendDot(color: habit.type.color, label: 'Done'),
              _LegendDot(color: habit.type.color.withOpacity(0.4), label: 'Partial'),
              _LegendDot(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15),
                label: 'Missed',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CompletionTile extends StatelessWidget {
  final HabitCompletion completion;
  final Habit habit;
  final bool isDark;

  const _CompletionTile({
    required this.completion,
    required this.habit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = ((completion.value / habit.goalValue) * 100).round();
    final isCompleted = completion.value >= habit.goalValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isCompleted ? habit.type.color : AppTheme.warning).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : Icons.remove_rounded,
              color: isCompleted ? habit.type.color : AppTheme.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(completion.date),
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '${completion.value.toDisplayString()} / ${habit.goalValue.toDisplayString()} ${habit.goalUnit}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isCompleted ? habit.type.color : AppTheme.warning).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$pct%',
              style: TextStyle(
                color: isCompleted ? habit.type.color : AppTheme.warning,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
