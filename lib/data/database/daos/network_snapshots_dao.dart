import 'package:sqflite/sqflite.dart';
import '../database_tables.dart';

/// Data Access Object for hourly network snapshots.
class NetworkSnapshotsDao {
  final Database _db;

  const NetworkSnapshotsDao(this._db);

  /// Inserts a single hourly snapshot record.
  Future<int> insertSnapshot({
    required int timestampMs,
    required int hourOfDay,
    required int networkType,
    int subId = -1,
    required int rxBytes,
    required int txBytes,
  }) async {
    return _db.insert(
      DatabaseTables.tableHourlySnapshots,
      {
        'timestamp_ms': timestampMs,
        'hour_of_day': hourOfDay,
        'network_type': networkType,
        'sub_id': subId,
        'rx_bytes': rxBytes,
        'tx_bytes': txBytes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch inserts hourly snapshots inside a single transaction.
  Future<void> batchInsert(List<Map<String, dynamic>> records) async {
    if (records.isEmpty) return;
    final batch = _db.batch();
    for (final record in records) {
      batch.insert(
        DatabaseTables.tableHourlySnapshots,
        record,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Queries all hourly snapshots for a given timestamp range.
  Future<List<Map<String, dynamic>>> querySnapshotsBetween({
    required int startMs,
    required int endMs,
  }) async {
    return _db.query(
      DatabaseTables.tableHourlySnapshots,
      where: 'timestamp_ms >= ? AND timestamp_ms <= ?',
      whereArgs: [startMs, endMs],
      orderBy: 'hour_of_day ASC, network_type ASC',
    );
  }

  /// Prunes hourly snapshots older than [retentionTimestampMs].
  Future<int> pruneOlderThan(int retentionTimestampMs) async {
    return _db.delete(
      DatabaseTables.tableHourlySnapshots,
      where: 'timestamp_ms < ?',
      whereArgs: [retentionTimestampMs],
    );
  }
}
