import 'package:byteflow/core/constants/channel_constants.dart';
import 'package:byteflow/domain/models/historical_summary_entity.dart';
import 'package:byteflow/domain/models/time_range.dart';
import 'package:byteflow/domain/models/usage_time_bucket.dart';
import 'package:byteflow/domain/use_cases/get_historical_summary_use_case.dart';
import 'package:byteflow/ui/core/widgets/time_range_segmented_button.dart';
import 'package:byteflow/ui/features/history/view_models/history_view_model.dart';
import 'package:byteflow/ui/features/history/views/history_view.dart';
import 'package:byteflow/ui/features/history/widgets/hourly_spike_chart.dart';
import 'package:byteflow/ui/features/history/widgets/insights_grid.dart';
import 'package:byteflow/ui/features/history/widgets/spike_culprit_card.dart';
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
        'renders time range, network filter chips, and charts without spike analysis or insights grid',
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

      // 1. App bar and Title
      expect(find.text('Usage History & Trends'), findsOneWidget);

      // 2. Segmented Button (TimeRange)
      expect(find.byType(TimeRangeSegmentedButton), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);

      // 3. Network Filter Chips
      expect(find.text('Network: '), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Mobile'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Wi-Fi'), findsOneWidget);

      // 4. Dynamic Chart Card (Today)
      expect(find.text('24-HOUR HOURLY TRAFFIC'), findsOneWidget);
      expect(find.byType(HourlySpikeChart), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HourlySpikeChart),
          matching: find.text('Cellular'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(HourlySpikeChart),
          matching: find.text('Wi-Fi'),
        ),
        findsOneWidget,
      );

      // 5. Spike Analysis and Insights Grid must NOT be present
      expect(find.byType(SpikeCulpritCard), findsNothing);
      expect(find.byType(InsightsGrid), findsNothing);
      expect(find.text('DAILY AVERAGE'), findsNothing);
      expect(find.text('CELL / WI-FI RATIO'), findsNothing);
      expect(find.text('SPIKE ANALYSIS'), findsNothing);

      // 6. Test Network Filter Switching
      final mobileChip = find.widgetWithText(ChoiceChip, 'Mobile');
      await tester.tap(mobileChip);
      await tester.pumpAndSettle();
      expect(viewModel.selectedNetworkType,
          equals(ChannelConstants.networkTypeMobile));

      final wifiChip = find.widgetWithText(ChoiceChip, 'Wi-Fi');
      await tester.tap(wifiChip);
      await tester.pumpAndSettle();
      expect(viewModel.selectedNetworkType,
          equals(ChannelConstants.networkTypeWifi));

      final allChip = find.widgetWithText(ChoiceChip, 'All');
      await tester.tap(allChip);
      await tester.pumpAndSettle();
      expect(viewModel.selectedNetworkType,
          equals(ChannelConstants.networkTypeAll));

      // 7. Switch to Weekly
      final weekBounds = TimeRange.week.calculateBounds();
      final weekBuckets = List.generate(7, (day) {
        return UsageTimeBucket(
          startTime: nowOrToday().subtract(Duration(days: 6 - day)),
          endTime: nowOrToday().subtract(Duration(days: 5 - day)),
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

      final weeklyBtn = find.text('Weekly');
      await tester.tap(weeklyBtn);
      await tester.pumpAndSettle();

      expect(find.text('7-DAY COMPARATIVE CONSUMPTION'), findsOneWidget);
      expect(find.byType(WeeklyComparisonChart), findsOneWidget);
      expect(find.byType(SpikeCulpritCard), findsNothing);
      expect(find.byType(InsightsGrid), findsNothing);
    });
  });
}

DateTime nowOrToday() => DateTime.now();
