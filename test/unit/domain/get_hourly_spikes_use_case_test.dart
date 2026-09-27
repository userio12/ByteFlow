import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/errors/app_failure.dart';
import 'package:byteflow/domain/models/hourly_spike_entity.dart';
import 'package:byteflow/domain/use_cases/get_hourly_spikes_use_case.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  group('GetHourlySpikesUseCase', () {
    late FakeNetworkRepository fakeRepo;
    late GetHourlySpikesUseCase useCase;

    setUp(() {
      fakeRepo = FakeNetworkRepository();
      useCase = GetHourlySpikesUseCase(fakeRepo);
    });

    test('returns detected hourly spikes list from repository', () async {
      final spikes = [
        const HourlySpikeEntity(
          hourOfDay: 14,
          totalBytes: 52428800, // 50 MB
          culpritAppName: 'YouTube',
          culpritPackageName: 'com.google.android.youtube',
          culpritBytes: 45000000,
        ),
      ];
      fakeRepo.hourlySpikes = spikes;

      final result = await useCase();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.length, equals(1));
      expect(result.dataOrNull?.first.culpritAppName, equals('YouTube'));
      expect(result.dataOrNull?.first.hourOfDay, equals(14));
    });

    test('propagates failure when query fails', () async {
      fakeRepo.errorToReturn = const DatabaseFailure(
        message: 'Database query failed',
      );

      final result = await useCase();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<DatabaseFailure>());
    });
  });
}
