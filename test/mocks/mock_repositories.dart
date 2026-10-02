import 'dart:async';
import 'package:flutter/material.dart';
import 'package:byteflow/core/errors/app_failure.dart';
import 'package:byteflow/core/functional/result.dart';
import 'package:byteflow/domain/models/app_usage_entity.dart';
import 'package:byteflow/domain/models/data_plan_entity.dart';
import 'package:byteflow/domain/models/export_format.dart';
import 'package:byteflow/domain/models/historical_summary_entity.dart';
import 'package:byteflow/domain/models/hourly_spike_entity.dart';
import 'package:byteflow/domain/models/network_summary_entity.dart';
import 'package:byteflow/domain/models/sim_info_entity.dart';
import 'package:byteflow/domain/models/speed_sample_entity.dart';
import 'package:byteflow/domain/models/time_range.dart';
import 'package:byteflow/domain/models/usage_time_bucket.dart';
import 'package:byteflow/domain/repositories/i_network_repository.dart';
import 'package:byteflow/domain/repositories/i_plan_repository.dart';
import 'package:byteflow/domain/repositories/i_settings_repository.dart';

/// In-memory fake test double for [INetworkRepository].
class FakeNetworkRepository implements INetworkRepository {
  NetworkSummaryEntity? todaySummary;
  HistoricalSummaryEntity? historicalSummary;
  List<AppUsageEntity> appsUsage = [];
  List<HourlySpikeEntity> hourlySpikes = [];
  List<SimInfoEntity> activeSims = [];
  bool usagePermission = true;
  bool phoneStatePermission = true;
  AppFailure? errorToReturn;

  final StreamController<SpeedSampleEntity> _speedController =
      StreamController<SpeedSampleEntity>.broadcast();

  @override
  Future<Result<NetworkSummaryEntity, AppFailure>> getTodayUsage() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(
      todaySummary ??
          NetworkSummaryEntity(
            mobileRx: 104857600, // 100 MB
            mobileTx: 20971520,  // 20 MB
            wifiRx: 524288000,   // 500 MB
            wifiTx: 104857600,   // 100 MB
            startTime: DateTime.now().subtract(const Duration(hours: 12)),
            endTime: DateTime.now(),
          ),
    );
  }

  @override
  Future<Result<HistoricalSummaryEntity, AppFailure>> getHistoricalSummary({
    required TimeRange range,
    int billingResetDay = 1,
  }) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(
      historicalSummary ??
          HistoricalSummaryEntity(
            range: range,
            dateBounds: range.calculateBounds(billingCycleResetDay: billingResetDay),
            totalMobileBytes: 125829120, // 120 MB
            totalWifiBytes: 629145600,  // 600 MB
            buckets: [
              UsageTimeBucket(
                startTime: DateTime.now().subtract(const Duration(hours: 1)),
                endTime: DateTime.now(),
                label: '00:00',
                mobileRxBytes: 1024,
                mobileTxBytes: 512,
                wifiRxBytes: 2048,
                wifiTxBytes: 1024,
              ),
            ],
            topApps: appsUsage,
            averageDailyBytes: 10485760,
          ),
    );
  }

  @override
  Future<Result<List<AppUsageEntity>, AppFailure>> getAppsUsage({
    required TimeRange range,
    int networkType = -1,
    int billingResetDay = 1,
    bool includeIcons = true,
  }) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(appsUsage);
  }

  @override
  Future<Result<List<HourlySpikeEntity>, AppFailure>> getHourlySpikes() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(hourlySpikes);
  }

  @override
  Future<Result<List<SimInfoEntity>, AppFailure>> getActiveSimCards() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(activeSims);
  }

  @override
  Future<Result<bool, AppFailure>> hasUsagePermission() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(usagePermission);
  }

  @override
  Future<Result<bool, AppFailure>> openUsageSettings() async =>
      const Result.success(true);

  @override
  Future<Result<bool, AppFailure>> hasPhoneStatePermission() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(phoneStatePermission);
  }

  @override
  Future<Result<void, AppFailure>> updateWidgetData({
    required String carrier,
    required String simBadge,
    required int mobileBytes,
    required int wifiBytes,
    required int quotaBytes,
    required String quotaText,
  }) async {
    return const Result.success(null);
  }

  @override
  Stream<SpeedSampleEntity> getSpeedStream() => _speedController.stream;

  String? lastLaunchedApp;
  String? lastOpenedAppDetails;

  @override
  Future<Result<bool, AppFailure>> launchApp(String packageName) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    lastLaunchedApp = packageName;
    return const Result.success(true);
  }

  @override
  Future<Result<bool, AppFailure>> openAppDetails(String packageName) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    lastOpenedAppDetails = packageName;
    return const Result.success(true);
  }

  void emitSpeed(SpeedSampleEntity sample) {
    if (!_speedController.isClosed) {
      _speedController.add(sample);
    }
  }

  void dispose() {
    _speedController.close();
  }
}

/// In-memory fake test double for [IPlanRepository].
class FakePlanRepository implements IPlanRepository {
  DataPlanEntity plan = const DataPlanEntity();
  AppFailure? errorToReturn;

  @override
  Future<Result<DataPlanEntity, AppFailure>> getDataPlan() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(plan);
  }

  @override
  Future<Result<void, AppFailure>> saveDataPlan(DataPlanEntity newPlan) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    plan = newPlan;
    return const Result.success(null);
  }

  DataPlanEntity wifiPlan = const DataPlanEntity(
    quotaBytes: 100 * 1024 * 1024 * 1024,
  );

  @override
  Future<Result<DataPlanEntity, AppFailure>> getWifiPlan() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(wifiPlan);
  }

  @override
  Future<Result<void, AppFailure>> saveWifiPlan(DataPlanEntity newPlan) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    wifiPlan = newPlan;
    return const Result.success(null);
  }
}

/// In-memory fake test double for [ISettingsRepository].
class FakeSettingsRepository implements ISettingsRepository {
  bool liveSpeedEnabled = false;
  int liveSpeedIntervalMs = 1000;
  bool speedUnitBits = false;
  bool onboardingCompleted = false;
  String csvToReturn = '# Mock CSV Export\nDate,Mobile,WiFi\n2026-09-26,1000,2000';
  String jsonToReturn = '{\n  "version": 1,\n  "generator": "ByteFlow",\n  "dailyNetworkTotals": []\n}';
  AppFailure? errorToReturn;

  @override
  Future<Result<bool, AppFailure>> isLiveSpeedEnabled() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(liveSpeedEnabled);
  }

  @override
  Future<Result<void, AppFailure>> setLiveSpeedEnabled(
    bool enabled, {
    int intervalMs = 1000,
  }) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    liveSpeedEnabled = enabled;
    liveSpeedIntervalMs = intervalMs;
    return const Result.success(null);
  }

  @override
  Future<Result<int, AppFailure>> getLiveSpeedIntervalMs() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(liveSpeedIntervalMs);
  }

  @override
  Future<Result<void, AppFailure>> setLiveSpeedIntervalMs(int intervalMs) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    liveSpeedIntervalMs = intervalMs;
    return const Result.success(null);
  }

  @override
  Future<Result<bool, AppFailure>> isSpeedUnitBits() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(speedUnitBits);
  }

  @override
  Future<Result<void, AppFailure>> setSpeedUnitBits(bool useBits) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    speedUnitBits = useBits;
    return const Result.success(null);
  }

  bool statusBarSpeedIcon = true;

  @override
  Future<Result<bool, AppFailure>> isStatusBarSpeedIconEnabled() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(statusBarSpeedIcon);
  }

  @override
  Future<Result<void, AppFailure>> setStatusBarSpeedIconEnabled(bool enabled) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    statusBarSpeedIcon = enabled;
    return const Result.success(null);
  }

  @override
  Future<Result<bool, AppFailure>> isOnboardingCompleted() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(onboardingCompleted);
  }

  @override
  Future<Result<void, AppFailure>> setOnboardingCompleted(bool completed) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    onboardingCompleted = completed;
    return const Result.success(null);
  }

  ThemeMode themeMode = ThemeMode.system;

  @override
  Future<Result<ThemeMode, AppFailure>> getThemeMode() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(themeMode);
  }

  @override
  Future<Result<void, AppFailure>> setThemeMode(ThemeMode mode) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    themeMode = mode;
    return const Result.success(null);
  }

  @override
  Future<Result<String, AppFailure>> exportUsageDataAsCsv() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(csvToReturn);
  }

  @override
  Future<Result<String, AppFailure>> exportUsageDataAsJson({bool pretty = true}) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(jsonToReturn);
  }

  @override
  Future<Result<String, AppFailure>> exportUsageData({
    ExportFormat format = ExportFormat.json,
    bool pretty = true,
  }) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return switch (format) {
      ExportFormat.json => Result.success(jsonToReturn),
      ExportFormat.csv => Result.success(csvToReturn),
    };
  }

  @override
  Future<Result<void, AppFailure>> clearHistoricalCache() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return const Result.success(null);
  }

  bool batteryOptimizationsIgnored = false;
  String? lastNotificationTitle;
  String? lastNotificationBody;
  bool? lastNotificationIsWarning;

  @override
  Future<Result<bool, AppFailure>> isIgnoringBatteryOptimizations() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    return Result.success(batteryOptimizationsIgnored);
  }

  @override
  Future<Result<bool, AppFailure>> requestIgnoreBatteryOptimizations() async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    batteryOptimizationsIgnored = true;
    return const Result.success(true);
  }

  @override
  Future<Result<bool, AppFailure>> sendQuotaNotification({
    required String title,
    required String body,
    required bool isWarning,
  }) async {
    if (errorToReturn != null) return Result.failure(errorToReturn!);
    lastNotificationTitle = title;
    lastNotificationBody = body;
    lastNotificationIsWarning = isWarning;
    return const Result.success(true);
  }
}
