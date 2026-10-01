import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/constants/channel_constants.dart';
import 'package:byteflow/domain/models/time_range.dart';
import 'package:byteflow/ui/features/history/widgets/history_filter_modal_sheet.dart';

void main() {
  group('HistoryFilterModalSheet Widget Test', () {
    testWidgets('renders all sections and applies selections',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TimeRange selectedRange = TimeRange.today;
      int selectedNetworkType = ChannelConstants.networkTypeAll;
      bool wasReset = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  HistoryFilterModalSheet.show(
                    context,
                    selectedRange: selectedRange,
                    onRangeChanged: (r) => selectedRange = r,
                    selectedNetworkType: selectedNetworkType,
                    onNetworkTypeChanged: (n) => selectedNetworkType = n,
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
      expect(find.text('Filter History & Trends'), findsOneWidget);
      expect(find.text('Time Range'), findsOneWidget);
      expect(find.text('Network Interface'), findsOneWidget);

      // Select Weekly, Mobile Cellular
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mobile Cellular'));
      await tester.pumpAndSettle();

      // Tap Apply Filters
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(selectedRange, equals(TimeRange.week));
      expect(selectedNetworkType, equals(ChannelConstants.networkTypeMobile));
      expect(wasReset, isFalse);

      // Test Reset All button in sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset All'));
      await tester.pumpAndSettle();

      expect(wasReset, isTrue);
    });
  });
}
