import 'package:flutter_test/flutter_test.dart';
import 'package:byteflow/core/errors/app_failure.dart';
import 'package:byteflow/domain/models/data_plan_entity.dart';
import 'package:byteflow/domain/use_cases/save_data_plan_use_case.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  group('SaveDataPlanUseCase', () {
    late FakePlanRepository fakeRepo;
    late SaveDataPlanUseCase useCase;

    setUp(() {
      fakeRepo = FakePlanRepository();
      useCase = SaveDataPlanUseCase(fakeRepo);
    });

    test('saves valid data plan successfully', () async {
      const validPlan = DataPlanEntity(
        quotaBytes: 10737418240, // 10 GB
        cycleType: DataPlanCycleType.monthly,
        resetDay: 15,
        alertThresholdPercent: 90.0,
        warningThresholdPercent: 75.0,
      );

      final result = await useCase(validPlan);

      expect(result.isSuccess, isTrue);
      expect(fakeRepo.plan.quotaBytes, equals(10737418240));
      expect(fakeRepo.plan.resetDay, equals(15));
    });

    test('fails validation when quotaBytes <= 0', () async {
      const invalidPlan = DataPlanEntity(quotaBytes: 0);

      final result = await useCase(invalidPlan);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        (result.failureOrNull as ValidationFailure).message,
        contains('greater than zero bytes'),
      );
    });

    test('fails validation when resetDay is out of range 1..31', () async {
      const invalidPlanLow = DataPlanEntity(quotaBytes: 1000, resetDay: 0);
      final resultLow = await useCase(invalidPlanLow);
      expect(resultLow.isFailure, isTrue);

      const invalidPlanHigh = DataPlanEntity(quotaBytes: 1000, resetDay: 32);
      final resultHigh = await useCase(invalidPlanHigh);
      expect(resultHigh.isFailure, isTrue);
    });

    test('fails validation when alertThresholdPercent is invalid', () async {
      const invalidAlert = DataPlanEntity(
        quotaBytes: 1000,
        alertThresholdPercent: 105.0,
      );
      final result = await useCase(invalidAlert);
      expect(result.isFailure, isTrue);
    });

    test('fails validation when warningThresholdPercent exceeds alert threshold', () async {
      const invertedThresholds = DataPlanEntity(
        quotaBytes: 1000,
        alertThresholdPercent: 50.0,
        warningThresholdPercent: 80.0,
      );
      final result = await useCase(invertedThresholds);
      expect(result.isFailure, isTrue);
      expect(
        (result.failureOrNull as ValidationFailure).message,
        contains('Warning threshold must be between 1% and the critical alert threshold'),
      );
    });
  });
}
