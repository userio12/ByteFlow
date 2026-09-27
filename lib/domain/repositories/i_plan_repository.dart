import '../../core/errors/app_failure.dart';
import '../../core/functional/result.dart';
import '../models/data_plan_entity.dart';

/// Contract defining data plan configuration persistence and retrieval.
abstract interface class IPlanRepository {
  /// Fetches currently configured data plan or defaults.
  Future<Result<DataPlanEntity, AppFailure>> getDataPlan();

  /// Persists user-defined data plan quota and billing cycle settings.
  Future<Result<void, AppFailure>> saveDataPlan(DataPlanEntity plan);

  /// Fetches currently configured Wi-Fi / Hotspot plan or defaults.
  Future<Result<DataPlanEntity, AppFailure>> getWifiPlan();

  /// Persists Wi-Fi / Hotspot data plan settings.
  Future<Result<void, AppFailure>> saveWifiPlan(DataPlanEntity plan);
}
