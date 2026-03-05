import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/theme.dart';

/// Renders a 30-day trend line chart for a single habit.
///
/// [data] is a list of 30 [MapEntry<DateTime, double>] where the value is:
///   -1.0  → not scheduled on that day (rendered as a gap / skipped)
///    0.0  → scheduled but not completed
///    1.0  → fully completed (values between 0 and 1 are partial)
class MonthlyLineChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> data;
  final Color lineColor;
  final double height;

  const MonthlyLineChart({
    super.key,
    required this.data,
    this.lineColor = AppTheme.primary,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    final labelColor =
        isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4);

    // Build spots, skipping entries where value == -1 (not scheduled).
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final v = data[i].value;
      if (v >= 0) {
        spots.add(FlSpot(i.toDouble(), v));
      }
    }

    if (spots.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data yet',
            style: TextStyle(color: labelColor, fontSize: 13),
          ),
        ),
      );
    }

    // X-axis label indices: show every ~7 days.
    final labelIndices = <int>{0, 6, 13, 20, 27, data.length - 1};

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 1,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.25,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: gridColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 0.5,
                getTitlesWidget: (value, meta) {
                  final label = value == 0
                      ? '0%'
                      : value == 0.5
                          ? '50%'
                          : value == 1
                              ? '100%'
                              : '';
                  if (label.isEmpty) return const SizedBox.shrink();
                  return Text(
                    label,
                    style: TextStyle(fontSize: 10, color: labelColor),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (!labelIndices.contains(idx) || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final date = data[idx].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('d MMM').format(date),
                      style: TextStyle(fontSize: 9, color: labelColor),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF252540) : Colors.white,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((ts) {
                  final idx = ts.x.toInt();
                  final date =
                      idx < data.length ? data[idx].key : DateTime.now();
                  final pct = (ts.y * 100).round();
                  return LineTooltipItem(
                    '${DateFormat('MMM d').format(date)}\n$pct%',
                    TextStyle(
                      color: lineColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: lineColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, barData, idx) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: lineColor,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withOpacity(0.25),
                    lineColor.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ),
    );
  }
}
