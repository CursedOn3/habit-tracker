import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/progress_circle.dart';
import '../../widgets/charts/monthly_line_chart.dart';
import 'add_edit_habit_screen.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Habit _habit;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Habit _getLatestHabit(WidgetRef ref) {
    final habits = ref.watch(habitNotifierProvider).habits;
    return habits.firstWhere(
      (h) => h.id == _habit.id,
      orElse: () => _habit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = _getLatestHabit(ref);
    final color = AppTheme.habitColors[habit.colorIndex % AppTheme.habitColors.length];
    final today = DateTime.now();
    final progress = habit.getProgressForDate(today);
    final isCompleted = habit.isCompletedForDate(today);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'habit_${habit.id}',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            habit.type.icon,
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            habit.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${habit.goalValue} ${habit.goalUnit} / ${habit.goalPeriod.displayName.toLowerCase()}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditHabitScreen(habit: habit),
                    ),
                  );
                  setState(() => _habit = _getLatestHabit(ref));
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _DetailStatCard(
                          label: "Today's Progress",
                          child: ProgressCircle(
                            progress: progress,
                            size: 64,
                            color: isCompleted ? AppTheme.successColor : color,
                            label:
                                isCompleted
                                    ? '✓'
                                    : '${(progress * 100).round()}%',
                            strokeWidth: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailStatCard(
                          label: 'Current Streak',
                          child: Column(
                            children: [
                              const Text(
                                '🔥',
                                style: TextStyle(fontSize: 28),
                              ),
                              Text(
                                '${habit.currentStreak} days',
                                style: TextStyle(
                                  color: AppTheme.warningColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailStatCard(
                          label: 'Schedule',
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: color,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getScheduleText(habit),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Log today's value
                  if (!isCompleted) ...[
                    _LogValueCard(habit: habit, color: color, date: today),
                    const SizedBox(height: 16),
                  ],

                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'History'),
                    ],
                    labelColor: color,
                    indicatorColor: color,
                  ),
                ],
              ),
            ),
          ),

          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(habit: habit),
                _HistoryTab(habit: habit),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getScheduleText(Habit habit) {
    if (habit.trackDays.length == 7) return 'Every day';
    if (habit.trackDays.length == 5 &&
        !habit.trackDays.contains(5) &&
        !habit.trackDays.contains(6)) {
      return 'Weekdays';
    }
    if (habit.trackDays.contains(5) && habit.trackDays.contains(6) &&
        habit.trackDays.length == 2) {
      return 'Weekends';
    }
    return '${habit.trackDays.length}x/week';
  }
}

class _DetailStatCard extends StatelessWidget {
  final String label;
  final Widget child;

  const _DetailStatCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          child,
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LogValueCard extends ConsumerStatefulWidget {
  final Habit habit;
  final Color color;
  final DateTime date;

  const _LogValueCard({
    required this.habit,
    required this.color,
    required this.date,
  });

  @override
  ConsumerState<_LogValueCard> createState() => _LogValueCardState();
}

class _LogValueCardState extends ConsumerState<_LogValueCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = widget.habit.getCompletionForDate(widget.date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Progress',
            style: theme.textTheme.titleLarge?.copyWith(color: widget.color),
          ),
          const SizedBox(height: 4),
          Text(
            'Current: $current / ${widget.habit.goalValue} ${widget.habit.goalUnit}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter ${widget.habit.goalUnit}',
                    suffixText: widget.habit.goalUnit,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  final value = double.tryParse(_controller.text);
                  if (value != null) {
                    ref
                        .read(habitNotifierProvider.notifier)
                        .logCompletion(widget.habit.id, widget.date, value);
                    _controller.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text('Log'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Quick buttons
          Row(
            children: [
              _QuickLogButton(
                label: 'Mark Done',
                onTap: () {
                  ref
                      .read(habitNotifierProvider.notifier)
                      .logCompletion(
                        widget.habit.id,
                        widget.date,
                        widget.habit.goalValue,
                      );
                },
                color: widget.color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickLogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickLogButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Habit habit;

  const _OverviewTab({required this.habit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.habitColors[habit.colorIndex % AppTheme.habitColors.length];
    final monthlyData = _getMonthlyData();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Monthly Progress', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MonthlyLineChart(data: monthlyData),
          ),
        ),
        const SizedBox(height: 16),

        Text('Details', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        _DetailRow(
          icon: Icons.category_outlined,
          label: 'Type',
          value: '${habit.type.icon} ${habit.type.displayName}',
          color: color,
        ),
        _DetailRow(
          icon: Icons.flag_outlined,
          label: 'Goal',
          value: _buildGoalText(habit),
          color: color,
        ),
        if (habit.startTime != null)
          _DetailRow(
            icon: Icons.schedule_outlined,
            label: 'Time Range',
            value: '${habit.startTime} - ${habit.endTime ?? '?'}',
            color: color,
          ),
        if (habit.reminderEnabled && habit.reminderTime != null)
          _DetailRow(
            icon: Icons.notifications_outlined,
            label: 'Reminder',
            value: habit.reminderTime!,
            color: color,
          ),
        _DetailRow(
          icon: Icons.calendar_today_outlined,
          label: 'Created',
          value: DateFormat('MMM d, yyyy').format(habit.createdAt),
          color: color,
        ),
      ],
    );
  }

  List<double> _getMonthlyData() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return List.generate(daysInMonth, (i) {
      final day = DateTime(now.year, now.month, i + 1);
      if (day.isAfter(now)) return -1.0;
      return habit.getProgressForDate(day);
    });
  }

  String _buildGoalText(Habit h) {
    final goal = h.goalValue.truncateToDouble() == h.goalValue
        ? h.goalValue.toInt().toString()
        : h.goalValue.toString();
    return '$goal ${h.goalUnit} / ${h.goalPeriod.displayName.toLowerCase()}';
  }
}

class _HistoryTab extends StatelessWidget {
  final Habit habit;

  const _HistoryTab({required this.habit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppTheme.habitColors[habit.colorIndex % AppTheme.habitColors.length];

    final entries = habit.completions.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_outlined,
              size: 48,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 8),
            Text('No history yet', style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final date = DateTime.parse(entry.key);
        final value = entry.value;
        final isComplete = value >= habit.goalValue;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isComplete
                ? AppTheme.successColor.withOpacity(0.1)
                : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: isComplete
                ? Border.all(
                  color: AppTheme.successColor.withOpacity(0.3),
                )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isComplete ? AppTheme.successColor : color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(date),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$value / ${habit.goalValue} ${habit.goalUnit}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '${((value / habit.goalValue) * 100).round()}%',
                style: TextStyle(
                  color: isComplete ? AppTheme.successColor : color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
