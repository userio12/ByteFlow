import 'app_usage_entity.dart';
import 'time_range.dart';
import 'usage_time_bucket.dart';

/// Aggregated multi-timeframe statistics container (Today, Weekly, Monthly, Yearly).
class HistoricalSummaryEntity {
  final TimeRange range;
  final DateRange dateBounds;
  final int totalMobileBytes;
  final int totalWifiBytes;
  final List<UsageTimeBucket> buckets;
  final List<AppUsageEntity> topApps;
  final double averageDailyBytes;
  final UsageTimeBucket? peakBucket;

  const HistoricalSummaryEntity({
    required this.range,
    required this.dateBounds,
    required this.totalMobileBytes,
    required this.totalWifiBytes,
    required this.buckets,
    required this.topApps,
    required this.averageDailyBytes,
    this.peakBucket,
  });

  int get grandTotal => totalMobileBytes + totalWifiBytes;

  /// Percentage of total data offloaded to Wi-Fi rather than cellular (0.0 - 100.0).
  double get wifiOffloadPercentage {
    if (grandTotal == 0) return 0.0;
    return (totalWifiBytes / grandTotal) * 100.0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoricalSummaryEntity &&
          runtimeType == other.runtimeType &&
          range == other.range &&
          dateBounds == other.dateBounds &&
          totalMobileBytes == other.totalMobileBytes &&
          totalWifiBytes == other.totalWifiBytes &&
          averageDailyBytes == other.averageDailyBytes;

  @override
  int get hashCode => Object.hash(
        range,
        dateBounds,
        totalMobileBytes,
        totalWifiBytes,
        averageDailyBytes,
      );

  @override
  String toString() =>
      'HistoricalSummaryEntity(range: ${range.displayName}, grandTotal: $grandTotal, offload: ${wifiOffloadPercentage.toStringAsFixed(1)}%)';
}
