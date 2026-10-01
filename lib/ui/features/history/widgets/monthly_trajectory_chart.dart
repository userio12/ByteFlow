import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/channel_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../../domain/models/usage_time_bucket.dart';

/// 30-day cumulative consumption burn LineChart comparing recorded usage with ideal linear quota pace.
class MonthlyTrajectoryChart extends StatelessWidget {
  final List<UsageTimeBucket> buckets;
  final int quotaBytes;
  final int networkType;
  final double chartHeight;

  const MonthlyTrajectoryChart({
    super.key,
    required this.buckets,
    required this.quotaBytes,
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
        child: Center(child: Text('No monthly activity recorded.')),
      );
    }

    final isWifiOnly = networkType == ChannelConstants.networkTypeWifi;
    final isMobileOnly = networkType == ChannelConstants.networkTypeMobile;

    // Compute cumulative actual spots
    final actualSpots = <FlSpot>[];
    int cumulative = 0;
    for (int i = 0; i < buckets.length; i++) {
      if (isWifiOnly) {
        cumulative += buckets[i].totalWifiBytes;
      } else if (isMobileOnly) {
        cumulative += buckets[i].totalMobileBytes;
      } else {
        cumulative += buckets[i].totalBytes;
      }
      actualSpots.add(FlSpot(i.toDouble(), cumulative.toDouble()));
    }

    // Compute ideal linear pace spots across the total days
    final totalDays = buckets.length > 1 ? buckets.length : 30;
    final idealSpots = <FlSpot>[];
    for (int i = 0; i < totalDays; i++) {
      final idealY = (quotaBytes / totalDays) * (i + 1);
      idealSpots.add(FlSpot(i.toDouble(), idealY));
    }

    final maxY = [
      quotaBytes.toDouble() * 1.1,
      cumulative.toDouble() * 1.15,
    ].reduce((a, b) => a > b ? a : b);

    final lineColor = isWifiOnly ? AppColors.wifi : AppColors.cellular;
    final legendLabel = isWifiOnly
        ? 'Wi-Fi Used'
        : isMobileOnly
            ? 'Cellular Used'
            : 'Actual Used';

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLegend(lineColor, legendLabel, isDashed: false),
            const SizedBox(width: 16),
            _buildLegend(
              colorScheme.outlineVariant,
              'Ideal Quota Pace',
              isDashed: true,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Line Chart
        SizedBox(
          height: chartHeight,
          child: LineChart(
            LineChartData(
              maxY: maxY,
              minY: 0,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.surfaceContainerHighest,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isActual = spot.barIndex == 0;
                      final label = isActual ? 'Actual' : 'Ideal';
                      final dayIndex = spot.x.toInt();
                      final dayLabel = dayIndex < buckets.length
                          ? buckets[dayIndex].label
                          : 'Day ${dayIndex + 1}';
                      return LineTooltipItem(
                        '$dayLabel ($label)\n${ByteFormatter.format(spot.y.round())}',
                        TextStyle(
                          color: isActual ? lineColor : colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
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
                    reservedSize: 44,
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
                    interval: (totalDays / 5).ceilToDouble().clamp(1.0, 7.0),
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
              lineBarsData: [
                // 1. Actual cumulative burn curve
                LineChartBarData(
                  spots: actualSpots,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withValues(alpha: 0.12),
                  ),
                ),
                // 2. Ideal linear pace line
                LineChartBarData(
                  spots: idealSpots,
                  isCurved: false,
                  color: colorScheme.outlineVariant,
                  barWidth: 2,
                  dashArray: [6, 4],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String label, {required bool isDashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
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
