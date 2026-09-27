import '../../core/errors/app_failure.dart';
import '../../core/functional/result.dart';
import '../models/network_summary_entity.dart';
import '../repositories/i_network_repository.dart';

/// Interactor for querying today's mobile and Wi-Fi cumulative usage.
class GetTodayUsageUseCase {
  final INetworkRepository _repository;

  const GetTodayUsageUseCase(this._repository);

  Future<Result<NetworkSummaryEntity, AppFailure>> call() {
    return _repository.getTodayUsage();
  }
}
