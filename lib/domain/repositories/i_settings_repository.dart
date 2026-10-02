import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';
import '../../core/functional/result.dart';
import '../models/export_format.dart';

/// Contract defining user preferences and live status bar service configuration.
abstract interface class ISettingsRepository {
  /// Checks whether live speed notification service is enabled.
  Future<Result<bool, AppFailure>> isLiveSpeedEnabled();

  /// Enables or disables the ongoing foreground live speed service.
  Future<Result<void, AppFailure>> setLiveSpeedEnabled(
    bool enabled, {
    int intervalMs = 1000,
  });

  /// Queries current sampling interval in milliseconds (default 1000ms).
  Future<Result<int, AppFailure>> getLiveSpeedIntervalMs();

  /// Configures sampling interval in milliseconds.
  Future<Result<void, AppFailure>> setLiveSpeedIntervalMs(int intervalMs);

  /// Checks whether throughput is displayed in bits/s rather than bytes/s.
  Future<Result<bool, AppFailure>> isSpeedUnitBits();

  /// Configures unit preference (bits/s vs bytes/s).
  Future<Result<void, AppFailure>> setSpeedUnitBits(bool useBits);

  /// Checks whether status bar speed icon is enabled.
  Future<Result<bool, AppFailure>> isStatusBarSpeedIconEnabled();

  /// Configures status bar speed icon preference.
  Future<Result<void, AppFailure>> setStatusBarSpeedIconEnabled(bool enabled);

  /// Checks whether the user has completed the onboarding flow.
  Future<Result<bool, AppFailure>> isOnboardingCompleted();

  /// Marks the onboarding flow as completed.
  Future<Result<void, AppFailure>> setOnboardingCompleted(bool completed);

  /// Queries the persisted theme mode.
  Future<Result<ThemeMode, AppFailure>> getThemeMode();

  /// Configures and persists the theme mode.
  Future<Result<void, AppFailure>> setThemeMode(ThemeMode mode);

  /// Exports stored usage data into a CSV string for user audit/backup.
  Future<Result<String, AppFailure>> exportUsageDataAsCsv();

  /// Exports stored usage data into a JSON string for user audit/backup.
  Future<Result<String, AppFailure>> exportUsageDataAsJson({bool pretty = true});

  /// Exports stored usage data in the requested [ExportFormat].
  Future<Result<String, AppFailure>> exportUsageData({
    ExportFormat format = ExportFormat.json,
    bool pretty = true,
  });

  /// Clears stored time-series data and vacuums database.
  Future<Result<void, AppFailure>> clearHistoricalCache();

  /// Checks whether ByteFlow is whitelisted / ignoring battery optimizations.
  Future<Result<bool, AppFailure>> isIgnoringBatteryOptimizations();

  /// Prompts user to exempt ByteFlow from Android battery optimizations.
  Future<Result<bool, AppFailure>> requestIgnoreBatteryOptimizations();

  /// Dispatches a high-priority system notification for data plan warning or exhaustion alerts.
  Future<Result<bool, AppFailure>> sendQuotaNotification({
    required String title,
    required String body,
    required bool isWarning,
  });
}
