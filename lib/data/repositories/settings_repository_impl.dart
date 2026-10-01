import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/exceptions.dart';
import '../../core/functional/result.dart';
import '../../domain/models/export_format.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../services/local_database_service.dart';
import '../services/local_preferences_service.dart';
import '../services/native_network_service.dart';

/// Concrete repository implementing user preferences and live speed controls.
class SettingsRepositoryImpl implements ISettingsRepository {
  final LocalPreferencesService _preferencesService;
  final NativeNetworkService _nativeService;
  final LocalDatabaseService? _databaseService;

  const SettingsRepositoryImpl({
    required LocalPreferencesService preferencesService,
    required NativeNetworkService nativeService,
    LocalDatabaseService? databaseService,
  })  : _preferencesService = preferencesService,
        _nativeService = nativeService,
        _databaseService = databaseService;

  @override
  Future<Result<bool, AppFailure>> isLiveSpeedEnabled() async {
    try {
      final isRunning = await _nativeService.isLiveSpeedServiceRunning();
      final prefEnabled = _preferencesService.getLiveSpeedEnabled();
      return Result.success(isRunning || prefEnabled);
    } catch (e) {
      return Result.success(_preferencesService.getLiveSpeedEnabled());
    }
  }

  @override
  Future<Result<void, AppFailure>> setLiveSpeedEnabled(
    bool enabled, {
    int intervalMs = 1000,
  }) async {
    try {
      await _preferencesService.setLiveSpeedEnabled(enabled);
      await _preferencesService.setLiveSpeedIntervalMs(intervalMs);

      if (enabled) {
        await _nativeService.startLiveSpeedService(intervalMs: intervalMs);
      } else {
        await _nativeService.stopLiveSpeedService();
      }

      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(
        PlatformFailure(code: 'LIVE_SPEED_TOGGLE_ERROR', message: e.message),
      );
    } catch (e) {
      return Result.failure(
        PlatformFailure(code: 'UNKNOWN_ERROR', message: e.toString()),
      );
    }
  }

  @override
  Future<Result<int, AppFailure>> getLiveSpeedIntervalMs() async {
    try {
      final interval = _preferencesService.getLiveSpeedIntervalMs();
      return Result.success(interval);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to read speed interval: $e'),
      );
    }
  }

  @override
  Future<Result<void, AppFailure>> setLiveSpeedIntervalMs(int intervalMs) async {
    try {
      await _preferencesService.setLiveSpeedIntervalMs(intervalMs);
      final isEnabled = _preferencesService.getLiveSpeedEnabled();
      if (isEnabled) {
        await _nativeService.startLiveSpeedService(intervalMs: intervalMs);
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to persist speed interval: $e'),
      );
    }
  }

  @override
  Future<Result<bool, AppFailure>> isSpeedUnitBits() async {
    try {
      final useBits = _preferencesService.getSpeedUnitBits();
      return Result.success(useBits);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to read unit preference: $e'),
      );
    }
  }

  @override
  Future<Result<void, AppFailure>> setSpeedUnitBits(bool useBits) async {
    try {
      await _preferencesService.setSpeedUnitBits(useBits);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to persist unit preference: $e'),
      );
    }
  }

  @override
  Future<Result<bool, AppFailure>> isOnboardingCompleted() async {
    try {
      final completed = _preferencesService.getOnboardingCompleted();
      return Result.success(completed);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to read onboarding state: $e'),
      );
    }
  }

  @override
  Future<Result<void, AppFailure>> setOnboardingCompleted(bool completed) async {
    try {
      await _preferencesService.setOnboardingCompleted(completed);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to persist onboarding state: $e'),
      );
    }
  }

  @override
  Future<Result<ThemeMode, AppFailure>> getThemeMode() async {
    try {
      final modeStr = _preferencesService.getThemeMode();
      final mode = switch (modeStr) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      return Result.success(mode);
    } catch (e) {
      return const Result.success(ThemeMode.system);
    }
  }

  @override
  Future<Result<void, AppFailure>> setThemeMode(ThemeMode mode) async {
    try {
      final modeStr = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await _preferencesService.setThemeMode(modeStr);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to persist theme mode: $e'),
      );
    }
  }

  @override
  Future<Result<String, AppFailure>> exportUsageDataAsCsv() async {
    try {
      if (_databaseService == null) {
        return const Result.failure(
          DatabaseFailure(message: 'Database service is unavailable for export.'),
        );
      }
      final csv = await _databaseService.exportUsageDataAsCsv();
      return Result.success(csv);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to export usage CSV: $e'),
      );
    }
  }

  @override
  Future<Result<String, AppFailure>> exportUsageDataAsJson({bool pretty = true}) async {
    try {
      if (_databaseService == null) {
        return const Result.failure(
          DatabaseFailure(message: 'Database service is unavailable for export.'),
        );
      }
      final json = await _databaseService.exportUsageDataAsJson(pretty: pretty);
      return Result.success(json);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to export usage JSON: $e'),
      );
    }
  }

  @override
  Future<Result<String, AppFailure>> exportUsageData({
    ExportFormat format = ExportFormat.json,
    bool pretty = true,
  }) async {
    return switch (format) {
      ExportFormat.json => exportUsageDataAsJson(pretty: pretty),
      ExportFormat.csv => exportUsageDataAsCsv(),
    };
  }

  @override
  Future<Result<void, AppFailure>> clearHistoricalCache() async {
    try {
      if (_databaseService != null) {
        await _databaseService.clearHistoricalCache();
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        DatabaseFailure(message: 'Failed to clear historical cache: $e'),
      );
    }
  }

  @override
  Future<Result<bool, AppFailure>> isIgnoringBatteryOptimizations() async {
    try {
      final isIgnoring = await _nativeService.isIgnoringBatteryOptimizations();
      return Result.success(isIgnoring);
    } on AppException catch (e) {
      return Result.failure(
        PlatformFailure(code: 'BATTERY_CHECK_ERROR', message: e.message),
      );
    }
  }

  @override
  Future<Result<bool, AppFailure>> requestIgnoreBatteryOptimizations() async {
    try {
      final success = await _nativeService.requestIgnoreBatteryOptimizations();
      return Result.success(success);
    } on AppException catch (e) {
      return Result.failure(
        PlatformFailure(code: 'BATTERY_REQUEST_ERROR', message: e.message),
      );
    }
  }

  @override
  Future<Result<bool, AppFailure>> sendQuotaNotification({
    required String title,
    required String body,
    required bool isWarning,
  }) async {
    try {
      final success = await _nativeService.sendQuotaNotification(
        title: title,
        body: body,
        isWarning: isWarning,
      );
      return Result.success(success);
    } on AppException catch (e) {
      return Result.failure(
        PlatformFailure(code: 'NOTIFICATION_ERROR', message: e.message),
      );
    }
  }
}
