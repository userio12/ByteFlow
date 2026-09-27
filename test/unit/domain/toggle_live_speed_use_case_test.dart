import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/errors/app_failure.dart';
import 'package:byteflow/domain/use_cases/toggle_live_speed_use_case.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  group('ToggleLiveSpeedUseCase Unit Test', () {
    late FakeSettingsRepository fakeSettingsRepo;
    late ToggleLiveSpeedUseCase useCase;

    setUp(() {
      fakeSettingsRepo = FakeSettingsRepository();
      useCase = ToggleLiveSpeedUseCase(fakeSettingsRepo);
    });

    test('enables live speed with specified interval', () async {
      final result = await useCase(enabled: true, intervalMs: 2000);

      expect(result.isSuccess, isTrue);
      expect(fakeSettingsRepo.liveSpeedEnabled, isTrue);
      expect(fakeSettingsRepo.liveSpeedIntervalMs, equals(2000));
    });

    test('disables live speed successfully', () async {
      fakeSettingsRepo.liveSpeedEnabled = true;

      final result = await useCase(enabled: false);

      expect(result.isSuccess, isTrue);
      expect(fakeSettingsRepo.liveSpeedEnabled, isFalse);
    });

    test('propagates failure when repository fails', () async {
      fakeSettingsRepo.errorToReturn =
          const PlatformFailure(code: 'SERVICE_ERROR', message: 'Unable to start foreground service');

      final result = await useCase(enabled: true);

      expect(result.isFailure, isTrue);
      result.when(
        success: (_) => fail('Expected failure'),
        failure: (f) => expect(f.message, contains('Unable to start foreground service')),
      );
    });
  });
}
