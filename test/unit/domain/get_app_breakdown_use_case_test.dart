import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/errors/app_failure.dart';
import 'package:byteflow/domain/models/app_usage_entity.dart';
import 'package:byteflow/domain/models/time_range.dart';
import 'package:byteflow/domain/use_cases/get_app_breakdown_use_case.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  group('GetAppBreakdownUseCase Unit Test', () {
    late FakeNetworkRepository fakeNetworkRepo;
    late GetAppBreakdownUseCase useCase;

    setUp(() {
      fakeNetworkRepo = FakeNetworkRepository();
      useCase = GetAppBreakdownUseCase(fakeNetworkRepo);
    });

    test('returns sorted list of app usage entities', () async {
      fakeNetworkRepo.appsUsage = const [
        AppUsageEntity(
          uid: 10042,
          packageName: 'com.google.android.youtube',
          appName: 'YouTube',
          foregroundRx: 104857600,
          foregroundTx: 10485760,
          backgroundRx: 5242880,
          backgroundTx: 1048576,
          rxBytes: 110100480,
          txBytes: 11534336,
        ),
        AppUsageEntity(
          uid: 10099,
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          foregroundRx: 52428800,
          foregroundTx: 5242880,
          backgroundRx: 10485760,
          backgroundTx: 2097152,
          rxBytes: 62914560,
          txBytes: 7340032,
        ),
      ];

      final result = await useCase(
        range: TimeRange.today,
        networkType: -1,
      );

      expect(result.isSuccess, isTrue);
      result.when(
        success: (apps) {
          expect(apps.length, equals(2));
          expect(apps.first.appName, equals('YouTube'));
          expect(apps.first.foregroundBytes, equals(115343360));
          expect(apps.first.backgroundBytes, equals(6291456));
          expect(apps.last.appName, equals('Instagram'));
        },
        failure: (f) => fail('Expected success, got $f'),
      );
    });

    test('propagates failure when repository fails', () async {
      fakeNetworkRepo.errorToReturn =
          const PlatformFailure(code: 'KERNEL_ERROR', message: 'Failed to read netstats');

      final result = await useCase(range: TimeRange.today);

      expect(result.isFailure, isTrue);
      result.when(
        success: (_) => fail('Expected failure'),
        failure: (f) => expect(f.message, contains('Failed to read netstats')),
      );
    });
  });
}
