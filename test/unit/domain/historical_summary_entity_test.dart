import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/domain/models/historical_summary_entity.dart';
import 'package:byteflow/domain/models/time_range.dart';

void main() {
  group('HistoricalSummaryEntity', () {
    final testBounds = DateRange(
      start: DateTime(2024, 1, 1),
      end: DateTime(2024, 1, 2),
    );

    test('grandTotal sums mobile and wifi data bytes', () {
      final summary = HistoricalSummaryEntity(
        range: TimeRange.today,
        dateBounds: testBounds,
        totalMobileBytes: 1000,
        totalWifiBytes: 3000,
        buckets: const [],
        topApps: const [],
        averageDailyBytes: 4000,
      );

      expect(summary.grandTotal, equals(4000));
    });

    test('wifiOffloadPercentage computes percentage accurately', () {
      // 0 bytes total -> 0.0%
      final zeroSummary = HistoricalSummaryEntity(
        range: TimeRange.today,
        dateBounds: testBounds,
        totalMobileBytes: 0,
        totalWifiBytes: 0,
        buckets: const [],
        topApps: const [],
        averageDailyBytes: 0,
      );
      expect(zeroSummary.wifiOffloadPercentage, equals(0.0));

      // 50% split
      final splitSummary = HistoricalSummaryEntity(
        range: TimeRange.week,
        dateBounds: testBounds,
        totalMobileBytes: 500,
        totalWifiBytes: 500,
        buckets: const [],
        topApps: const [],
        averageDailyBytes: 1000,
      );
      expect(splitSummary.wifiOffloadPercentage, equals(50.0));

      // 100% Wi-Fi
      final fullWifiSummary = HistoricalSummaryEntity(
        range: TimeRange.month,
        dateBounds: testBounds,
        totalMobileBytes: 0,
        totalWifiBytes: 1000,
        buckets: const [],
        topApps: const [],
        averageDailyBytes: 1000,
      );
      expect(fullWifiSummary.wifiOffloadPercentage, equals(100.0));
    });

    test('supports equality and toString', () {
      final s1 = HistoricalSummaryEntity(
        range: TimeRange.today,
        dateBounds: testBounds,
        totalMobileBytes: 100,
        totalWifiBytes: 200,
        buckets: const [],
        topApps: const [],
        averageDailyBytes: 300,
      );
      final s2 = HistoricalSummaryEntity(
        range: TimeRange.today,
        dateBounds: testBounds,
        totalMobileBytes: 100,
        totalWifiBytes: 200,
        buckets: const [],
        topApps: const [],
        averageDailyBytes: 300,
      );
      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1.toString(), contains('HistoricalSummaryEntity'));
    });
  });
}
