import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/rating.dart';
import '../models/supplier.dart';
import '../theme/app_theme.dart';

class RatingBarChart extends StatelessWidget {
  final List<Supplier> suppliers;
  final Map<String, Rating> ratingsMap;

  const RatingBarChart({
    super.key,
    required this.suppliers,
    required this.ratingsMap,
  });

  @override
  Widget build(BuildContext context) {
    // Collect vendors that have calculated total scores
    final scoredList = <MapEntry<Supplier, int>>[];
    for (final s in suppliers) {
      final r = ratingsMap[s.id];
      if (r?.total != null) {
        scoredList.add(MapEntry(s, r!.total!));
      }
    }

    if (scoredList.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Text(
          'No rating scores recorded yet for this period.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: AppTheme.primaryLight,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Vendor Total Performance Score (Out of 100)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Target: >= 80',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gradeGood,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: AppTheme.borderColor, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: AppTheme.borderColor, width: 1),
                      left: BorderSide(color: AppTheme.borderColor, width: 1),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < scoredList.length) {
                            final vendor = scoredList[idx].key;
                            // Display short name / ID
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                vendor.id,
                                style: const TextStyle(
                                  color: AppTheme.textDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  barGroups: scoredList.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final total = entry.value.value;
                    Color barColor;
                    if (total >= 90) {
                      barColor = AppTheme.gradeExcellent;
                    } else if (total >= 80) {
                      barColor = AppTheme.gradeGood;
                    } else if (total >= 60) {
                      barColor = AppTheme.gradeAverage;
                    } else {
                      barColor = AppTheme.gradePoor;
                    }

                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: total.toDouble(),
                          color: barColor,
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
