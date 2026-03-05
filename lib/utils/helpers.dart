import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String toFormattedDate() => DateFormat('MMM dd, yyyy').format(this);
  String toShortDate() => DateFormat('MMM dd').format(this);
  String toTimeString() => DateFormat('hh:mm a').format(this);
  String toDateKey() => DateFormat('yyyy-MM-dd').format(this);
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String toTitleCase() => split(' ').map((w) => w.capitalize()).join(' ');
}

extension DoubleExtension on double {
  String toDisplayString({int decimals = 1}) {
    if (this == truncateToDouble()) return toInt().toString();
    return toStringAsFixed(decimals);
  }
}

String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

String getWeekRange(DateTime date) {
  final start = date.subtract(Duration(days: date.weekday - 1));
  final end = start.add(const Duration(days: 6));
  return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
}

DateTime startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
DateTime endOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day, 23, 59, 59);
DateTime startOfWeek(DateTime dt) =>
    startOfDay(dt.subtract(Duration(days: dt.weekday - 1)));
DateTime startOfMonth(DateTime dt) => DateTime(dt.year, dt.month, 1);
