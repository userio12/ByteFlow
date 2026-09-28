import 'package:flutter/foundation.dart';
import '../../../../domain/models/data_plan_entity.dart';
import '../../../../domain/models/sim_info_entity.dart';
import '../../../../domain/repositories/i_plan_repository.dart';
import '../../../../domain/repositories/i_settings_repository.dart';
import '../../../../domain/use_cases/get_active_sim_info_use_case.dart';
import '../../../../domain/use_cases/get_data_plan_use_case.dart';
import '../../../../domain/use_cases/get_today_usage_use_case.dart';
import '../../../../domain/use_cases/save_data_plan_use_case.dart';

/// Active category tab for plan inspection and quota management.
enum PlanCategory { cellular, wifi }

/// ViewModel managing data plan quota configuration, carrier SIM details, and billing cycle pace.
class PlanViewModel extends ChangeNotifier {
  final GetDataPlanUseCase _getDataPlanUseCase;
  final SaveDataPlanUseCase _saveDataPlanUseCase;
  final GetActiveSimInfoUseCase _getActiveSimInfoUseCase;
  final GetTodayUsageUseCase _getTodayUsageUseCase;
  final IPlanRepository? _planRepository;
  final ISettingsRepository? _settingsRepository;

  PlanViewModel({
    required GetDataPlanUseCase getDataPlanUseCase,
    required SaveDataPlanUseCase saveDataPlanUseCase,
    required GetActiveSimInfoUseCase getActiveSimInfoUseCase,
    required GetTodayUsageUseCase getTodayUsageUseCase,
    IPlanRepository? planRepository,
    ISettingsRepository? settingsRepository,
  })  : _getDataPlanUseCase = getDataPlanUseCase,
        _saveDataPlanUseCase = saveDataPlanUseCase,
        _getActiveSimInfoUseCase = getActiveSimInfoUseCase,
        _getTodayUsageUseCase = getTodayUsageUseCase,
        _planRepository = planRepository,
        _settingsRepository = settingsRepository;

  PlanCategory _selectedCategory = PlanCategory.cellular;
  PlanCategory get selectedCategory => _selectedCategory;

  DataPlanEntity _cellularPlan = const DataPlanEntity();
  DataPlanEntity _wifiPlan = const DataPlanEntity(
    quotaBytes: 100 * 1024 * 1024 * 1024,
    cycleType: DataPlanCycleType.monthly,
    resetDay: 1,
  );

  DataPlanEntity get plan => _selectedCategory == PlanCategory.cellular
      ? _cellularPlan
      : _wifiPlan;

  SimInfoEntity? _activeSim;
  SimInfoEntity? get activeSim => _activeSim;

  List<SimInfoEntity> _allSims = const [];
  List<SimInfoEntity> get allSims => _allSims;

  int _cellularCycleUsedBytes = 0;
  int _wifiCycleUsedBytes = 0;

  int get cycleUsedBytes => _selectedCategory == PlanCategory.cellular
      ? _cellularCycleUsedBytes
      : _wifiCycleUsedBytes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void selectCategory(PlanCategory category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void init() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Load active data plan (cellular)
      final planResult = await _getDataPlanUseCase();
      planResult.when(
        success: (plan) => _cellularPlan = plan,
        failure: (f) => _errorMessage = f.message,
      );

      // 2. Load Wi-Fi plan
      if (_planRepository != null) {
        final wifiResult = await _planRepository.getWifiPlan();
        wifiResult.when(
          success: (wifiPlan) => _wifiPlan = wifiPlan,
          failure: (_) {},
        );
      }

      // 3. Load active SIM & all SIMs
      final simResult = await _getActiveSimInfoUseCase();
      simResult.when(
        success: (sim) => _activeSim = sim,
        failure: (_) {},
      );

      final allSimsResult = await _getActiveSimInfoUseCase.getAllSims();
      allSimsResult.when(
        success: (sims) => _allSims = sims,
        failure: (_) {},
      );

      // 4. Load today / cycle usage for both mobile and wifi
      final usageResult = await _getTodayUsageUseCase();
      usageResult.when(
        success: (summary) {
          _cellularCycleUsedBytes = summary.mobileTotal;
          _wifiCycleUsedBytes = summary.wifiTotal;
        },
        failure: (_) {},
      );

      // 5. Evaluate Quota Thresholds and trigger system notification if crossed
      if (_settingsRepository != null && _cellularPlan.quotaBytes > 0) {
        final percent = _cellularPlan.usagePercent(_cellularCycleUsedBytes);
        if (_cellularPlan.isExhausted(_cellularCycleUsedBytes)) {
          await _settingsRepository.sendQuotaNotification(
            title: '🚨 Data Limit Reached',
            body: 'You have consumed 100% of your cellular data quota.',
            isWarning: false,
          );
        } else if (_cellularPlan.isWarning(_cellularCycleUsedBytes)) {
          await _settingsRepository.sendQuotaNotification(
            title: '⚠️ Data Warning Alert',
            body: 'You have consumed ${percent.toStringAsFixed(0)}% of your cellular data quota.',
            isWarning: true,
          );
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> savePlan(DataPlanEntity newPlan) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool success = false;
    try {
      if (_selectedCategory == PlanCategory.cellular) {
        final result = await _saveDataPlanUseCase(newPlan);
        success = result.fold(
          (_) {
            _cellularPlan = newPlan;
            return true;
          },
          (failure) {
            _errorMessage = failure.message;
            return false;
          },
        );
      } else {
        if (_planRepository != null) {
          final result = await _planRepository.saveWifiPlan(newPlan);
          success = result.fold(
            (_) {
              _wifiPlan = newPlan;
              return true;
            },
            (failure) {
              _errorMessage = failure.message;
              return false;
            },
          );
        } else {
          _wifiPlan = newPlan;
          success = true;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }
}
