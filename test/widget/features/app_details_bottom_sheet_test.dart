import 'package:byteflow/domain/models/app_usage_entity.dart';
import 'package:byteflow/ui/features/app_usage/widgets/app_details_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  group('AppDetailsBottomSheet Widget Tests', () {
    late FakeNetworkRepository fakeNetworkRepo;

    final testApp = AppUsageEntity(
      packageName: 'com.android.chrome',
      appName: 'Google Chrome',
      uid: 10123,
      rxBytes: 90 * 1024 * 1024,
      txBytes: 15 * 1024 * 1024,
      foregroundRx: 50 * 1024 * 1024,
      foregroundTx: 10 * 1024 * 1024,
      backgroundRx: 40 * 1024 * 1024,
      backgroundTx: 5 * 1024 * 1024,
    );

    setUp(() {
      fakeNetworkRepo = FakeNetworkRepository();
    });

    testWidgets('renders telemetry metadata and dispatches deep interop intents',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDetailsBottomSheet(
              app: testApp,
              networkRepository: fakeNetworkRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. App metadata verification
      expect(find.text('Google Chrome'), findsOneWidget);
      expect(find.text('com.android.chrome'), findsOneWidget);
      expect(find.text('Linux UID: 10123'), findsOneWidget);
      expect(find.text('USAGE SPLIT'), findsOneWidget);

      // 2. High background usage alert check (background is 45MB / 105MB = ~42.8% >= 30%)
      expect(find.textContaining('Unusual background activity'), findsOneWidget);

      // 3. Test "Open App" button interaction
      final openAppButton = find.byKey(const Key('app_details_open_app_button'));
      expect(openAppButton, findsOneWidget);
      await tester.tap(openAppButton);
      await tester.pumpAndSettle();

      expect(fakeNetworkRepo.lastLaunchedApp, equals('com.android.chrome'));

      // 4. Test "App Info" button interaction
      final appInfoButton = find.byKey(const Key('app_details_app_info_button'));
      expect(appInfoButton, findsOneWidget);
      await tester.tap(appInfoButton);
      await tester.pumpAndSettle();

      expect(fakeNetworkRepo.lastOpenedAppDetails, equals('com.android.chrome'));
    });
  });
}
