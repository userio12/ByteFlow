import 'package:byteflow/domain/use_cases/toggle_live_speed_use_case.dart';
import 'package:byteflow/ui/features/settings/view_models/settings_view_model.dart';
import 'package:byteflow/ui/features/settings/views/settings_view.dart';
import 'package:byteflow/ui/features/settings/widgets/battery_saver_card.dart';
import 'package:byteflow/ui/features/settings/widgets/data_management_card.dart';
import 'package:byteflow/ui/features/settings/widgets/permission_health_card.dart';
import 'package:byteflow/ui/features/settings/widgets/status_bar_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_native_network_service.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  group('SettingsView Widget Test', () {
    late FakeSettingsRepository fakeSettingsRepo;
    late MockNativeNetworkService mockNativeService;
    late SettingsViewModel viewModel;

    setUp(() {
      fakeSettingsRepo = FakeSettingsRepository();
      mockNativeService = MockNativeNetworkService(
        usagePermissionGranted: true,
        phoneStatePermissionGranted: true,
      );

      viewModel = SettingsViewModel(
        settingsRepository: fakeSettingsRepo,
        toggleLiveSpeedUseCase: ToggleLiveSpeedUseCase(fakeSettingsRepo),
        nativeService: mockNativeService,
      );
    });

    testWidgets('renders all settings cards and handles export and clear cache flows',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsView(viewModel: viewModel),
        ),
      );

      await tester.pumpAndSettle();

      // 1. App bar
      expect(find.text('Settings'), findsOneWidget);

      // 2. Sections
      expect(find.byType(StatusBarSettingsTile), findsOneWidget);
      expect(find.byType(BatterySaverCard), findsOneWidget);
      expect(find.byType(PermissionHealthCard), findsOneWidget);
      expect(find.byType(DataManagementCard), findsOneWidget);

      // 3. Status bar speed toggle
      final liveSpeedSwitch = find.byType(Switch);
      expect(liveSpeedSwitch, findsOneWidget);
      await tester.tap(liveSpeedSwitch);
      await tester.pumpAndSettle();
      expect(viewModel.isLiveSpeedEnabled, isTrue);

      // 4. Test Export Usage Report dialog
      final exportTile = find.text('Export Usage Report');
      expect(exportTile, findsOneWidget);
      await tester.tap(exportTile);
      await tester.pumpAndSettle();

      expect(find.text('Export Usage Data'), findsOneWidget);
      expect(find.text('Copy CSV'), findsOneWidget);
      final closeBtn = find.text('Close');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // 5. Test Clear Cached History confirmation dialog
      final clearCacheTile = find.text('Clear Cached History');
      expect(clearCacheTile, findsOneWidget);
      await tester.tap(clearCacheTile);
      await tester.pumpAndSettle();

      expect(find.text('Clear Historical Cache?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      final cancelBtn = find.text('Cancel');
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // 6. Open Source Licenses tile
      expect(find.text('Open Source Licenses'), findsOneWidget);
    });
  });
}
