import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/errors/app_failure.dart';
import 'package:byteflow/domain/models/historical_summary_entity.dart';
import 'package:byteflow/domain/models/time_range.dart';
import 'package:byteflow/domain/models/usage_time_bucket.dart';
import 'package:byteflow/domain/use_cases/get_historical_summary_use_case.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  group('GetHistoricalSummaryUseCase Unit Test', () {
    late FakeNetworkRepository fakeNetworkRepo;
    late GetHistoricalSummaryUseCase useCase;

    setUp(() {
      fakeNetworkRepo = FakeNetworkRepository();
      useCase = GetHistoricalSummaryUseCase(fakeNetworkRepo);
    });

    test('successfully retrieves historical summary for weekly timeframe', () async {
      final bounds = TimeRange.week.calculateBounds();
      fakeNetworkRepo.historicalSummary = HistoricalSummaryEntity(
        range: TimeRange.week,
        dateBounds: bounds,
        totalMobileBytes: 104857600, // 100 MB
        totalWifiBytes: 419430400,  // 400 MB
        buckets: [
          UsageTimeBucket(
            startTime: bounds.start,
            endTime: bounds.end,
            label: 'Mon',
            mobileRxBytes: 52428800,
            mobileTxBytes: 52428800,
            wifiRxBytes: 209715200,
            wifiTxBytes: 209715200,
          ),
        ],
        topApps: const [],
        averageDailyBytes: 74898457,
      );

      final result = await useCase(range: TimeRange.week, billingResetDay: 1);

      expect(result.isSuccess, isTrue);
      result.when(
        success: (summary) {
          expect(summary.range, equals(TimeRange.week));
          expect(summary.totalMobileBytes, equals(104857600));
          expect(summary.totalWifiBytes, equals(419430400));
          expect(summary.wifiOffloadPercentage, closeTo(80.0, 0.1)); // 400 / 500 = 80%
        },
        failure: (f) => fail('Expected success, got $f'),
      );
    });

    test('propagates failure when repository fails', () async {
      fakeNetworkRepo.errorToReturn =
          const DatabaseFailure(message: 'SQLite disk I/O failure');

      final result = await useCase(range: TimeRange.month);

      expect(result.isFailure, isTrue);
      result.when(
        success: (_) => fail('Expected failure'),
        failure: (f) => expect(f.message, contains('SQLite disk I/O failure')),
      );
    });
  });
}
