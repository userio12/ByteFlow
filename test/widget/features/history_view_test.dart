import 'package:byteflow/core/constants/channel_constants.dart';
import 'package:byteflow/core/errors/app_failure.dart';
import 'package:byteflow/domain/models/historical_summary_entity.dart';
import 'package:byteflow/domain/models/time_range.dart';
import 'package:byteflow/domain/models/usage_time_bucket.dart';
import 'package:byteflow/domain/use_cases/get_historical_summary_use_case.dart';
import 'package:byteflow/ui/core/widgets/empty_state_card.dart';
import 'package:byteflow/ui/features/history/view_models/history_view_model.dart';
import 'package:byteflow/ui/features/history/views/history_view.dart';
import 'package:byteflow/ui/features/history/widgets/history_filter_modal_sheet.dart';
import 'package:byteflow/ui/features/history/widgets/hourly_spike_chart.dart';
import 'package:byteflow/ui/features/history/widgets/weekly_comparison_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  group('HistoryView Widget Test', () {
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
          mobileRxBytes: hour == 14 ? 50000000 : 1000000,
          mobileTxBytes: hour == 14 ? 10000000 : 200000,
          wifiRxBytes: 5000000,
          wifiTxBytes: 1000000,
        );
      });

      fakeNetworkRepo.historicalSummary = HistoricalSummaryEntity(
        range: TimeRange.today,
        dateBounds: todayBounds,
        totalMobileBytes: 84000000,
        totalWifiBytes: 144000000,
        buckets: buckets,
        topApps: const [],
        averageDailyBytes: 228000000.0,
        peakBucket: buckets[14],
      );

      viewModel = HistoryViewModel(
        getHistoricalSummaryUseCase:
            GetHistoricalSummaryUseCase(fakeNetworkRepo),
        planRepository: fakePlanRepo,
      );
    });

    testWidgets(
        'renders AppBar filter action, summary banner, modal sheet filter, and expanded charts',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: HistoryView(viewModel: viewModel),
        ),
      );

      // Initial load & animations
      await tester.pumpAndSettle();

      // 1. App bar and Title + Filter action (Refresh icon is removed)
      expect(find.text('Usage History & Trends'), findsOneWidget);
      expect(find.byTooltip('Refresh'), findsNothing);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.byTooltip('Filter options'), findsOneWidget);

      // 2. Summary Banner (No reset button initially)
      expect(find.textContaining('Today • Total:'), findsOneWidget);
      expect(find.text('Reset Filters'), findsNothing);

      // 3. Dynamic Chart Card (Today) with expanded height
      expect(find.text('24-HOUR HOURLY TRAFFIC'), findsOneWidget);
      expect(find.byType(HourlySpikeChart), findsOneWidget);
      final hourlyChart = tester.widget<HourlySpikeChart>(find.byType(HourlySpikeChart));
      expect(hourlyChart.chartHeight, equals(340.0));

      // 4. Open Modal Filter Sheet via AppBar action
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryFilterModalSheet), findsOneWidget);
      expect(find.text('Filter History & Trends'), findsOneWidget);

      // Select Mobile Cellular in filter sheet and apply
      await tester.tap(find.text('Mobile Cellular'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(viewModel.selectedNetworkType,
          equals(ChannelConstants.networkTypeMobile));
      expect(find.text('Reset Filters'), findsOneWidget);

      // 5. Test Reset Filters banner action
      await tester.tap(find.text('Reset Filters'));
      await tester.pumpAndSettle();

      expect(viewModel.selectedNetworkType,
          equals(ChannelConstants.networkTypeAll));
      expect(find.text('Reset Filters'), findsNothing);

      // 6. Test Time Range Selection via Filter Sheet
      final weekBounds = TimeRange.week.calculateBounds();
      final now = DateTime.now();
      final weekBuckets = List.generate(7, (day) {
        return UsageTimeBucket(
          startTime: now.subtract(Duration(days: 6 - day)),
          endTime: now.subtract(Duration(days: 5 - day)),
          label: 'Day $day',
          mobileRxBytes: 10000000,
          mobileTxBytes: 2000000,
          wifiRxBytes: 50000000,
          wifiTxBytes: 10000000,
        );
      });
      fakeNetworkRepo.historicalSummary = HistoricalSummaryEntity(
        range: TimeRange.week,
        dateBounds: weekBounds,
        totalMobileBytes: 84000000,
        totalWifiBytes: 420000000,
        buckets: weekBuckets,
        topApps: const [],
        averageDailyBytes: 72000000.0,
      );

      // Tap filter action to open sheet
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Select Weekly in modal sheet and apply
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(viewModel.selectedRange, equals(TimeRange.week));
      expect(find.text('7-DAY COMPARATIVE CONSUMPTION'), findsOneWidget);
      expect(find.byType(WeeklyComparisonChart), findsOneWidget);
      final weeklyChart =
          tester.widget<WeeklyComparisonChart>(find.byType(WeeklyComparisonChart));
      expect(weeklyChart.chartHeight, equals(340.0));
      expect(find.text('Reset Filters'), findsOneWidget);

      // 7. Test Deep Filter Sheet Reset All action
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryFilterModalSheet), findsOneWidget);

      // In sheet, tap Reset All
      await tester.tap(find.text('Reset All'));
      await tester.pumpAndSettle();

      expect(viewModel.selectedRange, equals(TimeRange.today));
      expect(viewModel.selectedNetworkType, equals(ChannelConstants.networkTypeAll));
    });

    testWidgets('renders EmptyStateCard when summary telemetry is null',
        (WidgetTester tester) async {
      fakeNetworkRepo.errorToReturn =
          const PlatformFailure(code: 'ERROR', message: 'Telemetry unavailable');

      await tester.pumpWidget(
        MaterialApp(
          home: HistoryView(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateCard), findsOneWidget);
      expect(find.text('No Telemetry Recorded'), findsOneWidget);
    });
  });
}
