import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class HabitCard extends ConsumerWidget {
  final Habit habit;
  final String userId;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.userId,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = ref.watch(
      todayProgressProvider((habitId: habit.id, goalValue: habit.goalValue)),
    );
    final streak = ref.watch(
      habitStreakProvider((habitId: habit.id, userId: userId)),
    );
    final today = DateTime.now();
    final completion = ref.watch(habitServiceProvider).getCompletionForDate(habit.id, today);
    final isCompleted = completion != null && completion.value >= habit.goalValue;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.shortAnim,
        decoration: BoxDecoration(
          color: isCompleted
              ? habit.type.color.withOpacity(0.08)
              : (isDark ? const Color(0xFF1E1E2E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? habit.type.color.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [habit.type.color, habit.type.color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(habit.type.icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),

              // Title + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: habit.type.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${habit.goalValue.toDisplayString()} ${habit.goalUnit} / ${habit.goalPeriod.displayName.toLowerCase()}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (streak > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 2),
                                Text(
                                  '$streak',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.warning,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (progress > 0 && !isCompleted) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: habit.type.color.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(habit.type.color),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(progress * habit.goalValue).toDisplayString()} / ${habit.goalValue.toDisplayString()} ${habit.goalUnit}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: habit.type.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Actions column
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Quick log button
                  GestureDetector(
                    onTap: () => _showQuickLog(context, ref),
                    child: AnimatedContainer(
                      duration: AppConstants.shortAnim,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? habit.type.color
                            : habit.type.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_rounded
                            : Icons.add_rounded,
                        color: isCompleted ? Colors.white : habit.type.color,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') onEdit?.call();
                      if (val == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: AppTheme.error)),
                      ),
                    ],
                    icon: Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showQuickLog(BuildContext context, WidgetRef ref) async {
    final today = DateTime.now();
    final service = ref.read(habitServiceProvider);
    final existing = service.getCompletionForDate(habit.id, today);

    if (existing != null && existing.value >= habit.goalValue) {
      // Toggle off
      await service.deleteCompletion(existing.id, habit.userId);
      ref.read(habitsProvider(userId).notifier).refresh();
      return;
    }

    // If goal is 1 unit or binary, just toggle
    if (habit.goalValue == 1) {
      await ref.read(habitsProvider(userId).notifier).logCompletion(
        habitId: habit.id,
        date: today,
        value: 1,
      );
      return;
    }

    // Show value input dialog
    if (context.mounted) {
      final value = await showDialog<double>(
        context: context,
        builder: (ctx) => _LogValueDialog(habit: habit, existing: existing),
      );
      if (value != null) {
        await ref.read(habitsProvider(userId).notifier).logCompletion(
          habitId: habit.id,
          date: today,
          value: value,
        );
      }
    }
  }
}

class _LogValueDialog extends StatefulWidget {
  final Habit habit;
  final dynamic existing;

  const _LogValueDialog({required this.habit, this.existing});

  @override
  State<_LogValueDialog> createState() => _LogValueDialogState();
}

class _LogValueDialogState extends State<_LogValueDialog> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.existing?.value.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log ${widget.habit.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Goal: ${widget.habit.goalValue} ${widget.habit.goalUnit}'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Value (${widget.habit.goalUnit})',
              suffixText: widget.habit.goalUnit,
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final val = double.tryParse(_ctrl.text);
            if (val != null && val >= 0) {
              Navigator.pop(context, val);
            }
          },
          child: const Text('Log'),
        ),
      ],
    );
  }
}
