import 'package:sqflite/sqflite.dart';
import '../database_tables.dart';

/// Data Access Object for monthly network usage rollups (feeds Yearly view).
class MonthlyRollupsDao {
  final Database _db;

  const MonthlyRollupsDao(this._db);

  /// Upserts a monthly rollup record.
  Future<int> upsertMonthlyRollup({
    required int year,
    required int month,
    required int networkType,
    int subId = -1,
    required int rxBytes,
    required int txBytes,
  }) async {
    return _db.insert(
      DatabaseTables.tableMonthlySnapshots,
      {
        'year': year,
        'month': month,
        'network_type': networkType,
        'sub_id': subId,
        'rx_bytes': rxBytes,
        'tx_bytes': txBytes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch upserts monthly rollups.
  Future<void> batchUpsert(List<Map<String, dynamic>> records) async {
    if (records.isEmpty) return;
    final batch = _db.batch();
    for (final record in records) {
      batch.insert(
        DatabaseTables.tableMonthlySnapshots,
        record,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Queries aggregated monthly stats for past 12 rolling months.
  Future<List<Map<String, dynamic>>> queryPastTwelveMonths({
    required int currentYear,
    required int currentMonth,
  }) async {
    const sql = '''
      SELECT 
        year,
        month,
        SUM(CASE WHEN network_type = 0 THEN rx_bytes + tx_bytes ELSE 0 END) AS mobile_bytes,
        SUM(CASE WHEN network_type = 1 THEN rx_bytes + tx_bytes ELSE 0 END) AS wifi_bytes,
        SUM(CASE WHEN network_type = 0 THEN rx_bytes ELSE 0 END) AS mobile_rx,
        SUM(CASE WHEN network_type = 0 THEN tx_bytes ELSE 0 END) AS mobile_tx,
        SUM(CASE WHEN network_type = 1 THEN rx_bytes ELSE 0 END) AS wifi_rx,
        SUM(CASE WHEN network_type = 1 THEN tx_bytes ELSE 0 END) AS wifi_tx
      FROM ${DatabaseTables.tableMonthlySnapshots}
      WHERE (year = ?) OR (year = ? - 1 AND month > ?)
      GROUP BY year, month
      ORDER BY year ASC, month ASC;
    ''';
    return _db.rawQuery(sql, [currentYear, currentYear, currentMonth]);
  }

  /// Counts total number of recorded monthly snapshot rows.
  Future<int> count() async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseTables.tableMonthlySnapshots}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
