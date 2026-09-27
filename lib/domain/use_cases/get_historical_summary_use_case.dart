import '../../core/errors/app_failure.dart';
import '../../core/functional/result.dart';
import '../models/historical_summary_entity.dart';
import '../models/time_range.dart';
import '../repositories/i_network_repository.dart';

/// Interactor for aggregating multi-timeframe statistics (Today, Weekly, Monthly, Yearly).
class GetHistoricalSummaryUseCase {
  final INetworkRepository _repository;

  const GetHistoricalSummaryUseCase(this._repository);

  Future<Result<HistoricalSummaryEntity, AppFailure>> call({
    required TimeRange range,
    int billingResetDay = 1,
  }) {
    return _repository.getHistoricalSummary(
      range: range,
      billingResetDay: billingResetDay,
    );
  }
}
