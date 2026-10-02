import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../data/services/native_network_service.dart';
import '../../../../domain/repositories/i_settings_repository.dart';

/// ViewModel managing state and permission checks for the guided onboarding carousel.
class OnboardingViewModel extends ChangeNotifier {
  final ISettingsRepository _settingsRepository;
  final NativeNetworkService _nativeService;

  OnboardingViewModel({
    required ISettingsRepository settingsRepository,
    required NativeNetworkService nativeService,
  })  : _settingsRepository = settingsRepository,
        _nativeService = nativeService;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool _hasUsagePermission = false;
  bool get hasUsagePermission => _hasUsagePermission;

  bool _hasPhoneStatePermission = false;
  bool get hasPhoneStatePermission => _hasPhoneStatePermission;

  bool _hasNotificationPermission = false;
  bool get hasNotificationPermission => _hasNotificationPermission;

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  Future<void> init() async {
    await checkPermissions();
  }

  Future<void> checkPermissions() async {
    try {
      _hasUsagePermission = await _nativeService.hasUsagePermission();
      _hasPhoneStatePermission = await _nativeService.hasPhoneStatePermission();
      _hasNotificationPermission = await Permission.notification.isGranted;
      notifyListeners();
    } catch (_) {
      // Platform check fallback
    }
  }

  Future<void> requestUsagePermission() async {
    try {
      await _nativeService.openUsageSettings();
      await Future.delayed(const Duration(milliseconds: 500));
      await checkPermissions();
    } catch (_) {}
  }

  /// Requests POST_NOTIFICATIONS (Android 13+) and READ_PHONE_STATE runtime permissions.
  Future<void> requestNotificationAndPhonePermissions() async {
    try {
      final statuses = await [
        Permission.notification,
        Permission.phone,
      ].request();

      _hasNotificationPermission =
          statuses[Permission.notification]?.isGranted ?? false;
      _hasPhoneStatePermission =
          statuses[Permission.phone]?.isGranted ?? false;
      notifyListeners();
    } catch (_) {
      await checkPermissions();
    }
  }

  void setPage(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    // Ensure notification permission before enabling live speed
    if (!_hasNotificationPermission) {
      final status = await Permission.notification.request();
      _hasNotificationPermission = status.isGranted;
    }

    await _settingsRepository.setOnboardingCompleted(true);
    await _settingsRepository.setLiveSpeedEnabled(true);
    _isCompleted = true;
    notifyListeners();
  }
}

