import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../../domain/models/usage_time_bucket.dart';

/// 7-day grouped BarChart comparing daily Cellular vs Wi-Fi data consumption.
class WeeklyComparisonChart extends StatelessWidget {
  final List<UsageTimeBucket> buckets;

  const WeeklyComparisonChart({
    super.key,
    required this.buckets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (buckets.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No weekly activity recorded.')),
      );
    }

    final maxBytes = buckets.fold<int>(
      1,
      (max, b) {
        final larger = b.totalMobileBytes > b.totalWifiBytes
            ? b.totalMobileBytes
            : b.totalWifiBytes;
        return larger > max ? larger : max;
      },
    );

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLegend(AppColors.cellular, 'Cellular', colorScheme),
            const SizedBox(width: 16),
            _buildLegend(AppColors.wifi, 'Wi-Fi', colorScheme),
          ],
        ),
        const SizedBox(height: 12),

        // Chart
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxBytes * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.surfaceContainerHighest,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final bucket = buckets[groupIndex];
                    final isCellular = rodIndex == 0;
                    final type = isCellular ? 'Cellular' : 'Wi-Fi';
                    final bytes = isCellular
                        ? bucket.totalMobileBytes
                        : bucket.totalWifiBytes;

                    return BarTooltipItem(
                      '${bucket.label} ($type)\n${ByteFormatter.format(bytes)}',
                      TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
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
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < buckets.length) {
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
                return BarChartGroupData(
                  x: index,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: bucket.totalMobileBytes.toDouble(),
                      color: AppColors.cellular,
                      width: 10,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    BarChartRodData(
                      toY: bucket.totalWifiBytes.toDouble(),
                      color: AppColors.wifi,
                      width: 10,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String label, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
