import '../../core/errors/app_failure.dart';
import '../../core/functional/result.dart';
import '../models/app_usage_entity.dart';
import '../models/time_range.dart';
import '../repositories/i_network_repository.dart';

/// Interactor for querying per-application usage breakdown across a time range.
class GetAppBreakdownUseCase {
  final INetworkRepository _repository;

  const GetAppBreakdownUseCase(this._repository);

  Future<Result<List<AppUsageEntity>, AppFailure>> call({
    required TimeRange range,
    int networkType = -1,
    int billingResetDay = 1,
    bool includeIcons = true,
  }) {
    return _repository.getAppsUsage(
      range: range,
      networkType: networkType,
      billingResetDay: billingResetDay,
      includeIcons: includeIcons,
    );
  }
}
