import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/domain/models/app_usage_entity.dart';
import 'package:byteflow/domain/use_cases/get_app_breakdown_use_case.dart';
import 'package:byteflow/ui/features/app_usage/view_models/app_usage_view_model.dart';
import 'package:byteflow/ui/features/app_usage/views/app_usage_view.dart';
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
      ),
      const AppUsageEntity(
        uid: 102,
        packageName: 'com.android.chrome',
        appName: 'Chrome',
        rxBytes: 20971520, // 20 MB
        txBytes: 5242880,  // 5 MB
        foregroundRx: 20000000,
        foregroundTx: 5000000,
      ),
      const AppUsageEntity(
        uid: 103,
        packageName: 'org.telegram.messenger',
        appName: 'Telegram',
        rxBytes: 10485760, // 10 MB
        txBytes: 2097152,  // 2 MB
        backgroundRx: 8000000,
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

    testWidgets('renders search filter and filters app list dynamically',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppUsageView(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Header and search bar
      expect(find.text('App Data Usage'), findsOneWidget);
      expect(find.byType(AppSearchFilterBar), findsOneWidget);

      // 2. Verify filter chips are rendered
      expect(find.text('Installed'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('All'), findsNWidgets(2)); // Network All and Apps All
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsOneWidget);

      // 3. By default (Installed filter), user apps render and system app is hidden
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Chrome'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('Android System'), findsNothing);

      // 4. Switch to System apps filter
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();

      expect(find.text('Android System'), findsOneWidget);
      expect(find.text('SYSTEM'), findsOneWidget); // System badge on tile
      expect(find.text('YouTube'), findsNothing);
      expect(find.text('Chrome'), findsNothing);
      expect(find.text('Telegram'), findsNothing);

      // 5. Switch to Apps "All" filter
      final allChips = find.text('All');
      await tester.tap(allChips.last); // Apps All chip
      await tester.pumpAndSettle();

      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Chrome'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('Android System'), findsOneWidget);

      // 6. Switch back to "Installed"
      await tester.tap(find.text('Installed'));
      await tester.pumpAndSettle();
      expect(find.text('Android System'), findsNothing);

      // 7. Enter search query for 'Chrome'
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Chrome');
      await tester.pumpAndSettle();

      // Verify filtered state: only Chrome is visible
      expect(find.text('Chrome'), findsOneWidget);
      expect(find.text('YouTube'), findsNothing);
      expect(find.text('Telegram'), findsNothing);

      // 8. Clear search query: all user apps return
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Chrome'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);

      // 9. Tap Chrome tile to open details bottom sheet
      await tester.tap(find.text('Chrome'));
      await tester.pumpAndSettle();

      // Verify bottom sheet appears with app details and app type
      expect(find.text('Foreground Rx / Tx'), findsOneWidget);
      expect(find.text('Background Rx / Tx'), findsOneWidget);
      expect(find.text('User Installed App'), findsOneWidget);
    });
  });
}
