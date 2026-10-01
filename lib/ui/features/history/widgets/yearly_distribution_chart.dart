import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/channel_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../../domain/models/usage_time_bucket.dart';

/// 12-month annual distribution BarChart comparing Cellular vs Wi-Fi offload ratio.
class YearlyDistributionChart extends StatelessWidget {
  final List<UsageTimeBucket> buckets;
  final int networkType;
  final double chartHeight;

  const YearlyDistributionChart({
    super.key,
    required this.buckets,
    this.networkType = ChannelConstants.networkTypeAll,
    this.chartHeight = 340.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (buckets.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: Text('No yearly historical data recorded.')),
      );
    }

    final showCellular = networkType == ChannelConstants.networkTypeAll ||
        networkType == ChannelConstants.networkTypeMobile;
    final showWifi = networkType == ChannelConstants.networkTypeAll ||
        networkType == ChannelConstants.networkTypeWifi;
    final showBoth = showCellular && showWifi;

    final maxBytes = buckets.fold<int>(
      1,
      (max, b) {
        int candidate = 0;
        if (showBoth) {
          candidate = b.totalBytes;
        } else if (showCellular) {
          candidate = b.totalMobileBytes;
        } else {
          candidate = b.totalWifiBytes;
        }
        return candidate > max ? candidate : max;
      },
    );

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (showCellular)
              _buildLegend(AppColors.cellular, 'Cellular'),
            if (showBoth) const SizedBox(width: 16),
            if (showWifi)
              _buildLegend(AppColors.wifi, showBoth ? 'Wi-Fi Offload' : 'Wi-Fi'),
          ],
        ),
        const SizedBox(height: 12),

        // Stacked BarChart
        SizedBox(
          height: chartHeight,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxBytes * 1.15,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.surfaceContainerHighest,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final bucket = buckets[groupIndex];
                    if (showBoth) {
                      final offload = bucket.totalBytes > 0
                          ? (bucket.totalWifiBytes / bucket.totalBytes * 100)
                              .toStringAsFixed(0)
                          : '0';

                      return BarTooltipItem(
                        '${bucket.label}\n'
                        'Total: ${ByteFormatter.format(bucket.totalBytes)}\n'
                        'Cell: ${ByteFormatter.format(bucket.totalMobileBytes)}\n'
                        'Wi-Fi: ${ByteFormatter.format(bucket.totalWifiBytes)} ($offload% offload)',
                        TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    } else if (showCellular) {
                      return BarTooltipItem(
                        '${bucket.label}\n'
                        'Cell: ${ByteFormatter.format(bucket.totalMobileBytes)}',
                        TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    } else {
                      return BarTooltipItem(
                        '${bucket.label}\n'
                        'Wi-Fi: ${ByteFormatter.format(bucket.totalWifiBytes)}',
                        TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    }
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value == meta.max) {
                        return const SizedBox.shrink();
                      }
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

                if (showBoth) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: bucket.totalBytes.toDouble(),
                        rodStackItems: [
                          BarChartRodStackItem(
                            0,
                            bucket.totalMobileBytes.toDouble(),
                            AppColors.cellular,
                          ),
                          BarChartRodStackItem(
                            bucket.totalMobileBytes.toDouble(),
                            bucket.totalBytes.toDouble(),
                            AppColors.wifi,
                          ),
                        ],
                        width: 14,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                } else if (showCellular) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: bucket.totalMobileBytes.toDouble(),
                        color: AppColors.cellular,
                        width: 14,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                } else {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: bucket.totalWifiBytes.toDouble(),
                        color: AppColors.wifi,
                        width: 14,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String label) {
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
