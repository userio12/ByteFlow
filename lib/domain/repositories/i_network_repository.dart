import '../../core/errors/app_failure.dart';
import '../../core/functional/result.dart';
import '../models/app_usage_entity.dart';
import '../models/historical_summary_entity.dart';
import '../models/hourly_spike_entity.dart';
import '../models/network_summary_entity.dart';
import '../models/sim_info_entity.dart';
import '../models/speed_sample_entity.dart';
import '../models/time_range.dart';

/// Contract defining all hardware network statistics, carrier inspection, and widget sync.
abstract interface class INetworkRepository {
  /// Queries cumulative mobile and Wi-Fi data consumed today.
  Future<Result<NetworkSummaryEntity, AppFailure>> getTodayUsage();

  /// Queries aggregated statistics across [range] (Today, Weekly, Monthly, Yearly).
  Future<Result<HistoricalSummaryEntity, AppFailure>> getHistoricalSummary({
    required TimeRange range,
    int billingResetDay = 1,
  });

  /// Queries per-app data usage for [range] with optional [networkType] filter.
  Future<Result<List<AppUsageEntity>, AppFailure>> getAppsUsage({
    required TimeRange range,
    int networkType = -1,
    int billingResetDay = 1,
    bool includeIcons = true,
  });

  /// Identifies peak hourly usage spikes today with culprit application.
  Future<Result<List<HourlySpikeEntity>, AppFailure>> getHourlySpikes();

  /// Queries all active hardware SIM cards and cellular subscriptions.
  Future<Result<List<SimInfoEntity>, AppFailure>> getActiveSimCards();

  /// Checks whether Android `PACKAGE_USAGE_STATS` permission is granted.
  Future<Result<bool, AppFailure>> hasUsagePermission();

  /// Launches Android System Usage Access settings screen.
  Future<Result<bool, AppFailure>> openUsageSettings();

  /// Checks whether Android `READ_PHONE_STATE` permission is granted.
  Future<Result<bool, AppFailure>> hasPhoneStatePermission();

  /// Pushes updated metrics to native Android Home Screen widget (`ByteFlowWidgetProvider`).
  Future<Result<void, AppFailure>> updateWidgetData({
    required String carrier,
    required String simBadge,
    required int mobileBytes,
    required int wifiBytes,
    required int quotaBytes,
    required String quotaText,
  });

  /// Emits real-time throughput rates from native `LiveSpeedService`.
  Stream<SpeedSampleEntity> getSpeedStream();

  /// Launches an application via Android's PackageManager by [packageName].
  Future<Result<bool, AppFailure>> launchApp(String packageName);

  /// Opens Android System Application Details Settings for [packageName].
  Future<Result<bool, AppFailure>> openAppDetails(String packageName);
}
