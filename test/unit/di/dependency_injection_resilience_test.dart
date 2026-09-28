import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:byteflow/core/di/dependency_injection.dart';
import 'package:byteflow/data/database/app_database.dart';

class _FailingAppDatabase extends AppDatabase {
  @override
  Future<Database> get database async {
    throw Exception('Simulated database disk failure on cold start');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DependencyInjection Resilience Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': false,
        'live_speed_enabled': false,
      });
    });

    test('createProviders succeeds and provides all core services even when database fails', () async {
      final prefs = await SharedPreferences.getInstance();
      final failingDb = _FailingAppDatabase();

      final providers = await DependencyInjection.createProviders(
        sharedPreferences: prefs,
        appDatabase: failingDb,
      );

      // Verify essential providers are present
      expect(providers, isNotEmpty);
      expect(providers.length, greaterThanOrEqualTo(10));
    });

    test('createProviders works normally with standard preferences mock', () async {
      final prefs = await SharedPreferences.getInstance();
      final failingDb = _FailingAppDatabase();

      final providers = await DependencyInjection.createProviders(
        sharedPreferences: prefs,
        appDatabase: failingDb,
      );

      expect(providers.any((p) => p.toString().contains('NativeNetworkService')), isTrue);
      expect(providers.any((p) => p.toString().contains('LocalPreferencesService')), isTrue);
      expect(providers.any((p) => p.toString().contains('INetworkRepository')), isTrue);
      expect(providers.any((p) => p.toString().contains('IPlanRepository')), isTrue);
      expect(providers.any((p) => p.toString().contains('ISettingsRepository')), isTrue);
    });
  });
}
