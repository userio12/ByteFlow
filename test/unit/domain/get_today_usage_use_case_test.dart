import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/errors/app_failure.dart';
import 'package:byteflow/domain/models/network_summary_entity.dart';
import 'package:byteflow/domain/use_cases/get_today_usage_use_case.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  group('GetTodayUsageUseCase', () {
    late FakeNetworkRepository fakeRepo;
    late GetTodayUsageUseCase useCase;

    setUp(() {
      fakeRepo = FakeNetworkRepository();
      useCase = GetTodayUsageUseCase(fakeRepo);
    });

    test('returns successful network summary from repository', () async {
      final summary = NetworkSummaryEntity(
        mobileRx: 1000,
        mobileTx: 500,
        wifiRx: 2000,
        wifiTx: 1000,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );
      fakeRepo.todaySummary = summary;

      final result = await useCase();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(summary));
      expect(result.dataOrNull?.mobileTotal, equals(1500));
      expect(result.dataOrNull?.wifiTotal, equals(3000));
    });

    test('propagates failure when repository fails', () async {
      fakeRepo.errorToReturn = const PlatformFailure(
        code: 'KERNEL_ERROR',
        message: 'Could not query network stats',
      );

      final result = await useCase();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PlatformFailure>());
      expect((result.failureOrNull as PlatformFailure).code, equals('KERNEL_ERROR'));
    });
  });
}
