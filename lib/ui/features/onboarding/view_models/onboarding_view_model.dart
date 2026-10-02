import 'package:flutter/foundation.dart';
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

  bool _isCompleted = false;
  bool get isCompleted => _isCompleted;

  Future<void> init() async {
    await checkPermissions();
  }

  Future<void> checkPermissions() async {
    try {
      _hasUsagePermission = await _nativeService.hasUsagePermission();
      _hasPhoneStatePermission = await _nativeService.hasPhoneStatePermission();
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

  void setPage(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    await _settingsRepository.setOnboardingCompleted(true);
    await _settingsRepository.setLiveSpeedEnabled(true);
    _isCompleted = true;
    notifyListeners();
  }
}
