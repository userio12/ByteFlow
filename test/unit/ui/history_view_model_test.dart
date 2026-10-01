import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/constants/channel_constants.dart';
import 'package:byteflow/domain/models/historical_summary_entity.dart';
import 'package:byteflow/domain/models/time_range.dart';
import 'package:byteflow/domain/models/usage_time_bucket.dart';
import 'package:byteflow/domain/use_cases/get_historical_summary_use_case.dart';
import 'package:byteflow/ui/features/history/view_models/history_view_model.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  group('HistoryViewModel Unit Tests', () {
    late FakeNetworkRepository fakeNetworkRepo;
    late FakePlanRepository fakePlanRepo;
    late HistoryViewModel viewModel;

    setUp(() {
      fakeNetworkRepo = FakeNetworkRepository();
      fakePlanRepo = FakePlanRepository();

      final now = DateTime.now();
      final todayBounds = TimeRange.today.calculateBounds();
      final buckets = List.generate(24, (hour) {
        return UsageTimeBucket(
          startTime: DateTime(now.year, now.month, now.day, hour),
          endTime: DateTime(now.year, now.month, now.day, hour + 1),
          label: '${hour.toString().padLeft(2, '0')}:00',
          mobileRxBytes: 1000000,
          mobileTxBytes: 200000,
          wifiRxBytes: 5000000,
          wifiTxBytes: 1000000,
        );
      });

      fakeNetworkRepo.historicalSummary = HistoricalSummaryEntity(
        range: TimeRange.today,
        dateBounds: todayBounds,
        totalMobileBytes: 28800000,
        totalWifiBytes: 144000000,
        buckets: buckets,
        topApps: const [],
        averageDailyBytes: 172800000.0,
      );

      viewModel = HistoryViewModel(
        getHistoricalSummaryUseCase:
            GetHistoricalSummaryUseCase(fakeNetworkRepo),
        planRepository: fakePlanRepo,
      );
    });

    test('initial state has correct defaults', () {
      expect(viewModel.selectedRange, equals(TimeRange.today));
      expect(
          viewModel.selectedNetworkType, equals(ChannelConstants.networkTypeAll));
      expect(viewModel.summary, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('setNetworkType updates selectedNetworkType and notifies listeners', () {
      var listenerCalled = false;
      viewModel.addListener(() {
        listenerCalled = true;
      });

      viewModel.setNetworkType(ChannelConstants.networkTypeMobile);

      expect(viewModel.selectedNetworkType,
          equals(ChannelConstants.networkTypeMobile));
      expect(listenerCalled, isTrue);

      listenerCalled = false;
      viewModel.setNetworkType(ChannelConstants.networkTypeWifi);

      expect(viewModel.selectedNetworkType,
          equals(ChannelConstants.networkTypeWifi));
      expect(listenerCalled, isTrue);
    });

    test('setNetworkType ignores duplicate selection', () {
      var callCount = 0;
      viewModel.addListener(() {
        callCount++;
      });

      viewModel.setNetworkType(ChannelConstants.networkTypeAll);

      expect(callCount, equals(0));
    });

    test('setTimeRange loads summary data for new range', () async {
      await viewModel.setTimeRange(TimeRange.week);

      expect(viewModel.selectedRange, equals(TimeRange.week));
      expect(viewModel.summary, isNotNull);
    });

    test('isFiltered returns false on default and true when modified', () async {
      expect(viewModel.isFiltered, isFalse);

      viewModel.setNetworkType(ChannelConstants.networkTypeMobile);
      expect(viewModel.isFiltered, isTrue);

      viewModel.setNetworkType(ChannelConstants.networkTypeAll);
      expect(viewModel.isFiltered, isFalse);

      await viewModel.setTimeRange(TimeRange.month);
      expect(viewModel.isFiltered, isTrue);
    });

    test('totalFilteredBytes returns appropriate totals based on network filter', () async {
      // Summary is null initially
      expect(viewModel.totalFilteredBytes, equals(0));

      await viewModel.loadData();
      expect(viewModel.summary, isNotNull);

      // All networks: grandTotal
      expect(viewModel.totalFilteredBytes, equals(28800000 + 144000000));

      // Mobile
      viewModel.setNetworkType(ChannelConstants.networkTypeMobile);
      expect(viewModel.totalFilteredBytes, equals(28800000));

      // Wi-Fi
      viewModel.setNetworkType(ChannelConstants.networkTypeWifi);
      expect(viewModel.totalFilteredBytes, equals(144000000));
    });

    test('resetFilters restores default time range and network type', () async {
      await viewModel.setTimeRange(TimeRange.year);
      viewModel.setNetworkType(ChannelConstants.networkTypeMobile);
      expect(viewModel.isFiltered, isTrue);

      await viewModel.resetFilters();

      expect(viewModel.selectedRange, equals(TimeRange.today));
      expect(viewModel.selectedNetworkType, equals(ChannelConstants.networkTypeAll));
      expect(viewModel.isFiltered, isFalse);
    });
  });
}
