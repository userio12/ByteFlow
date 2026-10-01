import 'package:flutter/material.dart';
import '../../../../data/services/native_network_service.dart';
import '../../../../domain/models/export_format.dart';
import '../../../../domain/repositories/i_settings_repository.dart';
import '../../../../domain/use_cases/toggle_live_speed_use_case.dart';

/// ViewModel controlling foreground LiveSpeedService notifications, intervals, and permissions.
class SettingsViewModel extends ChangeNotifier {
  final ISettingsRepository _settingsRepository;
  final ToggleLiveSpeedUseCase _toggleLiveSpeedUseCase;
  final NativeNetworkService _nativeService;

  SettingsViewModel({
    required ISettingsRepository settingsRepository,
    required ToggleLiveSpeedUseCase toggleLiveSpeedUseCase,
    required NativeNetworkService nativeService,
  })  : _settingsRepository = settingsRepository,
        _toggleLiveSpeedUseCase = toggleLiveSpeedUseCase,
        _nativeService = nativeService;

  bool _isLiveSpeedEnabled = false;
  bool get isLiveSpeedEnabled => _isLiveSpeedEnabled;

  int _samplingIntervalMs = 1000;
  int get samplingIntervalMs => _samplingIntervalMs;

  bool _isSpeedUnitBits = false;
  bool get isSpeedUnitBits => _isSpeedUnitBits;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool _hasUsagePermission = false;
  bool get hasUsagePermission => _hasUsagePermission;

  bool _hasPhoneStatePermission = false;
  bool get hasPhoneStatePermission => _hasPhoneStatePermission;

  bool _isBatteryOptimizationsIgnored = false;
  bool get isBatteryOptimizationsIgnored => _isBatteryOptimizationsIgnored;

  bool _quotaAlertsEnabled = true;
  bool get quotaAlertsEnabled => _quotaAlertsEnabled;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void init() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final speedResult = await _settingsRepository.isLiveSpeedEnabled();
      speedResult.when(
        success: (enabled) => _isLiveSpeedEnabled = enabled,
        failure: (_) {},
      );

      final intervalResult = await _settingsRepository.getLiveSpeedIntervalMs();
      intervalResult.when(
        success: (interval) => _samplingIntervalMs = interval,
        failure: (_) {},
      );

      final unitResult = await _settingsRepository.isSpeedUnitBits();
      unitResult.when(
        success: (useBits) => _isSpeedUnitBits = useBits,
        failure: (_) {},
      );

      final themeResult = await _settingsRepository.getThemeMode();
      themeResult.when(
        success: (mode) => _themeMode = mode,
        failure: (_) {},
      );

      await checkPermissions();
      await checkBatteryOptimizationStatus();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkPermissions() async {
    try {
      _hasUsagePermission = await _nativeService.hasUsagePermission();
      _hasPhoneStatePermission = await _nativeService.hasPhoneStatePermission();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> checkBatteryOptimizationStatus() async {
    try {
      final result = await _settingsRepository.isIgnoringBatteryOptimizations();
      result.when(
        success: (isIgnoring) => _isBatteryOptimizationsIgnored = isIgnoring,
        failure: (_) {},
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> requestBatteryOptimizationExemption() async {
    final result = await _settingsRepository.requestIgnoreBatteryOptimizations();
    await Future.delayed(const Duration(milliseconds: 600));
    await checkBatteryOptimizationStatus();
    return result.dataOrNull ?? false;
  }

  void setQuotaAlertsEnabled(bool enabled) {
    _quotaAlertsEnabled = enabled;
    notifyListeners();
  }

  Future<void> toggleLiveSpeed(bool enabled) async {
    _isLiveSpeedEnabled = enabled;
    notifyListeners();

    await _toggleLiveSpeedUseCase(
      enabled: enabled,
      intervalMs: _samplingIntervalMs,
    );
  }

  Future<void> setSamplingInterval(int intervalMs) async {
    _samplingIntervalMs = intervalMs;
    notifyListeners();

    await _settingsRepository.setLiveSpeedIntervalMs(intervalMs);
    if (_isLiveSpeedEnabled) {
      await _toggleLiveSpeedUseCase(enabled: true, intervalMs: intervalMs);
    }
  }

  Future<void> setSpeedUnitBits(bool useBits) async {
    _isSpeedUnitBits = useBits;
    notifyListeners();

    await _settingsRepository.setSpeedUnitBits(useBits);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    await _settingsRepository.setThemeMode(mode);
  }

  Future<void> openUsageSettings() async {
    await _nativeService.openUsageSettings();
    await Future.delayed(const Duration(milliseconds: 500));
    await checkPermissions();
  }

  /// Exports recorded network statistics into a JSON or CSV string.
  Future<String?> exportUsageData({
    ExportFormat format = ExportFormat.json,
    bool pretty = true,
  }) async {
    final result = await _settingsRepository.exportUsageData(
      format: format,
      pretty: pretty,
    );
    return result.dataOrNull;
  }

  /// Exports recorded network statistics into a JSON string.
  Future<String?> exportUsageDataAsJson({bool pretty = true}) async {
    final result = await _settingsRepository.exportUsageDataAsJson(pretty: pretty);
    return result.dataOrNull;
  }

  /// Exports recorded network statistics into a CSV string.
  Future<String?> exportUsageDataAsCsv() async {
    final result = await _settingsRepository.exportUsageDataAsCsv();
    return result.dataOrNull;
  }

  /// Clears historical snapshots and cache.
  Future<bool> clearHistoricalCache() async {
    final result = await _settingsRepository.clearHistoricalCache();
    return result.isSuccess;
  }
}
