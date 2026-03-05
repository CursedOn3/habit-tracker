import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class WeeklyBarChart extends StatelessWidget {
  final List<double> data; // 7 values, 0.0 to 1.0

  const WeeklyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1.0,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.surface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${(rod.toY * 100).round()}%',
                  TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
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
                  if (idx < 0 || idx >= AppConstants.weekDays.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      AppConstants.weekDays[idx],
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
                reservedSize: 24,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 0.5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${(value * 100).round()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  );
                },
                reservedSize: 36,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: 0.5,
            getDrawingHorizontalLine:
                (_) => FlLine(
                  color: theme.dividerColor.withOpacity(0.3),
                  strokeWidth: 1,
                ),
          ),
          barGroups: List.generate(data.length, (i) {
            final value = data[i].clamp(0.0, 1.0);
            final isToday = i == DateTime.now().weekday - 1;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color:
                      isToday
                          ? AppTheme.primaryColor
                          : value >= 1.0
                          ? AppTheme.successColor
                          : AppTheme.primaryColor.withOpacity(0.5),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 1.0,
                    color: AppTheme.primaryColor.withOpacity(0.08),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
