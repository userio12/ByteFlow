import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../../../domain/models/historical_summary_entity.dart';
import '../../../core/widgets/metric_card.dart';

/// 2x2 grid of high-level analytics cards: Daily Average, Projected Total, Offload Ratio, and Peak.
class InsightsGrid extends StatelessWidget {
  final HistoricalSummaryEntity summary;

  const InsightsGrid({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final dailyAvg = ByteFormatter.format(summary.averageDailyBytes.round());
    final projectedMonthly = ByteFormatter.format(
      (summary.averageDailyBytes * 30).round(),
    );
    final offloadPercent = summary.wifiOffloadPercentage.toStringAsFixed(0);
    final cellPercent = (100 - summary.wifiOffloadPercentage).toStringAsFixed(0);

    final peakBucket = summary.peakBucket;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Daily Average',
                value: dailyAvg,
                subtitle: 'Rolling burn rate',
                icon: AppIcons.historyActive,
                iconColor: AppColors.cellular,
                padding: const EdgeInsets.all(14.0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Projected 30d',
                value: projectedMonthly,
                subtitle: 'Based on daily burn',
                icon: AppIcons.planActive,
                iconColor: AppColors.hotspot,
                padding: const EdgeInsets.all(14.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Cell / Wi-Fi Ratio',
                value: '$cellPercent% / $offloadPercent%',
                subtitle: '$offloadPercent% offloaded',
                icon: AppIcons.wifi,
                iconColor: AppColors.wifi,
                padding: const EdgeInsets.all(14.0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Peak Period',
                value: peakBucket?.label ?? 'None',
                subtitle: peakBucket != null
                    ? ByteFormatter.format(peakBucket.totalBytes)
                    : 'No peak detected',
                icon: AppIcons.alertWarning,
                iconColor: AppColors.statusWarning,
                padding: const EdgeInsets.all(14.0),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
