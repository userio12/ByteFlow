import '../../core/errors/app_failure.dart';
import '../../core/functional/result.dart';
import '../models/data_plan_entity.dart';
import '../repositories/i_plan_repository.dart';

/// Interactor for retrieving user's data plan quota configuration.
class GetDataPlanUseCase {
  final IPlanRepository _repository;

  const GetDataPlanUseCase(this._repository);

  Future<Result<DataPlanEntity, AppFailure>> call() {
    return _repository.getDataPlan();
  }
}
