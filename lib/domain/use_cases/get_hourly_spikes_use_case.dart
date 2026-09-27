import '../../core/errors/app_failure.dart';
import '../../core/functional/result.dart';
import '../models/hourly_spike_entity.dart';
import '../repositories/i_network_repository.dart';

/// Interactor for detecting peak hourly network bursts and identifying culprit apps.
class GetHourlySpikesUseCase {
  final INetworkRepository _repository;

  const GetHourlySpikesUseCase(this._repository);

  Future<Result<List<HourlySpikeEntity>, AppFailure>> call() {
    return _repository.getHourlySpikes();
  }
}
