import 'dart:convert';
import 'package:byteflow/data/database/app_database.dart';
import 'package:byteflow/data/database/database_tables.dart';
import 'package:byteflow/data/repositories/settings_repository_impl.dart';
import 'package:byteflow/data/services/local_database_service.dart';
import 'package:byteflow/data/services/local_preferences_service.dart';
import 'package:byteflow/domain/models/export_format.dart';
import 'package:byteflow/domain/use_cases/toggle_live_speed_use_case.dart';
import 'package:byteflow/ui/features/settings/view_models/settings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../mocks/mock_native_network_service.dart';
import '../../mocks/mock_repositories.dart';

class _FakeDatabase implements Database {
  final Map<String, List<Map<String, Object?>>> tables;
  _FakeDatabase(this.tables);

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return tables[table] ?? [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAppDatabase extends AppDatabase {
  final Database _db;
  _FakeAppDatabase(this._db);

  @override
  Future<Database> get database async => _db;
}

void main() {
  group('Export Usage Report in JSON Format Tests', () {
    late LocalDatabaseService databaseService;
    late _FakeDatabase fakeDb;

    setUp(() {
      fakeDb = _FakeDatabase({
        DatabaseTables.tableDailySnapshots: [
          {
            'date_string': '2026-09-30',
            'date_epoch_day': 20726,
            'network_type': 0, // Mobile
            'sub_id': 1,
            'rx_bytes': 1000,
            'tx_bytes': 500,
            'peak_hour': 14,
            'peak_bytes': 300,
          },
          {
            'date_string': '2026-09-29',
            'date_epoch_day': 20725,
            'network_type': 1, // WiFi
            'sub_id': -1,
            'rx_bytes': 4000,
            'tx_bytes': 2000,
            'peak_hour': 20,
            'peak_bytes': 1500,
          },
        ],
        DatabaseTables.tableAppSnapshots: [
          {
            'date_epoch_day': 20726,
            'uid': 10050,
            'package_name': 'com.google.android.youtube',
            'app_name': 'YouTube',
            'network_type': 0,
            'rx_bytes': 800,
            'tx_bytes': 200,
            'fg_rx_bytes': 700,
            'fg_tx_bytes': 150,
            'bg_rx_bytes': 100,
            'bg_tx_bytes': 50,
          },
        ],
        DatabaseTables.tableMonthlySnapshots: [
          {
            'year': 2026,
            'month': 9,
            'network_type': 0,
            'sub_id': 1,
            'rx_bytes': 50000,
            'tx_bytes': 10000,
          },
        ],
      });

      databaseService = LocalDatabaseService(_FakeAppDatabase(fakeDb));
    });

    test('exportUsageDataAsJson produces valid structured JSON report with summary and details', () async {
      final jsonString = await databaseService.exportUsageDataAsJson(pretty: true);
      expect(jsonString, isNotEmpty);

      // Verify parseable
      final Map<String, dynamic> parsed = jsonDecode(jsonString);
      expect(parsed['version'], equals(1));
      expect(parsed['generator'], equals('ByteFlow'));
      expect(parsed['exportedAt'], isNotNull);

      // Summary
      final summary = parsed['summary'] as Map<String, dynamic>;
      expect(summary['dailySnapshotsCount'], equals(2));
      expect(summary['appSnapshotsCount'], equals(1));
      expect(summary['monthlySnapshotsCount'], equals(1));

      // Daily network totals
      final dailyList = parsed['dailyNetworkTotals'] as List;
      expect(dailyList.length, equals(2));
      final firstDaily = dailyList[0] as Map<String, dynamic>;
      expect(firstDaily['date'], equals('2026-09-30'));
      expect(firstDaily['epochDay'], equals(20726));
      expect(firstDaily['networkType'], equals('Mobile'));
      expect(firstDaily['subId'], equals(1));
      expect(firstDaily['rxBytes'], equals(1000));
      expect(firstDaily['txBytes'], equals(500));
      expect(firstDaily['totalBytes'], equals(1500));
      expect(firstDaily['peakHour'], equals(14));
      expect(firstDaily['peakBytes'], equals(300));

      final secondDaily = dailyList[1] as Map<String, dynamic>;
      expect(secondDaily['networkType'], equals('WiFi'));

      // App usage snapshots
      final appList = parsed['appUsageSnapshots'] as List;
      expect(appList.length, equals(1));
      final appItem = appList[0] as Map<String, dynamic>;
      expect(appItem['packageName'], equals('com.google.android.youtube'));
      expect(appItem['appName'], equals('YouTube'));
      expect(appItem['networkType'], equals('Mobile'));
      expect(appItem['totalBytes'], equals(1000));
      expect(appItem['foreground']['totalBytes'], equals(850));
      expect(appItem['background']['totalBytes'], equals(150));

      // Monthly rollups
      final monthlyList = parsed['monthlyRollups'] as List;
      expect(monthlyList.length, equals(1));
      final monthItem = monthlyList[0] as Map<String, dynamic>;
      expect(monthItem['year'], equals(2026));
      expect(monthItem['month'], equals(9));
      expect(monthItem['totalBytes'], equals(60000));
    });

    test('exportUsageDataAsJson respects pretty flag', () async {
      final prettyJson = await databaseService.exportUsageDataAsJson(pretty: true);
      final compactJson = await databaseService.exportUsageDataAsJson(pretty: false);

      expect(prettyJson.contains('\n'), isTrue);
      expect(compactJson.contains('\n'), isFalse);
      final Map<String, dynamic> parsedPretty = jsonDecode(prettyJson);
      final Map<String, dynamic> parsedCompact = jsonDecode(compactJson);
      expect(parsedPretty['version'], equals(parsedCompact['version']));
      expect(parsedPretty['generator'], equals(parsedCompact['generator']));
      expect(parsedPretty['dailyNetworkTotals'], equals(parsedCompact['dailyNetworkTotals']));
      expect(parsedPretty['appUsageSnapshots'], equals(parsedCompact['appUsageSnapshots']));
    });

    test('SettingsRepositoryImpl exports JSON and CSV according to ExportFormat', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final prefService = LocalPreferencesService(prefs);
      final nativeService = MockNativeNetworkService();

      final repository = SettingsRepositoryImpl(
        preferencesService: prefService,
        nativeService: nativeService,
        databaseService: databaseService,
      );

      final jsonResult = await repository.exportUsageData(format: ExportFormat.json);
      expect(jsonResult.isSuccess, isTrue);
      final parsedJson = jsonDecode(jsonResult.dataOrNull!);
      expect(parsedJson['version'], equals(1));

      final csvResult = await repository.exportUsageData(format: ExportFormat.csv);
      expect(csvResult.isSuccess, isTrue);
      expect(csvResult.dataOrNull!.contains('--- DAILY NETWORK TOTALS ---'), isTrue);
    });

    test('SettingsViewModel delegates exportUsageData with format selection', () async {
      final fakeSettingsRepo = FakeSettingsRepository();
      final mockNative = MockNativeNetworkService();
      final viewModel = SettingsViewModel(
        settingsRepository: fakeSettingsRepo,
        toggleLiveSpeedUseCase: ToggleLiveSpeedUseCase(fakeSettingsRepo),
        nativeService: mockNative,
      );

      fakeSettingsRepo.jsonToReturn = '{"test": "json_value"}';
      fakeSettingsRepo.csvToReturn = 'date,mobile\n2026-09-30,500';

      final jsonOutput = await viewModel.exportUsageData(format: ExportFormat.json);
      expect(jsonOutput, equals('{"test": "json_value"}'));

      final csvOutput = await viewModel.exportUsageData(format: ExportFormat.csv);
      expect(csvOutput, equals('date,mobile\n2026-09-30,500'));

      final jsonDirect = await viewModel.exportUsageDataAsJson();
      expect(jsonDirect, equals('{"test": "json_value"}'));

      final csvDirect = await viewModel.exportUsageDataAsCsv();
      expect(csvDirect, equals('date,mobile\n2026-09-30,500'));
    });
  });
}
