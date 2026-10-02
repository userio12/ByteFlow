import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/storage_keys.dart';
import '../models/data_plan_dto.dart';

/// Encapsulates key-value preferences persisted via SharedPreferences.
class LocalPreferencesService {
  final SharedPreferences _prefs;

  const LocalPreferencesService(this._prefs);

  /// Loads persisted data plan configuration or default values.
  DataPlanDto getDataPlan() {
    final quota = _prefs.getInt(StorageKeys.keyDataPlanQuotaBytes) ??
        AppConstants.defaultQuotaBytes;
    final cycle = _prefs.getString(StorageKeys.keyDataPlanCycleType) ?? 'monthly';
    final reset = _prefs.getInt(StorageKeys.keyDataPlanResetDay) ??
        AppConstants.defaultResetDay;
    final alert = _prefs.getDouble(StorageKeys.keyDataPlanAlertThreshold) ??
        AppConstants.defaultAlertThresholdPercent;
    final warning = _prefs.getDouble(StorageKeys.keyDataPlanWarningThreshold) ??
        AppConstants.defaultWarningThresholdPercent;

    return DataPlanDto(
      quotaBytes: quota,
      cycleType: cycle,
      resetDay: reset,
      alertThresholdPercent: alert,
      warningThresholdPercent: warning,
    );
  }

  /// Persists updated data plan configuration.
  Future<void> saveDataPlan(DataPlanDto plan) async {
    await Future.wait([
      _prefs.setInt(StorageKeys.keyDataPlanQuotaBytes, plan.quotaBytes),
      _prefs.setString(StorageKeys.keyDataPlanCycleType, plan.cycleType),
      _prefs.setInt(StorageKeys.keyDataPlanResetDay, plan.resetDay),
      _prefs.setDouble(
        StorageKeys.keyDataPlanAlertThreshold,
        plan.alertThresholdPercent,
      ),
      _prefs.setDouble(
        StorageKeys.keyDataPlanWarningThreshold,
        plan.warningThresholdPercent,
      ),
    ]);
  }

  /// Loads persisted Wi-Fi / Hotspot data plan configuration or default values.
  DataPlanDto getWifiPlan() {
    // Default 100 GB for broadband/hotspot FUP
    final quota = _prefs.getInt(StorageKeys.keyWifiPlanQuotaBytes) ??
        (100 * 1024 * 1024 * 1024);
    final cycle = _prefs.getString(StorageKeys.keyWifiPlanCycleType) ?? 'monthly';
    final reset = _prefs.getInt(StorageKeys.keyWifiPlanResetDay) ?? 1;
    final alert = _prefs.getDouble(StorageKeys.keyWifiPlanAlertThreshold) ??
        AppConstants.defaultAlertThresholdPercent;
    final warning = _prefs.getDouble(StorageKeys.keyWifiPlanWarningThreshold) ??
        AppConstants.defaultWarningThresholdPercent;

    return DataPlanDto(
      quotaBytes: quota,
      cycleType: cycle,
      resetDay: reset,
      alertThresholdPercent: alert,
      warningThresholdPercent: warning,
    );
  }

  /// Persists updated Wi-Fi / Hotspot data plan configuration.
  Future<void> saveWifiPlan(DataPlanDto plan) async {
    await Future.wait([
      _prefs.setInt(StorageKeys.keyWifiPlanQuotaBytes, plan.quotaBytes),
      _prefs.setString(StorageKeys.keyWifiPlanCycleType, plan.cycleType),
      _prefs.setInt(StorageKeys.keyWifiPlanResetDay, plan.resetDay),
      _prefs.setDouble(
        StorageKeys.keyWifiPlanAlertThreshold,
        plan.alertThresholdPercent,
      ),
      _prefs.setDouble(
        StorageKeys.keyWifiPlanWarningThreshold,
        plan.warningThresholdPercent,
      ),
    ]);
  }

  /// Returns whether live speed indicator service is enabled.
  bool getLiveSpeedEnabled() {
    return _prefs.getBool(StorageKeys.keyLiveSpeedEnabled) ?? true;
  }

  /// Sets live speed indicator toggle state.
  Future<void> setLiveSpeedEnabled(bool enabled) async {
    await _prefs.setBool(StorageKeys.keyLiveSpeedEnabled, enabled);
  }

  /// Returns live speed polling interval in milliseconds.
  int getLiveSpeedIntervalMs() {
    return _prefs.getInt(StorageKeys.keyLiveSpeedIntervalMs) ??
        AppConstants.defaultLiveSpeedIntervalMs;
  }

  /// Configures live speed polling interval in milliseconds.
  Future<void> setLiveSpeedIntervalMs(int intervalMs) async {
    await _prefs.setInt(StorageKeys.keyLiveSpeedIntervalMs, intervalMs);
  }

  /// Returns whether speed units are displayed in bits/s rather than bytes/s.
  bool getSpeedUnitBits() {
    return _prefs.getBool(StorageKeys.keySpeedUnitBits) ?? false;
  }

  /// Configures speed unit display preference.
  Future<void> setSpeedUnitBits(bool useBits) async {
    await _prefs.setBool(StorageKeys.keySpeedUnitBits, useBits);
  }

  /// Returns whether status bar icon displays dynamic numeric speed or static app logo.
  bool getStatusBarSpeedIcon() {
    return _prefs.getBool(StorageKeys.keyStatusBarSpeedIcon) ?? true;
  }

  /// Configures status bar speed icon preference.
  Future<void> setStatusBarSpeedIcon(bool enabled) async {
    await _prefs.setBool(StorageKeys.keyStatusBarSpeedIcon, enabled);
  }

  /// Returns whether the initial onboarding flow has been completed.
  bool getOnboardingCompleted() {
    return _prefs.getBool(StorageKeys.keyOnboardingCompleted) ?? false;
  }

  /// Marks initial onboarding flow as completed.
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(StorageKeys.keyOnboardingCompleted, completed);
  }

  /// Returns epoch timestamp in ms of last successful cold-start kernel backfill.
  int getLastColdStartBackfillMs() {
    return _prefs.getInt(StorageKeys.keyLastColdStartBackfillMs) ?? 0;
  }

  /// Records timestamp of last cold-start backfill.
  Future<void> setLastColdStartBackfillMs(int timestampMs) async {
    await _prefs.setInt(StorageKeys.keyLastColdStartBackfillMs, timestampMs);
  }

  /// Returns persisted theme mode identifier ('system', 'light', or 'dark').
  String getThemeMode() {
    return _prefs.getString(StorageKeys.keyThemeMode) ?? 'system';
  }

  /// Persists preferred theme mode identifier.
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(StorageKeys.keyThemeMode, mode);
  }
}
