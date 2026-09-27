import '../../core/errors/app_failure.dart';
import '../../core/functional/result.dart';
import '../../domain/models/data_plan_entity.dart';
import '../../domain/repositories/i_plan_repository.dart';
import '../models/data_plan_dto.dart';
import '../services/local_preferences_service.dart';

/// Concrete repository implementing data plan persistence via local preferences.
class PlanRepositoryImpl implements IPlanRepository {
  final LocalPreferencesService _preferencesService;

  const PlanRepositoryImpl(this._preferencesService);

  @override
  Future<Result<DataPlanEntity, AppFailure>> getDataPlan() async {
    try {
      final dto = _preferencesService.getDataPlan();
      return Result.success(dto.toEntity());
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to retrieve data plan: $e'),
      );
    }
  }

  @override
  Future<Result<void, AppFailure>> saveDataPlan(DataPlanEntity plan) async {
    try {
      final dto = DataPlanDto.fromEntity(plan);
      await _preferencesService.saveDataPlan(dto);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to persist data plan: $e'),
      );
    }
  }

  @override
  Future<Result<DataPlanEntity, AppFailure>> getWifiPlan() async {
    try {
      final dto = _preferencesService.getWifiPlan();
      return Result.success(dto.toEntity());
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to retrieve Wi-Fi plan: $e'),
      );
    }
  }

  @override
  Future<Result<void, AppFailure>> saveWifiPlan(DataPlanEntity plan) async {
    try {
      final dto = DataPlanDto.fromEntity(plan);
      await _preferencesService.saveWifiPlan(dto);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to persist Wi-Fi plan: $e'),
      );
    }
  }
}
