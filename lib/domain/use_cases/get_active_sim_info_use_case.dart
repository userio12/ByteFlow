import '../../core/errors/app_failure.dart';
import '../../core/functional/result.dart';
import '../models/sim_info_entity.dart';
import '../repositories/i_network_repository.dart';

/// Interactor for querying active carrier subscriptions and determining default data SIM.
class GetActiveSimInfoUseCase {
  final INetworkRepository _repository;

  const GetActiveSimInfoUseCase(this._repository);

  /// Returns the active data SIM (or first active SIM if no default declared).
  Future<Result<SimInfoEntity?, AppFailure>> call() async {
    final result = await _repository.getActiveSimCards();
    return result.map((sims) {
      if (sims.isEmpty) return null;
      return sims.firstWhere(
        (sim) => sim.isDefaultData,
        orElse: () => sims.first,
      );
    });
  }

  /// Returns all active SIM subscriptions installed in device slots.
  Future<Result<List<SimInfoEntity>, AppFailure>> getAllSims() {
    return _repository.getActiveSimCards();
  }
}
