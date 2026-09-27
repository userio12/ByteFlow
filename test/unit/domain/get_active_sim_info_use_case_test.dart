import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/errors/app_failure.dart';
import 'package:byteflow/domain/models/sim_info_entity.dart';
import 'package:byteflow/domain/use_cases/get_active_sim_info_use_case.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  group('GetActiveSimInfoUseCase Unit Test', () {
    late FakeNetworkRepository fakeNetworkRepo;
    late GetActiveSimInfoUseCase useCase;

    setUp(() {
      fakeNetworkRepo = FakeNetworkRepository();
      useCase = GetActiveSimInfoUseCase(fakeNetworkRepo);
    });

    test('returns null when no SIM cards are detected', () async {
      fakeNetworkRepo.activeSims = [];

      final result = await useCase();
      expect(result.isSuccess, isTrue);
      result.when(
        success: (sim) => expect(sim, isNull),
        failure: (f) => fail('Expected success, got $f'),
      );
    });

    test('returns default data SIM when multiple SIMs are present', () async {
      fakeNetworkRepo.activeSims = const [
        SimInfoEntity(
          subId: 1,
          slotIndex: 0,
          carrierName: 'Airtel',
          displayName: 'SIM 1',
          isDefaultData: false,
        ),
        SimInfoEntity(
          subId: 2,
          slotIndex: 1,
          carrierName: 'Jio 5G',
          displayName: 'SIM 2',
          isDefaultData: true,
        ),
      ];

      final result = await useCase();
      expect(result.isSuccess, isTrue);
      result.when(
        success: (sim) {
          expect(sim, isNotNull);
          expect(sim!.carrierName, equals('Jio 5G'));
          expect(sim.subId, equals(2));
          expect(sim.isDefaultData, isTrue);
        },
        failure: (f) => fail('Expected success, got $f'),
      );
    });

    test('falls back to first SIM if none are explicitly default data', () async {
      fakeNetworkRepo.activeSims = const [
        SimInfoEntity(
          subId: 1,
          slotIndex: 0,
          carrierName: 'T-Mobile',
          displayName: 'SIM 1',
          isDefaultData: false,
        ),
      ];

      final result = await useCase();
      expect(result.isSuccess, isTrue);
      result.when(
        success: (sim) {
          expect(sim, isNotNull);
          expect(sim!.carrierName, equals('T-Mobile'));
        },
        failure: (f) => fail('Expected success, got $f'),
      );
    });

    test('propagates failure when repository fails', () async {
      fakeNetworkRepo.errorToReturn =
          const PlatformFailure(code: 'SIM_ERROR', message: 'Unable to query SIM cards');

      final result = await useCase();
      expect(result.isFailure, isTrue);
      result.when(
        success: (_) => fail('Expected failure'),
        failure: (f) => expect(f.message, contains('Unable to query SIM cards')),
      );
    });
  });
}
