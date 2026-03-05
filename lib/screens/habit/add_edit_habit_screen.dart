import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final Habit? habit; // null = add mode

  const AddEditHabitScreen({super.key, this.habit});

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _goalValueController = TextEditingController();
  final _customUnitController = TextEditingController();

  HabitType _selectedType = HabitType.custom;
  GoalPeriod _selectedPeriod = GoalPeriod.daily;
  List<int> _trackDays = [0, 1, 2, 3, 4, 5, 6]; // All days by default
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  TimeOfDay? _reminderTime;
  bool _reminderEnabled = false;
  bool _locationEnabled = false;
  HabitLocation? _location;
  int _colorIndex = 0;
  bool _isLoading = false;

  String get _goalUnit {
    if (_selectedType == HabitType.custom) {
      return _customUnitController.text.isEmpty
          ? 'units'
          : _customUnitController.text;
    }
    return _selectedType.goalUnit;
  }

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _populateFromHabit(widget.habit!);
    }
  }

  void _populateFromHabit(Habit habit) {
    _titleController.text = habit.title;
    _goalValueController.text = habit.goalValue.toString();
    _customUnitController.text = habit.customUnit ?? '';
    _selectedType = habit.type;
    _selectedPeriod = habit.goalPeriod;
    _trackDays = List<int>.from(habit.trackDays);
    _reminderEnabled = habit.reminderEnabled;
    _locationEnabled = habit.locationEnabled;
    _location = habit.location;
    _colorIndex = habit.colorIndex;

    if (habit.startTime != null) {
      final parts = habit.startTime!.split(':');
      _startTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    if (habit.endTime != null) {
      final parts = habit.endTime!.split(':');
      _endTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    if (habit.reminderTime != null) {
      final parts = habit.reminderTime!.split(':');
      _reminderTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _goalValueController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(
    BuildContext context,
    TimeOfDay? initial,
    void Function(TimeOfDay?) onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
    );
    onPicked(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_trackDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one day')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final habit = Habit(
        id: widget.habit?.id ?? '',
        title: _titleController.text.trim(),
        type: _selectedType,
        goalPeriod: _selectedPeriod,
        goalValue: double.tryParse(_goalValueController.text) ?? 1.0,
        trackDays: _trackDays,
        startTime: _startTime != null ? _timeOfDayToString(_startTime!) : null,
        endTime: _endTime != null ? _timeOfDayToString(_endTime!) : null,
        reminderTime:
            _reminderEnabled && _reminderTime != null
                ? _timeOfDayToString(_reminderTime!)
                : null,
        reminderEnabled: _reminderEnabled,
        locationEnabled: _locationEnabled,
        location: _location,
        completions: widget.habit?.completions ?? {},
        createdAt: widget.habit?.createdAt,
        userId: widget.habit?.userId,
        colorIndex: _colorIndex,
        customUnit:
            _selectedType == HabitType.custom
                ? _customUnitController.text.trim()
                : null,
      );

      if (widget.habit == null) {
        await ref.read(habitNotifierProvider.notifier).addHabit(habit);
      } else {
        await ref.read(habitNotifierProvider.notifier).updateHabit(habit);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.habit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Habit' : 'New Habit'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            _SectionHeader(label: 'Habit Name'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. Morning Run, Read 30 pages...',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please enter a title' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // Color picker
            _SectionHeader(label: 'Color'),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppTheme.habitColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final color = AppTheme.habitColors[i];
                  return GestureDetector(
                    onTap: () => setState(() => _colorIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: _colorIndex == i
                            ? Border.all(
                              color: theme.colorScheme.onSurface,
                              width: 2.5,
                            )
                            : null,
                      ),
                      child: _colorIndex == i
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Type dropdown
            _SectionHeader(label: 'Habit Type'),
            DropdownButtonFormField<HabitType>(
              value: _selectedType,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: HabitType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Text(t.icon),
                          const SizedBox(width: 8),
                          Text(t.displayName),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),

            // Custom unit (only for custom type)
            if (_selectedType == HabitType.custom) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customUnitController,
                decoration: const InputDecoration(
                  labelText: 'Unit (e.g. glasses, pushups)',
                  prefixIcon: Icon(Icons.straighten_outlined),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Goal Period + Goal Value
            _SectionHeader(label: 'Goal'),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<GoalPeriod>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: 'Period',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    items: GoalPeriod.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPeriod = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _goalValueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Target (${_goalUnit})',
                      prefixIcon: const Icon(Icons.flag_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      if (double.parse(v) <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Track days
            _SectionHeader(label: 'Track Days'),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final selected = _trackDays.contains(i);
                return FilterChip(
                  label: Text(AppConstants.weekDays[i]),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _trackDays.add(i);
                        _trackDays.sort();
                      } else {
                        _trackDays.remove(i);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryColor,
                );
              }),
            ),
            const SizedBox(height: 20),

            // Time range
            _SectionHeader(label: 'Time Range (optional)'),
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Start Time',
                    time: _startTime,
                    onTap: () => _pickTime(
                      context,
                      _startTime,
                      (t) => setState(() => _startTime = t),
                    ),
                    onClear: () => setState(() => _startTime = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePicker(
                    label: 'End Time',
                    time: _endTime,
                    onTap: () => _pickTime(
                      context,
                      _endTime,
                      (t) => setState(() => _endTime = t),
                    ),
                    onClear: () => setState(() => _endTime = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Reminder
            _SectionHeader(label: 'Reminder'),
            SwitchListTile(
              title: const Text('Enable Reminder'),
              subtitle: const Text('Get notified at a specific time'),
              value: _reminderEnabled,
              onChanged: (v) => setState(() => _reminderEnabled = v),
              activeColor: AppTheme.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              _TimePicker(
                label: 'Reminder Time',
                time: _reminderTime,
                onTap: () => _pickTime(
                  context,
                  _reminderTime,
                  (t) => setState(() => _reminderTime = t),
                ),
                onClear: () => setState(() => _reminderTime = null),
              ),
            ],
            const SizedBox(height: 20),

            // Location
            _SectionHeader(label: 'Location Reminder'),
            SwitchListTile(
              title: const Text('Enable Location Trigger'),
              subtitle: const Text('Remind when near a specific location'),
              value: _locationEnabled,
              onChanged: (v) {
                setState(() => _locationEnabled = v);
                if (v && _location == null) {
                  _showLocationPicker();
                }
              },
              activeColor: AppTheme.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            if (_locationEnabled && _location != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _location?.address ??
                            '${_location?.latitude.toStringAsFixed(4)}, ${_location?.longitude.toStringAsFixed(4)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: _showLocationPicker,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(isEdit ? 'Save Changes' : 'Create Habit'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() {
    // Location picker placeholder - show a dialog to enter coordinates
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Set Location'),
            content: const Text(
              'Google Maps integration requires a valid API key.\n\n'
              'To enable location reminders:\n'
              '1. Get a Google Maps API key\n'
              '2. Replace YOUR_GOOGLE_MAPS_API_KEY in constants.dart\n'
              '3. Enable Maps SDK for Android/iOS in Google Cloud Console',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _locationEnabled = false;
                    _location = null;
                  });
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Set a placeholder location
                  setState(() {
                    _location = HabitLocation(
                      latitude: 27.7172,
                      longitude: 85.3240,
                      address: 'Kathmandu, Nepal',
                    );
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Use Placeholder'),
              ),
            ],
          ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Habit'),
            content: Text(
              'Are you sure you want to delete "${widget.habit?.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(habitNotifierProvider.notifier)
                      .deleteHabit(widget.habit!.id);
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _TimePicker({
    required this.label,
    this.time,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                time != null
                    ? AppTheme.primaryColor
                    : theme.dividerColor,
          ),
          borderRadius: BorderRadius.circular(12),
          color: time != null
              ? AppTheme.primaryColor.withOpacity(0.05)
              : theme.inputDecorationTheme.fillColor,
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 18,
              color: time != null ? AppTheme.primaryColor : theme.hintColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                time != null ? time!.format(context) : label,
                style: TextStyle(
                  color:
                      time != null
                          ? AppTheme.primaryColor
                          : theme.hintColor,
                  fontWeight:
                      time != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (time != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.clear, size: 16, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
