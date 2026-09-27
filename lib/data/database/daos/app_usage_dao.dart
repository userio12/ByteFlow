import 'package:sqflite/sqflite.dart';
import '../database_tables.dart';

/// Data Access Object for daily per-app usage snapshots.
class AppUsageDao {
  final Database _db;

  const AppUsageDao(this._db);

  /// Upserts a per-app usage snapshot.
  Future<int> upsertAppSnapshot({
    required int dateEpochDay,
    required int uid,
    required String packageName,
    required String appName,
    required int networkType,
    required int rxBytes,
    required int txBytes,
    int fgRxBytes = 0,
    int fgTxBytes = 0,
    int bgRxBytes = 0,
    int bgTxBytes = 0,
  }) async {
    return _db.insert(
      DatabaseTables.tableAppSnapshots,
      {
        'date_epoch_day': dateEpochDay,
        'uid': uid,
        'package_name': packageName,
        'app_name': appName,
        'network_type': networkType,
        'rx_bytes': rxBytes,
        'tx_bytes': txBytes,
        'fg_rx_bytes': fgRxBytes,
        'fg_tx_bytes': fgTxBytes,
        'bg_rx_bytes': bgRxBytes,
        'bg_tx_bytes': bgTxBytes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch upserts app snapshots.
  Future<void> batchUpsert(List<Map<String, dynamic>> records) async {
    if (records.isEmpty) return;
    final batch = _db.batch();
    for (final record in records) {
      batch.insert(
        DatabaseTables.tableAppSnapshots,
        record,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Queries aggregated per-app usage between two date epoch days.
  Future<List<Map<String, dynamic>>> queryAggregatedAppsBetween({
    required int startEpochDay,
    required int endEpochDay,
    int networkType = -1,
  }) async {
    final whereClauses = <String>['date_epoch_day >= ? AND date_epoch_day <= ?'];
    final whereArgs = <dynamic>[startEpochDay, endEpochDay];

    if (networkType != -1) {
      whereClauses.add('network_type = ?');
      whereArgs.add(networkType);
    }

    final sql = '''
      SELECT 
        uid,
        package_name,
        app_name,
        SUM(rx_bytes) AS rx_bytes,
        SUM(tx_bytes) AS tx_bytes,
        SUM(rx_bytes + tx_bytes) AS total_bytes,
        SUM(fg_rx_bytes) AS fg_rx,
        SUM(fg_tx_bytes) AS fg_tx,
        SUM(bg_rx_bytes) AS bg_rx,
        SUM(bg_tx_bytes) AS bg_tx
      FROM ${DatabaseTables.tableAppSnapshots}
      WHERE ${whereClauses.join(' AND ')}
      GROUP BY uid, package_name, app_name
      ORDER BY total_bytes DESC;
    ''';

    return _db.rawQuery(sql, whereArgs);
  }
}
