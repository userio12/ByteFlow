import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../../domain/models/usage_time_bucket.dart';

/// 24-hour interactive BarChart displaying hourly data distribution and peak bursts.
class HourlySpikeChart extends StatelessWidget {
  final List<UsageTimeBucket> buckets;
  final int? selectedHour;
  final ValueChanged<int>? onHourSelected;

  const HourlySpikeChart({
    super.key,
    required this.buckets,
    this.selectedHour,
    this.onHourSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (buckets.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No hourly activity recorded today.')),
      );
    }

    final maxBytes = buckets.fold<int>(
      1,
      (max, b) => b.totalBytes > max ? b.totalBytes : max,
    );

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxBytes * 1.15,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colorScheme.surfaceContainerHighest,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final bucket = buckets[groupIndex];
                return BarTooltipItem(
                  '${bucket.label}\n${ByteFormatter.format(rod.toY.round())}',
                  TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
            touchCallback: (event, response) {
              if (event is FlTapUpEvent &&
                  response != null &&
                  response.spot != null) {
                final index = response.spot!.touchedBarGroupIndex;
                if (index >= 0 && index < buckets.length) {
                  onHourSelected?.call(buckets[index].startTime.hour);
                }
              }
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) return const SizedBox.shrink();
                  return Text(
                    ByteFormatter.format(value.round(), decimals: 0),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 4, // Show every 4 hours: 00, 04, 08, 12, 16, 20
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < buckets.length) {
                    if (index % 4 == 0 || index == 23) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          buckets[index].label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(buckets.length, (index) {
            final bucket = buckets[index];
            final hour = bucket.startTime.hour;
            final isSelected = selectedHour == hour;
            final isPeak = bucket.totalBytes == maxBytes && maxBytes > 0;

            final rodColor = isSelected
                ? AppColors.cellular
                : isPeak
                    ? AppColors.statusWarning
                    : colorScheme.primary.withValues(alpha: 0.85);

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: bucket.totalBytes.toDouble(),
                  color: rodColor,
                  width: buckets.length > 12 ? 7 : 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
