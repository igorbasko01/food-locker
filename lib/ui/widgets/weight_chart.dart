import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:food_locker/core/date_format.dart';
import 'package:food_locker/features/weight/data/weight.dart';

class WeightChart extends StatelessWidget {
  final List<Weight> weights;

  const WeightChart({super.key, required this.weights});

  @override
  Widget build(BuildContext context) {
    if (weights.isEmpty) {
      return const Center(child: Text('No weight data to display.', style: TextStyle(color: Colors.grey)));
    }

    // Sort ascending for chart (earliest to latest)
    final sortedWeights = List<Weight>.from(weights);
    sortedWeights.sort((a, b) => a.date.compareTo(b.date));

    final spots = sortedWeights.map((w) {
      // Use time relative to first entry for X-axis to keep values smaller
      final ms = w.date.millisecondsSinceEpoch.toDouble();
      return FlSpot(ms, w.value);
    }).toList();

    double minY = sortedWeights.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    double maxY = sortedWeights.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // Padding for Y axis
    minY = (minY - 2).clamp(0, double.infinity);
    maxY = maxY + 2;

    int spotCount = spots.length;
    double minX = spots.first.x;
    double maxX = spots.last.x;
    if (minX == maxX) {
      // Handle single entry graph
      minX -= 86400000;
      maxX += 86400000;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (maxX - minX) / (spotCount > 5 ? 5 : spotCount).clamp(1, double.infinity),
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(shortDate(date), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                  return LineTooltipItem(
                    '${fullDateWithWeekday(date)}\n${spot.y} kg',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
