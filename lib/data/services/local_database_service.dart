import '../../core/constants/app_constants.dart';
import '../database/app_database.dart';
import '../database/daos/app_usage_dao.dart';
import '../database/daos/daily_rollups_dao.dart';
import '../database/daos/monthly_rollups_dao.dart';
import '../database/daos/network_snapshots_dao.dart';
import '../database/database_tables.dart';

/// Coordination service managing SQLite database initialization and DAO access.
class LocalDatabaseService {
  final AppDatabase _appDatabase;
  NetworkSnapshotsDao? _networkSnapshotsDao;
  DailyRollupsDao? _dailyRollupsDao;
  MonthlyRollupsDao? _monthlyRollupsDao;
  AppUsageDao? _appUsageDao;

  LocalDatabaseService(this._appDatabase);

  /// Initializes DAOs with the active SQLite database instance.
  Future<void> init() async {
    final db = await _appDatabase.database;
    _networkSnapshotsDao = NetworkSnapshotsDao(db);
    _dailyRollupsDao = DailyRollupsDao(db);
    _monthlyRollupsDao = MonthlyRollupsDao(db);
    _appUsageDao = AppUsageDao(db);
  }

  Future<NetworkSnapshotsDao> get networkSnapshotsDao async {
    if (_networkSnapshotsDao == null) await init();
    return _networkSnapshotsDao!;
  }

  Future<DailyRollupsDao> get dailyRollupsDao async {
    if (_dailyRollupsDao == null) await init();
    return _dailyRollupsDao!;
  }

  Future<MonthlyRollupsDao> get monthlyRollupsDao async {
    if (_monthlyRollupsDao == null) await init();
    return _monthlyRollupsDao!;
  }

  Future<AppUsageDao> get appUsageDao async {
    if (_appUsageDao == null) await init();
    return _appUsageDao!;
  }

  /// Prunes hourly snapshots older than 60 days to conserve storage.
  Future<int> runRetentionMaintenance() async {
    final dao = await networkSnapshotsDao;
    final sixtyDaysAgoMs = DateTime.now()
        .subtract(const Duration(days: AppConstants.hourlySnapshotRetentionDays))
        .millisecondsSinceEpoch;
    return dao.pruneOlderThan(sixtyDaysAgoMs);
  }

  /// Exports stored usage data into a standard CSV report for backup/audit.
  Future<String> exportUsageDataAsCsv() async {
    final db = await _appDatabase.database;
    final buffer = StringBuffer();

    buffer.writeln('# ByteFlow Data Usage Export');
    buffer.writeln('# Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    // 1. Daily summaries
    buffer.writeln('--- DAILY NETWORK TOTALS ---');
    buffer.writeln('Date,NetworkType,RxBytes,TxBytes,TotalBytes,PeakHour,PeakBytes');
    final dailyRows = await db.query(
      DatabaseTables.tableDailySnapshots,
      orderBy: 'date_epoch_day DESC',
    );
    for (final row in dailyRows) {
      final dateStr = row['date_string'] ?? '';
      final netType = (row['network_type'] as int? ?? 0) == 0 ? 'Mobile' : 'WiFi';
      final rx = row['rx_bytes'] as int? ?? 0;
      final tx = row['tx_bytes'] as int? ?? 0;
      final total = rx + tx;
      final peakHour = row['peak_hour'] as int? ?? 0;
      final peakBytes = row['peak_bytes'] as int? ?? 0;
      buffer.writeln('$dateStr,$netType,$rx,$tx,$total,$peakHour,$peakBytes');
    }

    buffer.writeln('');

    // 2. App summaries
    buffer.writeln('--- APP USAGE SNAPSHOTS ---');
    buffer.writeln('EpochDay,PackageName,AppName,NetworkType,TotalRx,TotalTx,TotalBytes,ForegroundBytes,BackgroundBytes');
    final appRows = await db.query(
      DatabaseTables.tableAppSnapshots,
      orderBy: 'date_epoch_day DESC, rx_bytes + tx_bytes DESC',
    );
    for (final row in appRows) {
      final epochDay = row['date_epoch_day'] ?? 0;
      final pkg = (row['package_name'] as String? ?? '').replaceAll(',', ' ');
      final name = (row['app_name'] as String? ?? '').replaceAll(',', ' ');
      final netType = (row['network_type'] as int? ?? 0) == 0 ? 'Mobile' : 'WiFi';
      final rx = row['rx_bytes'] as int? ?? 0;
      final tx = row['tx_bytes'] as int? ?? 0;
      final total = rx + tx;
      final fgRx = row['fg_rx_bytes'] as int? ?? 0;
      final fgTx = row['fg_tx_bytes'] as int? ?? 0;
      final bgRx = row['bg_rx_bytes'] as int? ?? 0;
      final bgTx = row['bg_tx_bytes'] as int? ?? 0;
      buffer.writeln('$epochDay,$pkg,$name,$netType,$rx,$tx,$total,${fgRx + fgTx},${bgRx + bgTx}');
    }

    return buffer.toString();
  }

  /// Clears all historical SQLite records and vacuums the database.
  Future<void> clearHistoricalCache() async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await txn.delete(DatabaseTables.tableHourlySnapshots);
      await txn.delete(DatabaseTables.tableDailySnapshots);
      await txn.delete(DatabaseTables.tableMonthlySnapshots);
      await txn.delete(DatabaseTables.tableAppSnapshots);
    });
    await db.execute('VACUUM;');
  }

  /// Closes underlying database connection.
  Future<void> close() async {
    await _appDatabase.close();
    _networkSnapshotsDao = null;
    _dailyRollupsDao = null;
    _monthlyRollupsDao = null;
    _appUsageDao = null;
  }
}
