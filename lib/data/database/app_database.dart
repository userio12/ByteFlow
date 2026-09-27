import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import 'database_tables.dart';

/// SQLite database connection lifecycle and schema manager.
class AppDatabase {
  Database? _database;
  final String? _customPath;

  AppDatabase({String? customPath}) : _customPath = customPath;

  /// Returns active [Database] instance, initializing if not yet open.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = _customPath ??
        p.join(await getDatabasesPath(), AppConstants.databaseName);

    return openDatabase(
      dbPath,
      version: AppConstants.databaseVersion,
      onConfigure: (db) async {
        // High-performance WAL mode & normal synchronous writes
        await db.execute('PRAGMA journal_mode = WAL;');
        await db.execute('PRAGMA synchronous = NORMAL;');
        await db.execute('PRAGMA temp_store = MEMORY;');
        await db.execute('PRAGMA cache_size = -4000;'); // 4MB cache
      },
      onCreate: (db, version) async {
        // 1. Hourly snapshots
        await db.execute(DatabaseTables.createTableHourlySnapshots);
        await db.execute(DatabaseTables.createIndexHourlyLookup);

        // 2. Daily rollups
        await db.execute(DatabaseTables.createTableDailySnapshots);
        await db.execute(DatabaseTables.createIndexDailyUnique);

        // 3. Monthly rollups
        await db.execute(DatabaseTables.createTableMonthlySnapshots);
        await db.execute(DatabaseTables.createIndexMonthlyUnique);

        // 4. Daily app snapshots
        await db.execute(DatabaseTables.createTableAppSnapshots);
        await db.execute(DatabaseTables.createIndexAppUnique);
        await db.execute(DatabaseTables.createIndexAppLookup);
      },
    );
  }

  /// Closes database connection.
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
