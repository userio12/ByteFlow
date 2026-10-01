import 'package:byteflow/domain/use_cases/toggle_live_speed_use_case.dart';
import 'package:byteflow/ui/features/settings/view_models/settings_view_model.dart';
import 'package:byteflow/ui/features/settings/views/about_settings_view.dart';
import 'package:byteflow/ui/features/settings/views/appearance_settings_view.dart';
import 'package:byteflow/ui/features/settings/views/data_privacy_settings_view.dart';
import 'package:byteflow/ui/features/settings/views/live_speed_settings_view.dart';
import 'package:byteflow/ui/features/settings/views/settings_view.dart';
import 'package:byteflow/ui/features/settings/views/system_health_settings_view.dart';
import 'package:byteflow/ui/features/settings/widgets/battery_saver_card.dart';
import 'package:byteflow/ui/features/settings/widgets/data_management_card.dart';
import 'package:byteflow/ui/features/settings/widgets/permission_health_card.dart';
import 'package:byteflow/ui/features/settings/widgets/status_bar_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_native_network_service.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  group('SettingsView Hub & Sub-Screens Widget Test', () {
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

    testWidgets('renders all 5 settings sub-screen hub tiles and navigates seamlessly',
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

      // 1. App bar & Hub Headers
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('NETWORK & SYSTEM'), findsOneWidget);
      expect(find.text('PREFERENCES & DATA'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);

      // Verify the 5 Hub Navigation Tiles exist
      expect(find.text('Live Speed & Monitoring'), findsOneWidget);
      expect(find.text('Battery & System Health'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Data & Storage Management'), findsOneWidget);
      expect(find.text('About ByteFlow'), findsOneWidget);

      // --- SUB-SCREEN 1: Live Speed & Monitoring ---
      await tester.tap(find.text('Live Speed & Monitoring'));
      await tester.pumpAndSettle();

      expect(find.byType(LiveSpeedSettingsView), findsOneWidget);
      expect(find.byType(StatusBarSettingsTile), findsOneWidget);

      // Toggle live speed switch
      final liveSpeedSwitch = find.byType(Switch);
      expect(liveSpeedSwitch, findsOneWidget);
      await tester.tap(liveSpeedSwitch);
      await tester.pumpAndSettle();
      expect(viewModel.isLiveSpeedEnabled, isTrue);

      // Pop back to Hub
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsView), findsOneWidget);

      // --- SUB-SCREEN 2: Battery & System Health ---
      await tester.tap(find.text('Battery & System Health'));
      await tester.pumpAndSettle();

      expect(find.byType(SystemHealthSettingsView), findsOneWidget);
      expect(find.byType(BatterySaverCard), findsOneWidget);
      expect(find.byType(PermissionHealthCard), findsOneWidget);

      // Pop back to Hub
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsView), findsOneWidget);

      // --- SUB-SCREEN 3: Appearance ---
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();

      expect(find.byType(AppearanceSettingsView), findsOneWidget);
      expect(find.text('Dark Mode (OLED)'), findsOneWidget);

      // Select Dark Mode
      await tester.tap(find.text('Dark Mode (OLED)'));
      await tester.pumpAndSettle();
      expect(viewModel.themeMode, ThemeMode.dark);

      // Pop back to Hub
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsView), findsOneWidget);

      // --- SUB-SCREEN 4: Data & Storage Management ---
      await tester.tap(find.text('Data & Storage Management'));
      await tester.pumpAndSettle();

      expect(find.byType(DataPrivacySettingsView), findsOneWidget);
      expect(find.byType(DataManagementCard), findsOneWidget);

      // Test Export Usage Report dialog with JSON default and CSV toggle
      final exportTile = find.text('Export Usage Report');
      expect(exportTile, findsOneWidget);
      await tester.tap(exportTile);
      await tester.pumpAndSettle();

      expect(find.text('Export Usage Data'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('Copy JSON'), findsOneWidget);

      // Switch to CSV format
      await tester.tap(find.text('CSV'));
      await tester.pumpAndSettle();
      expect(find.text('Copy CSV'), findsOneWidget);

      // Switch back to JSON format
      await tester.tap(find.text('JSON'));
      await tester.pumpAndSettle();
      expect(find.text('Copy JSON'), findsOneWidget);

      final closeBtn = find.text('Close');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Test Clear Cached History confirmation dialog
      final clearCacheTile = find.text('Clear Cached History');
      expect(clearCacheTile, findsOneWidget);
      await tester.tap(clearCacheTile);
      await tester.pumpAndSettle();

      expect(find.text('Clear Historical Cache?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      final cancelBtn = find.text('Cancel');
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Pop back to Hub
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsView), findsOneWidget);

      // --- SUB-SCREEN 5: About ByteFlow ---
      await tester.tap(find.text('About ByteFlow'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutSettingsView), findsOneWidget);
      expect(find.text('Version 1.0.0 (Production Build)'), findsOneWidget);
      expect(find.text('Open Source Licenses'), findsOneWidget);

      // Pop back to Hub
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsView), findsOneWidget);
    });
  });
}
