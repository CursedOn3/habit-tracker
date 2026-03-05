import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class WeeklyBarChart extends StatelessWidget {
  final List<double> weeklyData; // 7 values, -1 = not scheduled, 0-1 = completion
  final String userId;

  const WeeklyBarChart({
    super.key,
    required this.weeklyData,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('This Week', style: theme.textTheme.titleLarge),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_completedCount()} / ${_scheduledCount()} days',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final val = weeklyData[groupIndex];
                      if (val < 0) return null;
                      return BarTooltipItem(
                        '${(val * 100).round()}%',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= AppConstants.weekDaysShort.length) {
                          return const SizedBox.shrink();
                        }
                        final today = DateTime.now();
                        final isToday = idx == today.weekday - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            AppConstants.weekDaysShort[idx],
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                              color: isToday
                                  ? AppTheme.primary
                                  : theme.colorScheme.outline,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.outline.withOpacity(0.15),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final val = weeklyData.length > i ? weeklyData[i] : 0.0;
                  final isNotScheduled = val < 0;
                  final today = DateTime.now();
                  final isToday = i == today.weekday - 1;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: isNotScheduled ? 0.05 : val.clamp(0.05, 1.0),
                        gradient: isNotScheduled
                            ? null
                            : LinearGradient(
                                colors: isToday
                                    ? [AppTheme.primary, AppTheme.primaryLight]
                                    : [
                                        val >= 1
                                            ? AppTheme.success
                                            : AppTheme.primary.withOpacity(0.5 + val * 0.5),
                                        val >= 1
                                            ? AppTheme.accent
                                            : AppTheme.primaryLight.withOpacity(0.5 + val * 0.5),
                                      ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                        color: isNotScheduled ? theme.colorScheme.outline.withOpacity(0.15) : null,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _completedCount() {
    return weeklyData.where((v) => v >= 1.0).length;
  }

  int _scheduledCount() {
    return weeklyData.where((v) => v >= 0).length;
  }
}
