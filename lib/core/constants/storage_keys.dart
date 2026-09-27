/// Key identifiers for persistent key-value storage (SharedPreferences).
abstract final class StorageKeys {
  // Data Plan & Quota Preferences
  static const String keyDataPlanQuotaBytes = 'byteflow_plan_quota_bytes';
  static const String keyDataPlanCycleType = 'byteflow_plan_cycle_type';
  static const String keyDataPlanResetDay = 'byteflow_plan_reset_day';
  static const String keyDataPlanAlertThreshold = 'byteflow_plan_alert_threshold';
  static const String keyDataPlanWarningThreshold = 'byteflow_plan_warning_threshold';

  // Wi-Fi / Hotspot Data Plan Preferences
  static const String keyWifiPlanQuotaBytes = 'byteflow_wifi_plan_quota_bytes';
  static const String keyWifiPlanCycleType = 'byteflow_wifi_plan_cycle_type';
  static const String keyWifiPlanResetDay = 'byteflow_wifi_plan_reset_day';
  static const String keyWifiPlanAlertThreshold = 'byteflow_wifi_plan_alert_threshold';
  static const String keyWifiPlanWarningThreshold = 'byteflow_wifi_plan_warning_threshold';

  // Live Speed Service Preferences
  static const String keyLiveSpeedEnabled = 'byteflow_live_speed_enabled';
  static const String keyLiveSpeedIntervalMs = 'byteflow_live_speed_interval_ms';
  static const String keySpeedUnitBits = 'byteflow_speed_unit_bits';

  // Onboarding & Setup Flags
  static const String keyOnboardingCompleted = 'byteflow_onboarding_completed';

  // Cold Start & Synchronization Metadata
  static const String keyLastColdStartBackfillMs = 'byteflow_last_cold_start_backfill_ms';
  static const String keyLastKnownCarrier = 'byteflow_last_known_carrier';
}
