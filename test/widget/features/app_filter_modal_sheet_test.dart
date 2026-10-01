import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/constants/channel_constants.dart';
import 'package:byteflow/domain/models/app_sort_order.dart';
import 'package:byteflow/domain/models/app_type_filter.dart';
import 'package:byteflow/domain/models/time_range.dart';
import 'package:byteflow/ui/features/app_usage/widgets/app_filter_modal_sheet.dart';

void main() {
  group('AppFilterModalSheet Widget Test', () {
    testWidgets('renders all sections and applies selections',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TimeRange selectedRange = TimeRange.today;
      int selectedNetworkType = ChannelConstants.networkTypeAll;
      AppTypeFilter selectedAppType = AppTypeFilter.userInstalled;
      AppSortOrder selectedSortOrder = AppSortOrder.totalUsageDesc;
      bool wasReset = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppFilterModalSheet.show(
                    context,
                    selectedRange: selectedRange,
                    onRangeChanged: (r) => selectedRange = r,
                    selectedNetworkType: selectedNetworkType,
                    onNetworkTypeChanged: (n) => selectedNetworkType = n,
                    selectedAppType: selectedAppType,
                    onAppTypeChanged: (t) => selectedAppType = t,
                    selectedSortOrder: selectedSortOrder,
                    onSortOrderChanged: (s) => selectedSortOrder = s,
                    onReset: () => wasReset = true,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      // Open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify sections are visible
      expect(find.text('Filter & Sort Apps'), findsOneWidget);
      expect(find.text('Time Range'), findsOneWidget);
      expect(find.text('Network Interface'), findsOneWidget);
      expect(find.text('App Category'), findsOneWidget);
      expect(find.text('Sort Order'), findsOneWidget);

      // Select Weekly, Mobile, System Services, Background Hogs
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mobile Cellular'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('System Services'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Background Hogs'));
      await tester.pumpAndSettle();

      // Tap Apply Filters
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(selectedRange, equals(TimeRange.week));
      expect(selectedNetworkType, equals(ChannelConstants.networkTypeMobile));
      expect(selectedAppType, equals(AppTypeFilter.system));
      expect(selectedSortOrder, equals(AppSortOrder.backgroundUsageDesc));
      expect(wasReset, isFalse);

      // Test Reset button in sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset All'));
      await tester.pumpAndSettle();

      expect(wasReset, isTrue);
    });
  });
}
