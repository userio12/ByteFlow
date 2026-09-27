import 'package:byteflow/core/errors/app_failure.dart';
import 'package:byteflow/core/errors/exceptions.dart';
import 'package:byteflow/data/models/app_usage_dto.dart';
import 'package:byteflow/data/models/network_summary_dto.dart';
import 'package:byteflow/data/models/sim_info_dto.dart';
import 'package:byteflow/data/models/usage_time_bucket_dto.dart';
import 'package:byteflow/data/repositories/network_repository_impl.dart';
import 'package:byteflow/data/services/cold_start_backfill_service.dart';
import 'package:byteflow/data/services/local_database_service.dart';
import 'package:byteflow/domain/models/time_range.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks/mock_native_network_service.dart';

class _FakeBackfillService implements ColdStartBackfillService {
  bool backfillCalled = false;

  @override
  Future<bool> executeIfNeeded() async {
    backfillCalled = true;
    return true;
  }
}

class _FakeLocalDatabaseService extends Fake implements LocalDatabaseService {}

class _ThrowingNativeService extends MockNativeNetworkService {
  @override
  Future<NetworkSummaryDto> getDeviceTotal({
    required int startTimeMs,
    required int endTimeMs,
  }) async {
    throw const PlatformServiceException(
      message: 'Failed to access netstats',
      code: 'PERMISSION_DENIED',
    );
  }

  @override
  Future<List<AppUsageDto>> getAppsUsage({
    int networkType = -1,
    required int startTimeMs,
    required int endTimeMs,
    bool includeIcons = true,
  }) async {
    throw const PlatformServiceException(
      message: 'App usage query failure',
      code: 'QUERY_FAILED',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNativeNetworkService mockNativeService;
  late _FakeBackfillService fakeBackfillService;
  late NetworkRepositoryImpl repository;

  setUp(() {
    mockNativeService = MockNativeNetworkService(
      simCards: const [
        SimInfoDto(
          subId: 1,
          slotIndex: 0,
          displayName: 'SIM 1',
          carrierName: 'Jio 5G',
          isDefaultData: true,
        ),
      ],
      appsUsage: const [
        AppUsageDto(
          uid: 10001,
          packageName: 'com.google.android.youtube',
          appName: 'YouTube',
          rxBytes: 5000000,
          txBytes: 1000000,
          foregroundRx: 4500000,
          foregroundTx: 900000,
          backgroundRx: 500000,
          backgroundTx: 100000,
        ),
      ],
      timeBuckets: [
        UsageTimeBucketDto(
          startTimeMs: DateTime(2026, 9, 26, 10).millisecondsSinceEpoch,
          endTimeMs: DateTime(2026, 9, 26, 11).millisecondsSinceEpoch,
          rxBytes: 1000000,
          txBytes: 200000,
        ),
      ],
    );
    fakeBackfillService = _FakeBackfillService();

    // DatabaseService dummy since today's summary queries native service
    repository = NetworkRepositoryImpl(
      nativeService: mockNativeService,
      databaseService: _FakeLocalDatabaseService(),
      backfillService: fakeBackfillService as dynamic,
    );
  });

  group('NetworkRepositoryImpl', () {
    test('getTodayUsage returns success with converted NetworkSummaryEntity', () async {
      final result = await repository.getTodayUsage();

      expect(result.isSuccess, isTrue);
      final entity = result.dataOrNull!;
      expect(entity.mobileRx, equals(104857600));
      expect(entity.mobileTx, equals(20971520));
      expect(entity.wifiRx, equals(524288000));
      expect(entity.wifiTx, equals(104857600));
      expect(entity.mobileTotal, equals(125829120));
      expect(entity.grandTotal, equals(754974720));
    });

    test('getTodayUsage handles AppException and maps to PlatformFailure', () async {
      final throwingRepo = NetworkRepositoryImpl(
        nativeService: _ThrowingNativeService(),
        databaseService: _FakeLocalDatabaseService(),
        backfillService: fakeBackfillService as dynamic,
      );

      final result = await throwingRepo.getTodayUsage();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PlatformFailure>());
      final failure = result.failureOrNull as PlatformFailure;
      expect(failure.message, contains('Failed to access netstats'));
    });

    test('getHistoricalSummary for TimeRange.today builds aggregated summary', () async {
      final result = await repository.getHistoricalSummary(range: TimeRange.today);

      expect(result.isSuccess, isTrue);
      final summary = result.dataOrNull!;
      expect(summary.range, equals(TimeRange.today));
      expect(summary.buckets.length, equals(24));
      expect(summary.topApps.length, equals(1));
      expect(summary.topApps.first.appName, equals('YouTube'));
      expect(fakeBackfillService.backfillCalled, isTrue);
    });

    test('getAppsUsage returns list of AppUsageEntity', () async {
      final result = await repository.getAppsUsage(range: TimeRange.today);

      expect(result.isSuccess, isTrue);
      final apps = result.dataOrNull!;
      expect(apps.length, equals(1));
      expect(apps.first.packageName, equals('com.google.android.youtube'));
      expect(apps.first.totalBytes, equals(6000000));
    });

    test('getAppsUsage maps AppException to PlatformFailure', () async {
      final throwingRepo = NetworkRepositoryImpl(
        nativeService: _ThrowingNativeService(),
        databaseService: _FakeLocalDatabaseService(),
        backfillService: fakeBackfillService as dynamic,
      );

      final result = await throwingRepo.getAppsUsage(range: TimeRange.today);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PlatformFailure>());
    });

    test('getHourlySpikes returns spike entities with culprit app', () async {
      final result = await repository.getHourlySpikes();

      expect(result.isSuccess, isTrue);
      final spikes = result.dataOrNull!;
      expect(spikes.length, equals(1));
      expect(spikes.first.culpritAppName, equals('YouTube'));
      expect(spikes.first.totalBytes, equals(1200000));
    });

    test('getActiveSimCards returns active carriers', () async {
      final result = await repository.getActiveSimCards();

      expect(result.isSuccess, isTrue);
      final sims = result.dataOrNull!;
      expect(sims.length, equals(1));
      expect(sims.first.carrierName, equals('Jio 5G'));
      expect(sims.first.isDefaultData, isTrue);
    });

    test('hasUsagePermission and hasPhoneStatePermission query native service', () async {
      final usageResult = await repository.hasUsagePermission();
      expect(usageResult.isSuccess, isTrue);
      expect(usageResult.dataOrNull, isTrue);

      final phoneResult = await repository.hasPhoneStatePermission();
      expect(phoneResult.isSuccess, isTrue);
      expect(phoneResult.dataOrNull, isTrue);
    });

    test('updateWidgetData dispatches to native service successfully', () async {
      final result = await repository.updateWidgetData(
        carrier: 'Jio 5G',
        simBadge: 'SIM 1',
        mobileBytes: 500000,
        wifiBytes: 1500000,
        quotaBytes: 5000000000,
        quotaText: '5.0 GB',
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
