/// SQL Data Definition Language (DDL) statements and table definitions.
abstract final class DatabaseTables {
  // Table Names
  static const String tableHourlySnapshots = 'hourly_network_snapshots';
  static const String tableDailySnapshots = 'daily_network_snapshots';
  static const String tableMonthlySnapshots = 'monthly_network_snapshots';
  static const String tableAppSnapshots = 'daily_app_snapshots';

  /// DDL statement for hourly network snapshots table (retained 60 days).
  static const String createTableHourlySnapshots = '''
    CREATE TABLE IF NOT EXISTS $tableHourlySnapshots (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp_ms INTEGER NOT NULL,
      hour_of_day INTEGER NOT NULL,
      network_type INTEGER NOT NULL,
      sub_id INTEGER DEFAULT -1,
      rx_bytes INTEGER NOT NULL,
      tx_bytes INTEGER NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  ''';

  static const String createIndexHourlyLookup = '''
    CREATE INDEX IF NOT EXISTS idx_hourly_lookup 
    ON $tableHourlySnapshots(timestamp_ms, network_type);
  ''';

  /// DDL statement for daily rollups table.
  static const String createTableDailySnapshots = '''
    CREATE TABLE IF NOT EXISTS $tableDailySnapshots (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date_epoch_day INTEGER NOT NULL,
      date_string TEXT NOT NULL,
      network_type INTEGER NOT NULL,
      sub_id INTEGER DEFAULT -1,
      rx_bytes INTEGER NOT NULL,
      tx_bytes INTEGER NOT NULL,
      peak_hour INTEGER NOT NULL,
      peak_bytes INTEGER NOT NULL
    );
  ''';

  static const String createIndexDailyUnique = '''
    CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_unique 
    ON $tableDailySnapshots(date_epoch_day, network_type, sub_id);
  ''';

  /// DDL statement for monthly rollups table.
  static const String createTableMonthlySnapshots = '''
    CREATE TABLE IF NOT EXISTS $tableMonthlySnapshots (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      year INTEGER NOT NULL,
      month INTEGER NOT NULL,
      network_type INTEGER NOT NULL,
      sub_id INTEGER DEFAULT -1,
      rx_bytes INTEGER NOT NULL,
      tx_bytes INTEGER NOT NULL
    );
  ''';

  static const String createIndexMonthlyUnique = '''
    CREATE UNIQUE INDEX IF NOT EXISTS idx_monthly_unique 
    ON $tableMonthlySnapshots(year, month, network_type, sub_id);
  ''';

  /// DDL statement for daily per-app usage snapshots table.
  static const String createTableAppSnapshots = '''
    CREATE TABLE IF NOT EXISTS $tableAppSnapshots (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date_epoch_day INTEGER NOT NULL,
      uid INTEGER NOT NULL,
      package_name TEXT NOT NULL,
      app_name TEXT NOT NULL,
      network_type INTEGER NOT NULL,
      rx_bytes INTEGER NOT NULL,
      tx_bytes INTEGER NOT NULL,
      fg_rx_bytes INTEGER NOT NULL,
      fg_tx_bytes INTEGER NOT NULL,
      bg_rx_bytes INTEGER NOT NULL,
      bg_tx_bytes INTEGER NOT NULL
    );
  ''';

  static const String createIndexAppUnique = '''
    CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_app_unique 
    ON $tableAppSnapshots(date_epoch_day, uid, network_type);
  ''';

  static const String createIndexAppLookup = '''
    CREATE INDEX IF NOT EXISTS idx_app_lookup 
    ON $tableAppSnapshots(date_epoch_day, network_type);
  ''';
}
