import '../../core/errors/app_failure.dart';
import '../../core/functional/result.dart';
import '../models/data_plan_entity.dart';
import '../repositories/i_plan_repository.dart';

/// Interactor for validating and persisting user data plan quotas.
class SaveDataPlanUseCase {
  final IPlanRepository _repository;

  const SaveDataPlanUseCase(this._repository);

  Future<Result<void, AppFailure>> call(DataPlanEntity plan) async {
    if (plan.quotaBytes <= 0) {
      return const Result.failure(
        ValidationFailure(message: 'Data quota must be greater than zero bytes.'),
      );
    }

    if (plan.resetDay < 1 || plan.resetDay > 31) {
      return const Result.failure(
        ValidationFailure(message: 'Billing cycle reset day must be between 1 and 31.'),
      );
    }

    if (plan.alertThresholdPercent <= 0 || plan.alertThresholdPercent > 100) {
      return const Result.failure(
        ValidationFailure(
          message: 'Alert threshold percentage must be between 1% and 100%.',
        ),
      );
    }

    if (plan.warningThresholdPercent <= 0 ||
        plan.warningThresholdPercent > plan.alertThresholdPercent) {
      return const Result.failure(
        ValidationFailure(
          message:
              'Warning threshold must be between 1% and the critical alert threshold.',
        ),
      );
    }

    return _repository.saveDataPlan(plan);
  }
}
