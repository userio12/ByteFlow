import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/theme/app_icons.dart';
import 'package:byteflow/domain/models/app_usage_entity.dart';
import 'package:byteflow/domain/use_cases/get_app_breakdown_use_case.dart';
import 'package:byteflow/ui/features/app_usage/view_models/app_usage_view_model.dart';
import 'package:byteflow/ui/features/app_usage/views/app_usage_view.dart';
import 'package:byteflow/ui/features/app_usage/widgets/app_details_bottom_sheet.dart';
import 'package:byteflow/ui/features/app_usage/widgets/app_filter_modal_sheet.dart';
import 'package:byteflow/ui/features/app_usage/widgets/app_search_filter_bar.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  group('AppUsageView Widget Test', () {
    late FakeNetworkRepository fakeNetworkRepo;
    late AppUsageViewModel viewModel;

    final mockApps = [
      const AppUsageEntity(
        uid: 101,
        packageName: 'com.google.android.youtube',
        appName: 'YouTube',
        rxBytes: 52428800, // 50 MB
        txBytes: 10485760, // 10 MB
        foregroundRx: 50000000,
        foregroundTx: 10000000,
        backgroundRx: 2428800,
        backgroundTx: 485760,
      ),
      const AppUsageEntity(
        uid: 102,
        packageName: 'com.android.chrome',
        appName: 'Chrome',
        rxBytes: 20971520, // 20 MB
        txBytes: 5242880,  // 5 MB
        foregroundRx: 20000000,
        foregroundTx: 5000000,
        backgroundRx: 971520,
        backgroundTx: 242880,
      ),
      const AppUsageEntity(
        uid: 103,
        packageName: 'org.telegram.messenger',
        appName: 'Telegram',
        rxBytes: 10485760, // 10 MB
        txBytes: 2097152,  // 2 MB
        foregroundRx: 2485760,
        foregroundTx: 1097152,
        backgroundRx: 8000000, // Highest background!
        backgroundTx: 1000000,
      ),
      const AppUsageEntity(
        uid: 1000,
        packageName: 'android.uid.system',
        appName: 'Android System',
        rxBytes: 5242880,  // 5 MB
        txBytes: 1048576,  // 1 MB
        isSystemApp: true,
      ),
    ];

    setUp(() {
      fakeNetworkRepo = FakeNetworkRepository();
      fakeNetworkRepo.appsUsage = mockApps;
      viewModel = AppUsageViewModel(
        getAppBreakdownUseCase: GetAppBreakdownUseCase(fakeNetworkRepo),
      );
    });

    testWidgets('renders search filter bar without refresh icon or dropdowns, and filters apps via bottom sheet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AppUsageView(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Header and search bar
      expect(find.text('App Data Usage'), findsOneWidget);
      expect(find.byType(AppSearchFilterBar), findsOneWidget);

      // 2. Verify Refresh icon in AppBar is removed
      expect(find.byIcon(AppIcons.refresh), findsNothing);

      // 3. Verify on-screen dropdown pill menus are removed
      expect(find.text('Today'), findsNothing);
      expect(find.text('All Networks'), findsNothing);
      expect(find.text('User Apps'), findsNothing);
      expect(find.text('Highest Usage'), findsNothing);

      // 4. By default (User Apps filter), user apps render and system app is hidden
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Chrome'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('Android System'), findsNothing);

      // 5. Verify filter icon is located in the AppBar top right corner, not in search bar
      final filterBtn = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.tune_rounded),
      );
      expect(filterBtn, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppSearchFilterBar),
          matching: find.byIcon(Icons.tune_rounded),
        ),
        findsNothing,
      );

      // Open Filter Modal Sheet via tune icon
      await tester.tap(filterBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AppFilterModalSheet), findsOneWidget);
      expect(find.text('Filter & Sort Apps'), findsOneWidget);

      // Switch to System Services
      await tester.tap(find.text('System Services'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Android System'), findsOneWidget);
      expect(find.text('SYSTEM'), findsOneWidget); // System badge on tile
      expect(find.text('YouTube'), findsNothing);
      expect(find.text('Chrome'), findsNothing);
      expect(find.text('Telegram'), findsNothing);

      // 6. Open filter sheet again and switch to "All Apps"
      await tester.tap(filterBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('All Apps'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Chrome'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('Android System'), findsOneWidget);

      // 7. Open filter sheet and switch back to "User Apps" + "Background Hogs"
      await tester.tap(filterBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('User Apps'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Background Hogs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Android System'), findsNothing);
      // Telegram has 9MB background bytes vs YouTube ~3MB, Chrome ~1.2MB
      // Verify Telegram is ordered first in the list
      expect(viewModel.filteredApps.first.appName, equals('Telegram'));

      // 8. Enter search query for 'Chrome'
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Chrome');
      await tester.pumpAndSettle();

      // Verify filtered state: only Chrome is visible
      expect(find.text('Chrome'), findsOneWidget);
      expect(find.text('YouTube'), findsNothing);
      expect(find.text('Telegram'), findsNothing);

      // 9. Clear search query: all user apps return
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Chrome'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);

      // 10. Tap Chrome tile to open details bottom sheet
      await tester.tap(find.text('Chrome'));
      await tester.pumpAndSettle();

      // Verify bottom sheet appears with app details
      expect(find.text('Foreground Rx / Tx'), findsOneWidget);
      expect(find.text('Background Rx / Tx'), findsOneWidget);
      expect(find.text('User Installed App'), findsOneWidget);

      // Close bottom sheet
      Navigator.of(tester.element(find.byType(AppDetailsBottomSheet))).pop();
      await tester.pumpAndSettle();

      // 11. Test Reset Filters banner action
      expect(find.text('Reset Filters'), findsOneWidget);
      await tester.tap(find.text('Reset Filters'));
      await tester.pumpAndSettle();
      expect(viewModel.isFiltered, isFalse);
    });
  });
}
