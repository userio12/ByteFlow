import 'package:byteflow/data/repositories/network_repository_impl.dart';
import 'package:byteflow/data/repositories/settings_repository_impl.dart';
import 'package:byteflow/data/services/local_preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:byteflow/data/services/cold_start_backfill_service.dart';
import 'package:byteflow/data/services/local_database_service.dart';
import '../../mocks/mock_native_network_service.dart';

class _FakeLocalDatabaseService extends Fake implements LocalDatabaseService {}

class _FakeBackfillService implements ColdStartBackfillService {
  @override
  Future<bool> executeIfNeeded() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNativeNetworkService mockNativeService;
  late NetworkRepositoryImpl networkRepository;
  late SettingsRepositoryImpl settingsRepository;
  late LocalPreferencesService prefsService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    prefsService = LocalPreferencesService(prefs);
    mockNativeService = MockNativeNetworkService();
    networkRepository = NetworkRepositoryImpl(
      nativeService: mockNativeService,
      databaseService: _FakeLocalDatabaseService(),
      backfillService: _FakeBackfillService(),
    );
    settingsRepository = SettingsRepositoryImpl(
      preferencesService: prefsService,
      nativeService: mockNativeService,
    );
  });

  group('NetworkRepositoryImpl App Interop Tests', () {
    test('launchApp dispatches to native service successfully', () async {
      final result = await networkRepository.launchApp('com.google.android.youtube');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isTrue);
      expect(mockNativeService.lastLaunchedPackage, equals('com.google.android.youtube'));
    });

    test('openAppDetails dispatches to native service successfully', () async {
      final result = await networkRepository.openAppDetails('com.android.chrome');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isTrue);
      expect(mockNativeService.lastOpenedDetailsPackage, equals('com.android.chrome'));
    });
  });

  group('SettingsRepositoryImpl Battery & Notification Interop Tests', () {
    test('isIgnoringBatteryOptimizations queries native service', () async {
      mockNativeService.batteryOptimizationsIgnored = false;
      final result1 = await settingsRepository.isIgnoringBatteryOptimizations();
      expect(result1.isSuccess, isTrue);
      expect(result1.dataOrNull, isFalse);

      mockNativeService.batteryOptimizationsIgnored = true;
      final result2 = await settingsRepository.isIgnoringBatteryOptimizations();
      expect(result2.isSuccess, isTrue);
      expect(result2.dataOrNull, isTrue);
    });

    test('requestIgnoreBatteryOptimizations triggers native service exemption', () async {
      final result = await settingsRepository.requestIgnoreBatteryOptimizations();
      expect(result.isSuccess, isTrue);
      expect(mockNativeService.batteryOptimizationsIgnored, isTrue);
    });

    test('sendQuotaNotification dispatches title, body, and severity to native service', () async {
      final result = await settingsRepository.sendQuotaNotification(
        title: '⚠️ Data Warning',
        body: 'You have consumed 80% of your plan.',
        isWarning: true,
      );

      expect(result.isSuccess, isTrue);
      expect(mockNativeService.lastNotificationTitle, equals('⚠️ Data Warning'));
      expect(mockNativeService.lastNotificationBody, equals('You have consumed 80% of your plan.'));
      expect(mockNativeService.lastNotificationIsWarning, isTrue);
    });
  });
}
