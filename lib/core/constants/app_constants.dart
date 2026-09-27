/// Global application configuration constants and default thresholds.
abstract final class AppConstants {
  // Database Configuration
  static const String databaseName = 'byteflow_timeseries.db';
  static const int databaseVersion = 1;

  // Plan Quota Defaults (5.0 GB default mobile quota)
  static const int bytesPerKilobyte = 1024;
  static const int bytesPerMegabyte = 1024 * 1024;
  static const int bytesPerGigabyte = 1024 * 1024 * 1024;
  static const int defaultQuotaBytes = 5 * bytesPerGigabyte;
  static const int defaultResetDay = 1;
  static const double defaultWarningThresholdPercent = 80.0;
  static const double defaultAlertThresholdPercent = 90.0;

  // Live Speed Service Defaults
  static const int defaultLiveSpeedIntervalMs = 1000;
  static const int minLiveSpeedIntervalMs = 500;
  static const int maxLiveSpeedIntervalMs = 5000;

  // Data Retention Settings
  static const int hourlySnapshotRetentionDays = 60;

  // UI Breakpoints & Responsive Sizing
  static const double tabletBreakpointWidth = 600.0;
  static const double maxContentWidth = 800.0;
  static const double appUsageTileHeight = 76.0;

  // Animation Timings
  static const Duration countUpAnimationDuration = Duration(milliseconds: 400);
  static const Duration searchDebounceDuration = Duration(milliseconds: 150);
}
