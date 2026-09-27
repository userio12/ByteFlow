import 'dart:async';
import '../../core/constants/channel_constants.dart';
import '../../core/errors/app_failure.dart';
import '../../core/errors/exceptions.dart';
import '../../core/functional/result.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/models/app_usage_entity.dart';
import '../../domain/models/historical_summary_entity.dart';
import '../../domain/models/hourly_spike_entity.dart';
import '../../domain/models/network_summary_entity.dart';
import '../../domain/models/sim_info_entity.dart';
import '../../domain/models/speed_sample_entity.dart';
import '../../domain/models/time_range.dart';
import '../../domain/models/usage_time_bucket.dart';
import '../../domain/repositories/i_network_repository.dart';
import '../services/cold_start_backfill_service.dart';
import '../services/local_database_service.dart';
import '../services/native_network_service.dart';

/// Concrete repository implementing single source of truth for network telemetry.
class NetworkRepositoryImpl implements INetworkRepository {
  final NativeNetworkService _nativeService;
  final LocalDatabaseService _databaseService;
  final ColdStartBackfillService _backfillService;

  NetworkRepositoryImpl({
    required NativeNetworkService nativeService,
    required LocalDatabaseService databaseService,
    required ColdStartBackfillService backfillService,
  })  : _nativeService = nativeService,
        _databaseService = databaseService,
        _backfillService = backfillService;

  @override
  Future<Result<NetworkSummaryEntity, AppFailure>> getTodayUsage() async {
    try {
      final now = DateTime.now();
      final startOfDay = AppDateUtils.startOfDay(now);

      final totalDto = await _nativeService.getDeviceTotal(
        startTimeMs: startOfDay.millisecondsSinceEpoch,
        endTimeMs: now.millisecondsSinceEpoch,
      );

      return Result.success(totalDto.toEntity());
    } on AppException catch (e) {
      return Result.failure(PlatformFailure(code: 'TODAY_USAGE_ERROR', message: e.message));
    } catch (e) {
      return Result.failure(PlatformFailure(code: 'UNKNOWN_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Result<HistoricalSummaryEntity, AppFailure>> getHistoricalSummary({
    required TimeRange range,
    int billingResetDay = 1,
  }) async {
    try {
      // Trigger lazy cold-start ingestion if needed
      await _backfillService.executeIfNeeded();

      final bounds = range.calculateBounds(billingCycleResetDay: billingResetDay);
      final startMs = bounds.start.millisecondsSinceEpoch;
      final endMs = bounds.end.millisecondsSinceEpoch;

      return switch (range) {
        TimeRange.today => _buildTodaySummary(bounds, startMs, endMs),
        TimeRange.week => _buildWeeklySummary(bounds),
        TimeRange.month => _buildMonthlySummary(bounds),
        TimeRange.year => _buildYearlySummary(bounds),
      };
    } on AppException catch (e) {
      return Result.failure(PlatformFailure(code: 'HISTORICAL_SUMMARY_ERROR', message: e.message));
    } catch (e) {
      return Result.failure(PlatformFailure(code: 'UNKNOWN_ERROR', message: e.toString()));
    }
  }

  Future<Result<HistoricalSummaryEntity, AppFailure>> _buildTodaySummary(
    DateRange bounds,
    int startMs,
    int endMs,
  ) async {
    final totalsDto = await _nativeService.getDeviceTotal(
      startTimeMs: startMs,
      endTimeMs: endMs,
    );

    final mobileBucketsDto = await _nativeService.getTimeBuckets(
      networkType: ChannelConstants.networkTypeMobile,
      startTimeMs: startMs,
      endTimeMs: endMs,
      stepIntervalMs: 3600 * 1000,
    );

    final wifiBucketsDto = await _nativeService.getTimeBuckets(
      networkType: ChannelConstants.networkTypeWifi,
      startTimeMs: startMs,
      endTimeMs: endMs,
      stepIntervalMs: 3600 * 1000,
    );

    // Merge 24 hourly buckets
    final bucketMap = <int, UsageTimeBucket>{};
    for (int hour = 0; hour < 24; hour++) {
      final hourStart = DateTime(bounds.start.year, bounds.start.month, bounds.start.day, hour);
      final hourEnd = hourStart.add(const Duration(hours: 1));
      final label = AppDateUtils.formatHourLabel(hour);
      bucketMap[hour] = UsageTimeBucket(
        startTime: hourStart,
        endTime: hourEnd,
        label: label,
      );
    }

    for (final b in mobileBucketsDto) {
      final d = DateTime.fromMillisecondsSinceEpoch(b.startTimeMs);
      final hour = d.hour;
      final existing = bucketMap[hour];
      if (existing != null) {
        bucketMap[hour] = UsageTimeBucket(
          startTime: existing.startTime,
          endTime: existing.endTime,
          label: existing.label,
          mobileRxBytes: b.rxBytes,
          mobileTxBytes: b.txBytes,
          wifiRxBytes: existing.wifiRxBytes,
          wifiTxBytes: existing.wifiTxBytes,
        );
      }
    }

    for (final b in wifiBucketsDto) {
      final d = DateTime.fromMillisecondsSinceEpoch(b.startTimeMs);
      final hour = d.hour;
      final existing = bucketMap[hour];
      if (existing != null) {
        bucketMap[hour] = UsageTimeBucket(
          startTime: existing.startTime,
          endTime: existing.endTime,
          label: existing.label,
          mobileRxBytes: existing.mobileRxBytes,
          mobileTxBytes: existing.mobileTxBytes,
          wifiRxBytes: b.rxBytes,
          wifiTxBytes: b.txBytes,
        );
      }
    }

    final buckets = bucketMap.values.toList();
    UsageTimeBucket? peakBucket;
    for (final bucket in buckets) {
      if (peakBucket == null || bucket.totalBytes > peakBucket.totalBytes) {
        peakBucket = bucket;
      }
    }

    final appsDto = await _nativeService.getAppsUsage(
      startTimeMs: startMs,
      endTimeMs: endMs,
      includeIcons: true,
    );
    final topApps = appsDto.take(5).map((d) => d.toEntity()).toList();

    final summary = HistoricalSummaryEntity(
      range: TimeRange.today,
      dateBounds: bounds,
      totalMobileBytes: totalsDto.mobileRx + totalsDto.mobileTx,
      totalWifiBytes: totalsDto.wifiRx + totalsDto.wifiTx,
      buckets: buckets,
      topApps: topApps,
      averageDailyBytes: (totalsDto.mobileRx + totalsDto.mobileTx + totalsDto.wifiRx + totalsDto.wifiTx).toDouble(),
      peakBucket: (peakBucket != null && peakBucket.totalBytes > 0) ? peakBucket : null,
    );

    return Result.success(summary);
  }

  Future<Result<HistoricalSummaryEntity, AppFailure>> _buildWeeklySummary(
    DateRange bounds,
  ) async {
    final dailyDao = await _databaseService.dailyRollupsDao;
    final startEpoch = AppDateUtils.epochDay(bounds.start);
    final endEpoch = AppDateUtils.epochDay(bounds.end);

    final rows = await dailyDao.queryDailyAggregatesBetween(
      startEpochDay: startEpoch,
      endEpochDay: endEpoch,
    );

    final bucketMap = <int, UsageTimeBucket>{};
    for (int i = 0; i < 7; i++) {
      final dayDate = bounds.start.add(Duration(days: i));
      final epoch = AppDateUtils.epochDay(dayDate);
      final label = AppDateUtils.formatDayOfWeek(dayDate);
      bucketMap[epoch] = UsageTimeBucket(
        startTime: AppDateUtils.startOfDay(dayDate),
        endTime: AppDateUtils.endOfDay(dayDate),
        label: label,
      );
    }

    int totalMobile = 0;
    int totalWifi = 0;

    for (final row in rows) {
      final epoch = (row['date_epoch_day'] as num).toInt();
      final mobRx = (row['mobile_rx'] as num?)?.toInt() ?? 0;
      final mobTx = (row['mobile_tx'] as num?)?.toInt() ?? 0;
      final wRx = (row['wifi_rx'] as num?)?.toInt() ?? 0;
      final wTx = (row['wifi_tx'] as num?)?.toInt() ?? 0;

      totalMobile += (mobRx + mobTx);
      totalWifi += (wRx + wTx);

      final existing = bucketMap[epoch];
      if (existing != null) {
        bucketMap[epoch] = UsageTimeBucket(
          startTime: existing.startTime,
          endTime: existing.endTime,
          label: existing.label,
          mobileRxBytes: mobRx,
          mobileTxBytes: mobTx,
          wifiRxBytes: wRx,
          wifiTxBytes: wTx,
        );
      }
    }

    final buckets = bucketMap.values.toList();
    UsageTimeBucket? peakBucket;
    for (final bucket in buckets) {
      if (peakBucket == null || bucket.totalBytes > peakBucket.totalBytes) {
        peakBucket = bucket;
      }
    }

    final appsDto = await _nativeService.getAppsUsage(
      startTimeMs: bounds.start.millisecondsSinceEpoch,
      endTimeMs: bounds.end.millisecondsSinceEpoch,
      includeIcons: true,
    );
    final topApps = appsDto.take(5).map((d) => d.toEntity()).toList();

    final summary = HistoricalSummaryEntity(
      range: TimeRange.week,
      dateBounds: bounds,
      totalMobileBytes: totalMobile,
      totalWifiBytes: totalWifi,
      buckets: buckets,
      topApps: topApps,
      averageDailyBytes: (totalMobile + totalWifi) / 7.0,
      peakBucket: (peakBucket != null && peakBucket.totalBytes > 0) ? peakBucket : null,
    );

    return Result.success(summary);
  }

  Future<Result<HistoricalSummaryEntity, AppFailure>> _buildMonthlySummary(
    DateRange bounds,
  ) async {
    final dailyDao = await _databaseService.dailyRollupsDao;
    final startEpoch = AppDateUtils.epochDay(bounds.start);
    final endEpoch = AppDateUtils.epochDay(bounds.end);

    final rows = await dailyDao.queryDailyAggregatesBetween(
      startEpochDay: startEpoch,
      endEpochDay: endEpoch,
    );

    final daysInCycle = bounds.duration.inDays + 1;
    final bucketMap = <int, UsageTimeBucket>{};

    for (int i = 0; i < daysInCycle; i++) {
      final dayDate = bounds.start.add(Duration(days: i));
      final epoch = AppDateUtils.epochDay(dayDate);
      bucketMap[epoch] = UsageTimeBucket(
        startTime: AppDateUtils.startOfDay(dayDate),
        endTime: AppDateUtils.endOfDay(dayDate),
        label: '${dayDate.day}',
      );
    }

    int totalMobile = 0;
    int totalWifi = 0;

    for (final row in rows) {
      final epoch = (row['date_epoch_day'] as num).toInt();
      final mobRx = (row['mobile_rx'] as num?)?.toInt() ?? 0;
      final mobTx = (row['mobile_tx'] as num?)?.toInt() ?? 0;
      final wRx = (row['wifi_rx'] as num?)?.toInt() ?? 0;
      final wTx = (row['wifi_tx'] as num?)?.toInt() ?? 0;

      totalMobile += (mobRx + mobTx);
      totalWifi += (wRx + wTx);

      final existing = bucketMap[epoch];
      if (existing != null) {
        bucketMap[epoch] = UsageTimeBucket(
          startTime: existing.startTime,
          endTime: existing.endTime,
          label: existing.label,
          mobileRxBytes: mobRx,
          mobileTxBytes: mobTx,
          wifiRxBytes: wRx,
          wifiTxBytes: wTx,
        );
      }
    }

    final buckets = bucketMap.values.toList();
    UsageTimeBucket? peakBucket;
    for (final bucket in buckets) {
      if (peakBucket == null || bucket.totalBytes > peakBucket.totalBytes) {
        peakBucket = bucket;
      }
    }

    final appsDto = await _nativeService.getAppsUsage(
      startTimeMs: bounds.start.millisecondsSinceEpoch,
      endTimeMs: bounds.end.millisecondsSinceEpoch,
      includeIcons: true,
    );
    final topApps = appsDto.take(5).map((d) => d.toEntity()).toList();

    final summary = HistoricalSummaryEntity(
      range: TimeRange.month,
      dateBounds: bounds,
      totalMobileBytes: totalMobile,
      totalWifiBytes: totalWifi,
      buckets: buckets,
      topApps: topApps,
      averageDailyBytes: daysInCycle > 0 ? (totalMobile + totalWifi) / daysInCycle : 0.0,
      peakBucket: (peakBucket != null && peakBucket.totalBytes > 0) ? peakBucket : null,
    );

    return Result.success(summary);
  }

  Future<Result<HistoricalSummaryEntity, AppFailure>> _buildYearlySummary(
    DateRange bounds,
  ) async {
    final monthlyDao = await _databaseService.monthlyRollupsDao;
    final now = DateTime.now();

    final rows = await monthlyDao.queryPastTwelveMonths(
      currentYear: now.year,
      currentMonth: now.month,
    );

    final bucketMap = <String, UsageTimeBucket>{};
    for (int i = 11; i >= 0; i--) {
      int y = now.year;
      int m = now.month - i;
      while (m <= 0) {
        m += 12;
        y -= 1;
      }
      final key = '$y-$m';
      final label = AppDateUtils.formatMonthLabel(m);
      final mStart = DateTime(y, m, 1, 0, 0, 0);
      final mEnd = DateTime(y, m, AppDateUtils.daysInMonth(y, m), 23, 59, 59, 999);

      bucketMap[key] = UsageTimeBucket(
        startTime: mStart,
        endTime: mEnd,
        label: label,
      );
    }

    int totalMobile = 0;
    int totalWifi = 0;

    for (final row in rows) {
      final y = (row['year'] as num).toInt();
      final m = (row['month'] as num).toInt();
      final key = '$y-$m';

      final mobRx = (row['mobile_rx'] as num?)?.toInt() ?? 0;
      final mobTx = (row['mobile_tx'] as num?)?.toInt() ?? 0;
      final wRx = (row['wifi_rx'] as num?)?.toInt() ?? 0;
      final wTx = (row['wifi_tx'] as num?)?.toInt() ?? 0;

      totalMobile += (mobRx + mobTx);
      totalWifi += (wRx + wTx);

      final existing = bucketMap[key];
      if (existing != null) {
        bucketMap[key] = UsageTimeBucket(
          startTime: existing.startTime,
          endTime: existing.endTime,
          label: existing.label,
          mobileRxBytes: mobRx,
          mobileTxBytes: mobTx,
          wifiRxBytes: wRx,
          wifiTxBytes: wTx,
        );
      }
    }

    final buckets = bucketMap.values.toList();
    UsageTimeBucket? peakBucket;
    for (final bucket in buckets) {
      if (peakBucket == null || bucket.totalBytes > peakBucket.totalBytes) {
        peakBucket = bucket;
      }
    }

    final appsDto = await _nativeService.getAppsUsage(
      startTimeMs: bounds.start.millisecondsSinceEpoch,
      endTimeMs: bounds.end.millisecondsSinceEpoch,
      includeIcons: true,
    );
    final topApps = appsDto.take(5).map((d) => d.toEntity()).toList();

    final summary = HistoricalSummaryEntity(
      range: TimeRange.year,
      dateBounds: bounds,
      totalMobileBytes: totalMobile,
      totalWifiBytes: totalWifi,
      buckets: buckets,
      topApps: topApps,
      averageDailyBytes: (totalMobile + totalWifi) / 365.0,
      peakBucket: (peakBucket != null && peakBucket.totalBytes > 0) ? peakBucket : null,
    );

    return Result.success(summary);
  }

  @override
  Future<Result<List<AppUsageEntity>, AppFailure>> getAppsUsage({
    required TimeRange range,
    int networkType = -1,
    int billingResetDay = 1,
    bool includeIcons = true,
  }) async {
    try {
      final bounds = range.calculateBounds(billingCycleResetDay: billingResetDay);
      final appsDto = await _nativeService.getAppsUsage(
        networkType: networkType,
        startTimeMs: bounds.start.millisecondsSinceEpoch,
        endTimeMs: bounds.end.millisecondsSinceEpoch,
        includeIcons: includeIcons,
      );

      final entities = appsDto.map((d) => d.toEntity()).toList();
      return Result.success(entities);
    } on AppException catch (e) {
      return Result.failure(PlatformFailure(code: 'APPS_USAGE_ERROR', message: e.message));
    } catch (e) {
      return Result.failure(PlatformFailure(code: 'UNKNOWN_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Result<List<HourlySpikeEntity>, AppFailure>> getHourlySpikes() async {
    try {
      final now = DateTime.now();
      final startOfDay = AppDateUtils.startOfDay(now);

      final buckets = await _nativeService.getTimeBuckets(
        networkType: ChannelConstants.networkTypeMobile,
        startTimeMs: startOfDay.millisecondsSinceEpoch,
        endTimeMs: now.millisecondsSinceEpoch,
        stepIntervalMs: 3600 * 1000,
      );

      final appsDto = await _nativeService.getAppsUsage(
        startTimeMs: startOfDay.millisecondsSinceEpoch,
        endTimeMs: now.millisecondsSinceEpoch,
        includeIcons: false,
      );

      final topApp = appsDto.isNotEmpty ? appsDto.first : null;

      final spikes = <HourlySpikeEntity>[];
      for (final bucket in buckets) {
        final d = DateTime.fromMillisecondsSinceEpoch(bucket.startTimeMs);
        spikes.add(HourlySpikeEntity(
          hourOfDay: d.hour,
          totalBytes: bucket.rxBytes + bucket.txBytes,
          culpritAppName: topApp?.appName,
          culpritPackageName: topApp?.packageName,
          culpritBytes: topApp != null ? (topApp.rxBytes + topApp.txBytes) : null,
        ));
      }

      return Result.success(spikes);
    } on AppException catch (e) {
      return Result.failure(PlatformFailure(code: 'SPIKES_ERROR', message: e.message));
    } catch (e) {
      return Result.failure(PlatformFailure(code: 'UNKNOWN_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Result<List<SimInfoEntity>, AppFailure>> getActiveSimCards() async {
    try {
      final simsDto = await _nativeService.getSimCards();
      final entities = simsDto.map((d) => d.toEntity()).toList();
      return Result.success(entities);
    } on AppException catch (e) {
      return Result.failure(PlatformFailure(code: 'SIM_QUERY_ERROR', message: e.message));
    } catch (e) {
      return Result.failure(PlatformFailure(code: 'UNKNOWN_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Result<bool, AppFailure>> hasUsagePermission() async {
    try {
      final hasPerm = await _nativeService.hasUsagePermission();
      return Result.success(hasPerm);
    } on AppException catch (e) {
      return Result.failure(PlatformFailure(code: 'PERMISSION_ERROR', message: e.message));
    }
  }

  @override
  Future<Result<bool, AppFailure>> openUsageSettings() async {
    try {
      final result = await _nativeService.openUsageSettings();
      return Result.success(result);
    } on AppException catch (e) {
      return Result.failure(PlatformFailure(code: 'PERMISSION_SETTINGS_ERROR', message: e.message));
    }
  }

  @override
  Future<Result<bool, AppFailure>> hasPhoneStatePermission() async {
    try {
      final hasPerm = await _nativeService.hasPhoneStatePermission();
      return Result.success(hasPerm);
    } on AppException catch (e) {
      return Result.failure(PlatformFailure(code: 'PHONE_STATE_ERROR', message: e.message));
    }
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
    try {
      await _nativeService.updateWidgetData(
        carrier: carrier,
        simBadge: simBadge,
        mobileBytes: mobileBytes,
        wifiBytes: wifiBytes,
        quotaBytes: quotaBytes,
        quotaText: quotaText,
      );
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(PlatformFailure(code: 'WIDGET_UPDATE_ERROR', message: e.message));
    }
  }

  @override
  Stream<SpeedSampleEntity> getSpeedStream() {
    return _nativeService.speedStream.map((dto) => dto.toEntity());
  }

  @override
  Future<Result<bool, AppFailure>> launchApp(String packageName) async {
    try {
      final success = await _nativeService.launchApp(packageName);
      return Result.success(success);
    } on AppException catch (e) {
      return Result.failure(PlatformFailure(code: 'APP_LAUNCH_ERROR', message: e.message));
    }
  }

  @override
  Future<Result<bool, AppFailure>> openAppDetails(String packageName) async {
    try {
      final success = await _nativeService.openAppDetails(packageName);
      return Result.success(success);
    } on AppException catch (e) {
      return Result.failure(PlatformFailure(code: 'APP_DETAILS_ERROR', message: e.message));
    }
  }
}
