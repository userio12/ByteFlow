import 'package:sqflite/sqflite.dart';
import '../database_tables.dart';

/// Data Access Object for daily network usage rollups.
class DailyRollupsDao {
  final Database _db;

  const DailyRollupsDao(this._db);

  /// Upserts a daily rollup record.
  Future<int> upsertDailyRollup({
    required int dateEpochDay,
    required String dateString,
    required int networkType,
    int subId = -1,
    required int rxBytes,
    required int txBytes,
    int peakHour = 0,
    int peakBytes = 0,
  }) async {
    return _db.insert(
      DatabaseTables.tableDailySnapshots,
      {
        'date_epoch_day': dateEpochDay,
        'date_string': dateString,
        'network_type': networkType,
        'sub_id': subId,
        'rx_bytes': rxBytes,
        'tx_bytes': txBytes,
        'peak_hour': peakHour,
        'peak_bytes': peakBytes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch upserts daily rollups.
  Future<void> batchUpsert(List<Map<String, dynamic>> records) async {
    if (records.isEmpty) return;
    final batch = _db.batch();
    for (final record in records) {
      batch.insert(
        DatabaseTables.tableDailySnapshots,
        record,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Queries aggregated daily stats grouped by day for Weekly (7d) or Monthly (30d) views.
  Future<List<Map<String, dynamic>>> queryDailyAggregatesBetween({
    required int startEpochDay,
    required int endEpochDay,
  }) async {
    const sql = '''
      SELECT 
        date_string,
        date_epoch_day,
        SUM(CASE WHEN network_type = 0 THEN rx_bytes + tx_bytes ELSE 0 END) AS mobile_bytes,
        SUM(CASE WHEN network_type = 1 THEN rx_bytes + tx_bytes ELSE 0 END) AS wifi_bytes,
        SUM(CASE WHEN network_type = 0 THEN rx_bytes ELSE 0 END) AS mobile_rx,
        SUM(CASE WHEN network_type = 0 THEN tx_bytes ELSE 0 END) AS mobile_tx,
        SUM(CASE WHEN network_type = 1 THEN rx_bytes ELSE 0 END) AS wifi_rx,
        SUM(CASE WHEN network_type = 1 THEN tx_bytes ELSE 0 END) AS wifi_tx
      FROM ${DatabaseTables.tableDailySnapshots}
      WHERE date_epoch_day >= ? AND date_epoch_day <= ?
      GROUP BY date_epoch_day, date_string
      ORDER BY date_epoch_day ASC;
    ''';
    return _db.rawQuery(sql, [startEpochDay, endEpochDay]);
  }

  /// Counts total number of recorded daily snapshot rows.
  Future<int> count() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseTables.tableDailySnapshots}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
