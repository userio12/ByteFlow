import '../../core/errors/app_failure.dart';
import '../../core/functional/result.dart';
import '../repositories/i_settings_repository.dart';

/// Interactor for starting or halting the ongoing status bar live speed service.
class ToggleLiveSpeedUseCase {
  final ISettingsRepository _repository;

  const ToggleLiveSpeedUseCase(this._repository);

  Future<Result<void, AppFailure>> call({
    required bool enabled,
    int intervalMs = 1000,
  }) {
    return _repository.setLiveSpeedEnabled(enabled, intervalMs: intervalMs);
  }
}
