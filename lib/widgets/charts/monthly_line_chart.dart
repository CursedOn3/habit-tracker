import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class MonthlyLineChart extends StatelessWidget {
  final List<double> data; // values per day in month, -1 = future

  const MonthlyLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      if (data[i] >= 0) {
        spots.add(FlSpot(i.toDouble(), data[i]));
      }
    }

    if (spots.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No data yet',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: 1.0,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.surface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    'Day ${spot.x.toInt() + 1}: ${(spot.y * 100).round()}%',
                    TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 7,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt() + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  );
                },
                reservedSize: 20,
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
                      fontSize: 9,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  );
                },
                reservedSize: 32,
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
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: AppTheme.primaryColor,
                    strokeColor: Colors.white,
                    strokeWidth: 1.5,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.3),
                    AppTheme.primaryColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
