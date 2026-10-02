import 'package:byteflow/domain/use_cases/toggle_live_speed_use_case.dart';
import 'package:byteflow/ui/features/settings/view_models/settings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_native_network_service.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  group('SettingsViewModel Unit Tests', () {
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

    test('loadSettings initializes all live speed and notification properties', () async {
      fakeSettingsRepo.liveSpeedEnabled = true;
      fakeSettingsRepo.liveSpeedIntervalMs = 2000;
      fakeSettingsRepo.speedUnitBits = true;
      fakeSettingsRepo.statusBarSpeedIcon = false;

      await viewModel.loadSettings();

      expect(viewModel.isLiveSpeedEnabled, isTrue);
      expect(viewModel.samplingIntervalMs, equals(2000));
      expect(viewModel.isSpeedUnitBits, isTrue);
      expect(viewModel.isStatusBarSpeedIcon, isFalse);
    });

    test('setStatusBarSpeedIcon updates state, persists, and refreshes notification when service is running', () async {
      await viewModel.loadSettings();
      await viewModel.toggleLiveSpeed(true);

      expect(mockNativeService.refreshNotificationCalled, isFalse);

      await viewModel.setStatusBarSpeedIcon(false);

      expect(viewModel.isStatusBarSpeedIcon, isFalse);
      expect(fakeSettingsRepo.statusBarSpeedIcon, isFalse);
      expect(mockNativeService.refreshNotificationCalled, isTrue);
    });

    test('setSpeedUnitBits updates state, persists, and refreshes notification when service is running', () async {
      await viewModel.loadSettings();
      await viewModel.toggleLiveSpeed(true);

      mockNativeService.refreshNotificationCalled = false;

      await viewModel.setSpeedUnitBits(true);

      expect(viewModel.isSpeedUnitBits, isTrue);
      expect(fakeSettingsRepo.speedUnitBits, isTrue);
      expect(mockNativeService.refreshNotificationCalled, isTrue);
    });
  });
}
