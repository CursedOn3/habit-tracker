import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

// ---------------------------------------------------------------------------
// Gradient palette — 6 options (index matches Habit.colorIndex)
// ---------------------------------------------------------------------------
const List<List<Color>> _kGradientPalette = [
  [Color(0xFF6C63FF), Color(0xFF9D97FF)], // 0 — purple (default)
  [Color(0xFF43E97B), Color(0xFF38F9D7)], // 1 — green
  [Color(0xFFFF6584), Color(0xFFFF8E53)], // 2 — pink-orange
  [Color(0xFF4FC3F7), Color(0xFF0288D1)], // 3 — blue
  [Color(0xFFFF9F43), Color(0xFFFFD32A)], // 4 — amber
  [Color(0xFF8E54E9), Color(0xFF4776E6)], // 5 — indigo
];

LinearGradient _gradientAt(int idx) => LinearGradient(
      colors: _kGradientPalette[idx.clamp(0, _kGradientPalette.length - 1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

Color _baseColorAt(int idx) =>
    _kGradientPalette[idx.clamp(0, _kGradientPalette.length - 1)][0];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Full-screen form for adding or editing a single habit.
///
/// Push this route directly or show it as a modal bottom sheet.
/// On success it pops with [true]; on cancel / back it pops with [false].
class AddEditHabitScreen extends ConsumerStatefulWidget {
  /// The authenticated Firebase user uid.
  final String userId;

  /// When provided the form is pre-filled and [HabitsNotifier.updateHabit]
  /// is called on save; otherwise [HabitsNotifier.addHabit] is called.
  final Habit? habit;

  const AddEditHabitScreen({
    super.key,
    required this.userId,
    this.habit,
  });

  @override
  ConsumerState<AddEditHabitScreen> createState() =>
      _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  // ── form controllers ──────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _goalValueCtrl;
  late final TextEditingController _locationNameCtrl;

  // ── fields ────────────────────────────────────────────────────────────────
  late HabitType _type;
  late GoalPeriod _goalPeriod;
  late List<int> _trackDays; // ISO weekday: 1=Mon … 7=Sun
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _reminderEnabled = false;
  TimeOfDay? _reminderTime;
  bool _locationEnabled = false;
  late int _colorIndex;

  bool _saving = false;
  bool get _isEdit => widget.habit != null;

  // ── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _titleCtrl = TextEditingController(text: h?.title ?? '');
    _goalValueCtrl =
        TextEditingController(text: h != null ? _fmtGoal(h.goalValue) : '');
    _locationNameCtrl = TextEditingController(text: h?.locationName ?? '');
    _type = h?.type ?? HabitType.custom;
    _goalPeriod = h?.goalPeriod ?? GoalPeriod.daily;
    _trackDays = h != null ? List<int>.from(h.trackDays) : [1, 2, 3, 4, 5];
    _startTime =
        h?.startTime != null ? TimeOfDay.fromDateTime(h!.startTime!) : null;
    _endTime =
        h?.endTime != null ? TimeOfDay.fromDateTime(h!.endTime!) : null;
    _reminderEnabled = h?.reminderEnabled ?? false;
    _reminderTime = h?.reminderTime != null
        ? TimeOfDay.fromDateTime(h!.reminderTime!)
        : null;
    _locationEnabled = h?.locationEnabled ?? false;
    _colorIndex = h?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _goalValueCtrl.dispose();
    _locationNameCtrl.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String _fmtGoal(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  DateTime? _todayWithTime(TimeOfDay? t) {
    if (t == null) return null;
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, t.hour, t.minute);
  }

  String _fmtTime(TimeOfDay t) => t.format(context);

  Future<TimeOfDay?> _pickTime(TimeOfDay? initial) => showTimePicker(
        context: context,
        initialTime: initial ?? TimeOfDay.now(),
      );

  // ── save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_trackDays.isEmpty) {
      _showError('Please select at least one tracking day.');
      return;
    }

    setState(() => _saving = true);
    try {
      final notifier = ref.read(habitsProvider(widget.userId).notifier);
      final goalValue = double.tryParse(_goalValueCtrl.text.trim()) ?? 1.0;
      final locationName = _locationEnabled &&
              _locationNameCtrl.text.trim().isNotEmpty
          ? _locationNameCtrl.text.trim()
          : null;

      if (_isEdit) {
        // Construct Habit directly so nullable fields are genuinely
        // cleared to null rather than kept via copyWith fallback.
        final updated = Habit(
          id: widget.habit!.id,
          userId: widget.userId,
          title: _titleCtrl.text.trim(),
          type: _type,
          goalPeriod: _goalPeriod,
          goalValue: goalValue,
          goalUnit: _type.defaultUnit,
          trackDays: _trackDays,
          startTime: _todayWithTime(_startTime),
          endTime: _todayWithTime(_endTime),
          reminderTime: _todayWithTime(_reminderTime),
          reminderEnabled: _reminderEnabled,
          locationEnabled: _locationEnabled,
          locationName: locationName,
          colorIndex: _colorIndex,
          createdAt: widget.habit!.createdAt,
          updatedAt: DateTime.now(),
          isArchived: widget.habit!.isArchived,
        );
        await notifier.updateHabit(updated);
      } else {
        await notifier.addHabit(
          title: _titleCtrl.text.trim(),
          type: _type,
          goalPeriod: _goalPeriod,
          goalValue: goalValue,
          goalUnit: _type.defaultUnit,
          trackDays: _trackDays,
          startTime: _todayWithTime(_startTime),
          endTime: _todayWithTime(_endTime),
          reminderTime: _todayWithTime(_reminderTime),
          reminderEnabled: _reminderEnabled,
          locationEnabled: _locationEnabled,
          locationName: locationName,
          colorIndex: _colorIndex,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _showError('Failed to save habit. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildGradientHeader(context, isDark),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                children: [
                  _buildTitleField(theme, isDark),
                  const Gap(20),
                  _buildSection(
                    label: 'Habit Settings',
                    isDark: isDark,
                    children: [
                      _buildTypeDropdown(),
                      const Gap(14),
                      _buildGoalPeriodDropdown(),
                      const Gap(14),
                      _buildGoalValueField(),
                    ],
                  ),
                  const Gap(20),
                  _buildSection(
                    label: 'Tracking Days',
                    isDark: isDark,
                    children: [_buildTrackDayChips()],
                  ),
                  const Gap(20),
                  _buildSection(
                    label: 'Schedule (Optional)',
                    isDark: isDark,
                    children: [
                      _buildTimeTile(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Start Time',
                        value: _startTime != null
                            ? _fmtTime(_startTime!)
                            : 'Not set',
                        onTap: () async {
                          final t = await _pickTime(_startTime);
                          if (t != null) setState(() => _startTime = t);
                        },
                        onClear: _startTime != null
                            ? () => setState(() => _startTime = null)
                            : null,
                      ),
                      const Divider(height: 1, indent: 48),
                      _buildTimeTile(
                        icon: Icons.stop_circle_outlined,
                        label: 'End Time',
                        value: _endTime != null
                            ? _fmtTime(_endTime!)
                            : 'Not set',
                        onTap: () async {
                          final t = await _pickTime(_endTime);
                          if (t != null) setState(() => _endTime = t);
                        },
                        onClear: _endTime != null
                            ? () => setState(() => _endTime = null)
                            : null,
                      ),
                    ],
                  ),
                  const Gap(20),
                  _buildSection(
                    label: 'Reminder',
                    isDark: isDark,
                    children: [
                      _buildToggleTile(
                        icon: Icons.notifications_outlined,
                        label: 'Enable Reminder',
                        value: _reminderEnabled,
                        onChanged: (v) => setState(() => _reminderEnabled = v),
                      ),
                      if (_reminderEnabled) ...[
                        const Divider(height: 1, indent: 48),
                        _buildTimeTile(
                          icon: Icons.access_time_rounded,
                          label: 'Reminder Time',
                          value: _reminderTime != null
                              ? _fmtTime(_reminderTime!)
                              : 'Tap to set',
                          onTap: () async {
                            final t = await _pickTime(_reminderTime);
                            if (t != null) setState(() => _reminderTime = t);
                          },
                          onClear: _reminderTime != null
                              ? () => setState(() => _reminderTime = null)
                              : null,
                        ),
                      ],
                    ],
                  ),
                  const Gap(20),
                  _buildSection(
                    label: 'Location (Optional)',
                    isDark: isDark,
                    children: [
                      _buildToggleTile(
                        icon: Icons.location_on_outlined,
                        label: 'Track Location',
                        value: _locationEnabled,
                        onChanged: (v) => setState(() => _locationEnabled = v),
                      ),
                      if (_locationEnabled) ...[
                        const Divider(height: 1, indent: 48),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: TextFormField(
                            controller: _locationNameCtrl,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.place_outlined),
                              labelText: 'Location name',
                              hintText: 'e.g. Home gym, Local park',
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Gap(20),
                  _buildSection(
                    label: 'Color Theme',
                    isDark: isDark,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildColorPicker(),
                      ),
                    ],
                  ),
                  const Gap(32),
                  _buildSaveButton(),
                  const Gap(24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── gradient header with live preview ─────────────────────────────────────

  Widget _buildGradientHeader(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(gradient: _gradientAt(_colorIndex)),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(false),
                    tooltip: 'Cancel',
                  ),
                  const Spacer(),
                  Text(
                    _isEdit ? 'Edit Habit' : 'New Habit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // balance the close button
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 4),
              child: Column(
                children: [
                  Text(_type.icon, style: const TextStyle(fontSize: 52)),
                  const Gap(8),
                  Text(
                    _titleCtrl.text.trim().isEmpty
                        ? (_isEdit ? 'Edit habit' : 'New habit')
                        : _titleCtrl.text.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Gap(4),
                  Text(
                    _type.displayName + '  •  ' + _goalPeriod.displayName,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── section card ──────────────────────────────────────────────────────────

  Widget _buildSection({
    required String label,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: isDark ? Colors.white54 : Colors.black38,
            fontFamily: 'Inter',
          ),
        ),
        const Gap(8),
        Container(
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
          child: Column(children: children),
        ),
      ],
    );
  }

  // ── title field ───────────────────────────────────────────────────────────

  Widget _buildTitleField(ThemeData theme, bool isDark) {
    return TextFormField(
      controller: _titleCtrl,
      textCapitalization: TextCapitalization.sentences,
      style: theme.textTheme.headlineSmall,
      decoration: InputDecoration(
        hintText: 'Habit title\u2026',
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : Colors.black26,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Title is required';
        if (v.trim().length > 60) return 'Max 60 characters';
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }

  // ── dropdowns ─────────────────────────────────────────────────────────────

  Widget _buildTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: DropdownButtonFormField<HabitType>(
        value: _type,
        decoration: const InputDecoration(
          labelText: 'Habit Type',
          prefixIcon: Icon(Icons.category_outlined),
        ),
        items: HabitType.values.map((t) {
          return DropdownMenuItem(
            value: t,
            child: Row(
              children: [
                Text(t.icon, style: const TextStyle(fontSize: 18)),
                const Gap(10),
                Text(t.displayName),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) setState(() => _type = v);
        },
      ),
    );
  }

  Widget _buildGoalPeriodDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<GoalPeriod>(
        value: _goalPeriod,
        decoration: const InputDecoration(
          labelText: 'Goal Period',
          prefixIcon: Icon(Icons.repeat_rounded),
        ),
        items: GoalPeriod.values.map((p) {
          return DropdownMenuItem(
            value: p,
            child: Text(p.displayName),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) setState(() => _goalPeriod = v);
        },
      ),
    );
  }

  Widget _buildGoalValueField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: TextFormField(
        controller: _goalValueCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        decoration: InputDecoration(
          labelText: _type.goalLabel,
          prefixIcon: const Icon(Icons.flag_outlined),
          suffixText: _type.defaultUnit,
          suffixStyle: TextStyle(
            color: _baseColorAt(_colorIndex),
            fontWeight: FontWeight.w600,
          ),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Enter a goal value';
          final n = double.tryParse(v.trim());
          if (n == null || n <= 0) return 'Enter a positive number';
          return null;
        },
      ),
    );
  }

  // ── tracking day chips ────────────────────────────────────────────────────

  Widget _buildTrackDayChips() {
    final activeColor = _baseColorAt(_colorIndex);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(7, (i) {
          final dayNum = i + 1; // 1=Mon … 7=Sun
          final selected = _trackDays.contains(dayNum);
          return FilterChip(
            label: Text(
              AppConstants.weekDaysShort[i],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? activeColor : null,
              ),
            ),
            selected: selected,
            selectedColor: activeColor.withOpacity(0.15),
            checkmarkColor: activeColor,
            onSelected: (v) {
              setState(() {
                if (v) {
                  _trackDays.add(dayNum);
                  _trackDays.sort();
                } else {
                  _trackDays.remove(dayNum);
                }
              });
            },
          );
        }),
      ),
    );
  }

  // ── time tile ─────────────────────────────────────────────────────────────

  Widget _buildTimeTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: _baseColorAt(_colorIndex)),
      title: Text(label, style: theme.textTheme.bodyMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: _baseColorAt(_colorIndex),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (onClear != null) ...[
            const Gap(4),
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded,
                  size: 16, color: Colors.grey),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  // ── toggle tile ───────────────────────────────────────────────────────────

  Widget _buildToggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return SwitchListTile(
      secondary: Icon(icon, color: _baseColorAt(_colorIndex)),
      title: Text(label, style: theme.textTheme.bodyMedium),
      value: value,
      activeColor: _baseColorAt(_colorIndex),
      onChanged: onChanged,
    );
  }

  // ── color picker ──────────────────────────────────────────────────────────

  /// Displays 6 colored circles; tapping one selects that gradient theme.
  Widget _buildColorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(_kGradientPalette.length, (i) {
        final isSelected = _colorIndex == i;
        return GestureDetector(
          onTap: () => setState(() => _colorIndex = i),
          child: AnimatedContainer(
            duration: AppConstants.shortAnim,
            width: isSelected ? 46 : 36,
            height: isSelected ? 46 : 36,
            decoration: BoxDecoration(
              gradient: _gradientAt(i),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: _kGradientPalette[i][0].withOpacity(0.5),
                      width: 3,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _kGradientPalette[i][0].withOpacity(0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: isSelected
                ? const Center(
                    child: Icon(Icons.check_rounded,
                        color: Colors.white, size: 20))
                : null,
          ),
        );
      }),
    );
  }

  // ── save button ───────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: AppConstants.shortAnim,
      decoration: BoxDecoration(
        gradient: _gradientAt(_colorIndex),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _baseColorAt(_colorIndex).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _saving ? null : _save,
          child: SizedBox(
            height: 54,
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      _isEdit ? 'Save Changes' : 'Create Habit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
