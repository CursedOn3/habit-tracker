import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../services/habit_service.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../../widgets/monthly_line_chart.dart';
import 'add_edit_habit_screen.dart';

// ---------------------------------------------------------------------------
// Gradient palette mirrors add_edit_habit_screen.dart
// ---------------------------------------------------------------------------
const List<List<Color>> _kDetailGradientPalette = [
  [Color(0xFF6C63FF), Color(0xFF9D97FF)],
  [Color(0xFF43E97B), Color(0xFF38F9D7)],
  [Color(0xFFFF6584), Color(0xFFFF8E53)],
  [Color(0xFF4FC3F7), Color(0xFF0288D1)],
  [Color(0xFFFF9F43), Color(0xFFFFD32A)],
  [Color(0xFF8E54E9), Color(0xFF4776E6)],
];

LinearGradient _detailGradient(int idx) => LinearGradient(
      colors:
          _kDetailGradientPalette[idx.clamp(0, _kDetailGradientPalette.length - 1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

Color _detailBaseColor(int idx) =>
    _kDetailGradientPalette[idx.clamp(0, _kDetailGradientPalette.length - 1)][0];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Full stats screen for a single habit.
///
/// Shows: header card, streak, 30-day line chart, 42-day calendar grid,
/// recent completions list, and a FAB to log today's entry.
class HabitDetailScreen extends ConsumerStatefulWidget {
  final Habit habit;
  final String userId;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.userId,
  });

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  // Keep a local mutable copy that updates when the user edits the habit.
  late Habit _habit;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
  }

  // ── open edit screen ──────────────────────────────────────────────────────

  Future<void> _openEdit() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddEditHabitScreen(
          userId: widget.userId,
          habit: _habit,
        ),
      ),
    );
    if (result == true && mounted) {
      // Re-fetch the updated habit from the provider.
      final habitsAsync =
          ref.read(habitsProvider(widget.userId));
      habitsAsync.whenData((list) {
        try {
          final updated =
              list.firstWhere((h) => h.id == _habit.id);
          setState(() => _habit = updated);
        } catch (_) {}
      });
    }
  }

  // ── log completion dialog ─────────────────────────────────────────────────

  Future<void> _logCompletion() async {
    final service = ref.read(habitServiceProvider);
    final existing = service.getCompletionForDate(_habit.id, DateTime.now());

    final valueCtrl = TextEditingController(
      text: existing != null ? _fmtVal(existing.value) : '',
    );
    final noteCtrl =
        TextEditingController(text: existing?.note ?? '');

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LogCompletionSheet(
        habit: _habit,
        valueCtrl: valueCtrl,
        noteCtrl: noteCtrl,
        isEdit: existing != null,
        accentColor: _detailBaseColor(_habit.colorIndex),
      ),
    );

    if (confirmed == true && mounted) {
      final val = double.tryParse(valueCtrl.text.trim()) ?? 0.0;
      await ref
          .read(habitsProvider(widget.userId).notifier)
          .logCompletion(
            habitId: _habit.id,
            date: DateTime.now(),
            value: val,
            note: noteCtrl.text.trim().isNotEmpty
                ? noteCtrl.text.trim()
                : null,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Progress logged!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      }
    }
    valueCtrl.dispose();
    noteCtrl.dispose();
  }

  String _fmtVal(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final completions =
        ref.watch(habitCompletionsProvider(_habit.id));
    final streak = ref.watch(habitStreakProvider(
        (habitId: _habit.id, userId: widget.userId)));
    final service = ref.read(habitServiceProvider);
    final monthlyData = service.getMonthlyTrendData(_habit.id, _habit);
    final accentColor = _detailBaseColor(_habit.colorIndex);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, isDark, streak, accentColor),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildGoalInfoRow(theme, isDark, completions),
                const Gap(24),
                _buildSectionHeader('30-Day Progress', isDark),
                const Gap(8),
                _buildChartCard(isDark, monthlyData, accentColor),
                const Gap(24),
                _buildSectionHeader('Activity Calendar', isDark),
                const Gap(8),
                _buildCalendarCard(isDark, completions, accentColor),
                const Gap(24),
                _buildSectionHeader('Recent Completions', isDark),
                const Gap(8),
                _buildRecentCompletions(theme, isDark, completions),
                const Gap(100), // FAB clearance
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logCompletion,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Today',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      )
          .animate()
          .scale(
            duration: 300.ms,
            curve: Curves.elasticOut,
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
          ),
    );
  }

  // ── sliver app bar ────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(
    BuildContext context,
    bool isDark,
    int streak,
    Color accentColor,
  ) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: accentColor,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          tooltip: 'Edit',
          onPressed: _openEdit,
        ),
        const Gap(8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration:
              BoxDecoration(gradient: _detailGradient(_habit.colorIndex)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(_habit.type.icon,
                              style: const TextStyle(fontSize: 32)),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _habit.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const Gap(4),
                            Text(
                              _habit.type.displayName +
                                  '  \u2022  ' +
                                  _habit.goalPeriod.displayName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\uD83D\uDD25',
                                style: const TextStyle(fontSize: 20))
                            .animate(
                              onPlay: (c) => c.repeat(period: 2.seconds),
                            )
                            .shimmer(
                              duration: 1200.ms,
                              color: Colors.white38,
                            ),
                        const Gap(8),
                        Text(
                          '$streak day streak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── goal info row ─────────────────────────────────────────────────────────

  Widget _buildGoalInfoRow(
    ThemeData theme,
    bool isDark,
    List<HabitCompletion> completions,
  ) {
    final service = ref.read(habitServiceProvider);
    final todayCompletion =
        service.getCompletionForDate(_habit.id, DateTime.now());
    final todayValue = todayCompletion?.value ?? 0.0;
    final progress = (todayValue / _habit.goalValue).clamp(0.0, 1.0);
    final accentColor = _detailBaseColor(_habit.colorIndex);
    final bestValue = completions.isEmpty
        ? 0.0
        : completions.map((c) => c.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statCard(
                isDark: isDark,
                accentColor: accentColor,
                icon: Icons.today_rounded,
                label: 'Today',
                value: _fmtVal(todayValue) +
                    ' / ' +
                    _fmtVal(_habit.goalValue),
                sub: _habit.goalUnit,
              ),
              const Gap(12),
              _statCard(
                isDark: isDark,
                accentColor: accentColor,
                icon: Icons.checklist_rounded,
                label: 'Total Logs',
                value: completions.length.toString(),
                sub: 'entries',
              ),
              const Gap(12),
              _statCard(
                isDark: isDark,
                accentColor: accentColor,
                icon: Icons.bar_chart_rounded,
                label: 'Best',
                value: _fmtVal(bestValue),
                sub: _habit.goalUnit,
              ),
            ],
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Today\u2019s progress',
                  style: theme.textTheme.bodySmall),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Gap(6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  accentColor.withOpacity(isDark ? 0.2 : 0.12),
              valueColor:
                  AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required bool isDark,
    required Color accentColor,
    required IconData icon,
    required String label,
    required String value,
    required String sub,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(isDark ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: accentColor),
            const Gap(6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: accentColor,
                fontFamily: 'Inter',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── section header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark ? Colors.white54 : Colors.black38,
        fontFamily: 'Inter',
      ),
    );
  }

  // ── monthly line chart card ───────────────────────────────────────────────

  Widget _buildChartCard(
    bool isDark,
    List<MapEntry<DateTime, double>> data,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: MonthlyLineChart(
        data: data,
        lineColor: accentColor,
        height: 200,
      ),
    );
  }

  // ── 42-day calendar grid ──────────────────────────────────────────────────

  Widget _buildCalendarCard(
    bool isDark,
    List<HabitCompletion> completions,
    Color accentColor,
  ) {
    final today = startOfDay(DateTime.now());
    // 42 cells = 6 weeks, ending on today (or the nearest Sunday after today)
    final cellCount = 42;
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final completionMap = <String, double>{};
    for (final c in completions) {
      completionMap[c.date.toDateKey()] = c.value;
    }

    // Start date: 41 days before today
    final startDate = today.subtract(const Duration(days: 41));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day-of-week header
          Row(
            children: dayLabels.map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Gap(6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: cellCount,
            itemBuilder: (ctx, i) {
              final date = startDate.add(Duration(days: i));
              final key = date.toDateKey();
              final isScheduled = _habit.isScheduledForDay(date);
              final isFuture = date.isAfter(today);
              final completionValue = completionMap[key];
              final isCompleted = completionValue != null &&
                  completionValue >= _habit.goalValue;
              final isPartial = completionValue != null &&
                  completionValue > 0 &&
                  !isCompleted;
              final isToday = date.isSameDay(today);

              Color bgColor;
              if (isFuture || !isScheduled) {
                bgColor = isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.03);
              } else if (isCompleted) {
                bgColor = accentColor;
              } else if (isPartial) {
                bgColor = accentColor.withOpacity(0.45);
              } else {
                bgColor = isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.07);
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                  border: isToday
                      ? Border.all(color: accentColor, width: 2)
                      : null,
                ),
                child: isCompleted
                    ? const Center(
                        child: Icon(Icons.check_rounded,
                            size: 10, color: Colors.white))
                    : null,
              );
            },
          ),
          const Gap(12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _legendDot(
                  color: accentColor,
                  label: 'Done',
                  isDark: isDark),
              const Gap(12),
              _legendDot(
                  color: accentColor.withOpacity(0.45),
                  label: 'Partial',
                  isDark: isDark),
              const Gap(12),
              _legendDot(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.07),
                  label: 'Missed',
                  isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot({
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  // ── recent completions ────────────────────────────────────────────────────

  Widget _buildRecentCompletions(
    ThemeData theme,
    bool isDark,
    List<HabitCompletion> completions,
  ) {
    final recent = completions.take(10).toList();
    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history_rounded,
                  size: 40,
                  color: isDark ? Colors.white24 : Colors.black26),
              const Gap(12),
              Text(
                'No completions yet',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontFamily: 'Inter',
                ),
              ),
              const Gap(4),
              Text(
                'Tap the button below to log your first entry',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final accentColor = _detailBaseColor(_habit.colorIndex);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: recent.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          final isGoalMet = c.value >= _habit.goalValue;
          final pct =
              ((c.value / _habit.goalValue) * 100).round();

          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isGoalMet
                        ? accentColor.withOpacity(0.15)
                        : (isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.05)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isGoalMet
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isGoalMet
                        ? accentColor
                        : (isDark ? Colors.white38 : Colors.black38),
                    size: 22,
                  ),
                ),
                title: Text(
                  c.date.toFormattedDate(),
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: c.note != null && c.note!.isNotEmpty
                    ? Text(c.note!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                    : null,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmtVal(c.value) + ' ' + _habit.goalUnit,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isGoalMet ? accentColor : null,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < recent.length - 1)
                const Divider(height: 1, indent: 56, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
} // end _HabitDetailScreenState

// ---------------------------------------------------------------------------
// Log Completion Bottom Sheet
// ---------------------------------------------------------------------------

/// Internal bottom sheet that collects a completion value and optional note.
/// Returns [true] when the user taps Save, [false] / null on dismiss.
class _LogCompletionSheet extends StatefulWidget {
  final Habit habit;
  final TextEditingController valueCtrl;
  final TextEditingController noteCtrl;
  final bool isEdit;
  final Color accentColor;

  const _LogCompletionSheet({
    required this.habit,
    required this.valueCtrl,
    required this.noteCtrl,
    required this.isEdit,
    required this.accentColor,
  });

  @override
  State<_LogCompletionSheet> createState() => _LogCompletionSheetState();
}

class _LogCompletionSheetState extends State<_LogCompletionSheet> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      padding:
          EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(20),
            Row(
              children: [
                Text(
                  widget.habit.type.icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEdit
                            ? 'Update Today\u2019s Log'
                            : 'Log Today\u2019s Progress',
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        widget.habit.title,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(24),
            TextFormField(
              controller: widget.valueCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: widget.habit.goalLabel,
                prefixIcon: const Icon(Icons.edit_outlined),
                suffixText: widget.habit.goalUnit,
                suffixStyle: TextStyle(
                  color: widget.accentColor,
                  fontWeight: FontWeight.w700,
                ),
                helperText:
                    'Goal: ${_fmtGoal(widget.habit.goalValue)} '
                    '${widget.habit.goalUnit}',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a value';
                }
                final n = double.tryParse(v.trim());
                if (n == null || n < 0) return 'Enter a valid number';
                return null;
              },
            ),
            const Gap(14),
            TextFormField(
              controller: widget.noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
                hintText: 'How did it go?',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.accentColor,
                      widget.accentColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    child: Center(
                      child: Text(
                        widget.isEdit ? 'Update Entry' : 'Save Entry',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtGoal(double v) =>
      v == v.truncateToDouble()
          ? v.toInt().toString()
          : v.toStringAsFixed(1);
}
