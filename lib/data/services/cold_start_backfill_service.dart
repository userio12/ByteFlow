import 'dart:developer' as dev;
import '../../core/constants/channel_constants.dart';
import '../../core/utils/date_utils.dart';
import 'local_database_service.dart';
import 'local_preferences_service.dart';
import 'native_network_service.dart';

/// Ingests genuine historical kernel netstats into SQLite on first installation (Zero Synthetic Data).
class ColdStartBackfillService {
  final NativeNetworkService _nativeService;
  final LocalDatabaseService _databaseService;
  final LocalPreferencesService _preferencesService;

  ColdStartBackfillService({
    required NativeNetworkService nativeService,
    required LocalDatabaseService databaseService,
    required LocalPreferencesService preferencesService,
  })  : _nativeService = nativeService,
        _databaseService = databaseService,
        _preferencesService = preferencesService;

  /// Executes historical kernel ingestion if not already performed and permissions are granted.
  Future<bool> executeIfNeeded() async {
    final lastBackfill = _preferencesService.getLastColdStartBackfillMs();
    if (lastBackfill > 0) {
      return false; // Already backfilled
    }

    final hasPerm = await _nativeService.hasUsagePermission();
    if (!hasPerm) {
      return false; // Cannot query kernel without usage stats access
    }

    try {
      final now = DateTime.now();
      final dailyDao = await _databaseService.dailyRollupsDao;
      final monthlyDao = await _databaseService.monthlyRollupsDao;
      final hourlyDao = await _databaseService.networkSnapshotsDao;

      // 1. Backfill Past 30 Days into daily_network_snapshots
      final dailyRecords = <Map<String, dynamic>>[];
      for (int i = 29; i >= 0; i--) {
        final targetDate = now.subtract(Duration(days: i));
        final startOfDay = AppDateUtils.startOfDay(targetDate);
        final endOfDay = i == 0 ? now : AppDateUtils.endOfDay(targetDate);

        final startMs = startOfDay.millisecondsSinceEpoch;
        final endMs = endOfDay.millisecondsSinceEpoch;
        final epochDay = AppDateUtils.epochDay(targetDate);
        final dateStr = AppDateUtils.formatDateString(targetDate);

        final total = await _nativeService.getDeviceTotal(
          startTimeMs: startMs,
          endTimeMs: endMs,
        );

        if (total.mobileRx > 0 || total.mobileTx > 0) {
          dailyRecords.add({
            'date_epoch_day': epochDay,
            'date_string': dateStr,
            'network_type': ChannelConstants.networkTypeMobile,
            'sub_id': -1,
            'rx_bytes': total.mobileRx,
            'tx_bytes': total.mobileTx,
            'peak_hour': 0,
            'peak_bytes': 0,
          });
        }

        if (total.wifiRx > 0 || total.wifiTx > 0) {
          dailyRecords.add({
            'date_epoch_day': epochDay,
            'date_string': dateStr,
            'network_type': ChannelConstants.networkTypeWifi,
            'sub_id': -1,
            'rx_bytes': total.wifiRx,
            'tx_bytes': total.wifiTx,
            'peak_hour': 0,
            'peak_bytes': 0,
          });
        }
      }

      if (dailyRecords.isNotEmpty) {
        await dailyDao.batchUpsert(dailyRecords);
      }

      // 2. Backfill Past 12 Months into monthly_network_snapshots
      final monthlyRecords = <Map<String, dynamic>>[];
      for (int i = 11; i >= 0; i--) {
        int targetYear = now.year;
        int targetMonth = now.month - i;
        while (targetMonth <= 0) {
          targetMonth += 12;
          targetYear -= 1;
        }

        final daysInM = AppDateUtils.daysInMonth(targetYear, targetMonth);
        final monthStart = DateTime(targetYear, targetMonth, 1, 0, 0, 0);
        final monthEnd = (targetYear == now.year && targetMonth == now.month)
            ? now
            : DateTime(targetYear, targetMonth, daysInM, 23, 59, 59, 999);

        final total = await _nativeService.getDeviceTotal(
          startTimeMs: monthStart.millisecondsSinceEpoch,
          endTimeMs: monthEnd.millisecondsSinceEpoch,
        );

        if (total.mobileRx > 0 || total.mobileTx > 0) {
          monthlyRecords.add({
            'year': targetYear,
            'month': targetMonth,
            'network_type': ChannelConstants.networkTypeMobile,
            'sub_id': -1,
            'rx_bytes': total.mobileRx,
            'tx_bytes': total.mobileTx,
          });
        }

        if (total.wifiRx > 0 || total.wifiTx > 0) {
          monthlyRecords.add({
            'year': targetYear,
            'month': targetMonth,
            'network_type': ChannelConstants.networkTypeWifi,
            'sub_id': -1,
            'rx_bytes': total.wifiRx,
            'tx_bytes': total.wifiTx,
          });
        }
      }

      if (monthlyRecords.isNotEmpty) {
        await monthlyDao.batchUpsert(monthlyRecords);
      }

      // 3. Backfill Today's 24 Hours into hourly_network_snapshots
      final todayStart = AppDateUtils.startOfDay(now);
      final mobileBuckets = await _nativeService.getTimeBuckets(
        networkType: ChannelConstants.networkTypeMobile,
        startTimeMs: todayStart.millisecondsSinceEpoch,
        endTimeMs: now.millisecondsSinceEpoch,
        stepIntervalMs: 3600 * 1000,
      );

      final hourlyRecords = <Map<String, dynamic>>[];
      for (final bucket in mobileBuckets) {
        final bucketDate = DateTime.fromMillisecondsSinceEpoch(bucket.startTimeMs);
        hourlyRecords.add({
          'timestamp_ms': bucket.startTimeMs,
          'hour_of_day': bucketDate.hour,
          'network_type': ChannelConstants.networkTypeMobile,
          'sub_id': -1,
          'rx_bytes': bucket.rxBytes,
          'tx_bytes': bucket.txBytes,
        });
      }

      final wifiBuckets = await _nativeService.getTimeBuckets(
        networkType: ChannelConstants.networkTypeWifi,
        startTimeMs: todayStart.millisecondsSinceEpoch,
        endTimeMs: now.millisecondsSinceEpoch,
        stepIntervalMs: 3600 * 1000,
      );

      for (final bucket in wifiBuckets) {
        final bucketDate = DateTime.fromMillisecondsSinceEpoch(bucket.startTimeMs);
        hourlyRecords.add({
          'timestamp_ms': bucket.startTimeMs,
          'hour_of_day': bucketDate.hour,
          'network_type': ChannelConstants.networkTypeWifi,
          'sub_id': -1,
          'rx_bytes': bucket.rxBytes,
          'tx_bytes': bucket.txBytes,
        });
      }

      if (hourlyRecords.isNotEmpty) {
        await hourlyDao.batchInsert(hourlyRecords);
      }

      await _preferencesService.setLastColdStartBackfillMs(now.millisecondsSinceEpoch);
      return true;
    } catch (e, stack) {
      dev.log('ColdStartBackfillService error: $e', error: e, stackTrace: stack);
      return false;
    }
  }
}
