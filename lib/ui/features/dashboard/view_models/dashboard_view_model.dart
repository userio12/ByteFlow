import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../data/services/native_network_service.dart';
import '../../../../domain/models/data_plan_entity.dart';
import '../../../../domain/models/network_summary_entity.dart';
import '../../../../domain/models/sim_info_entity.dart';
import '../../../../domain/models/speed_sample_entity.dart';
import '../../../../domain/repositories/i_plan_repository.dart';
import '../../../../domain/use_cases/get_active_sim_info_use_case.dart';
import '../../../../domain/use_cases/get_data_plan_use_case.dart';
import '../../../../domain/use_cases/get_today_usage_use_case.dart';
import '../../plan/view_models/plan_view_model.dart';

/// ViewModel driving real-time throughput pulses and daily summary metrics on the Dashboard.
class DashboardViewModel extends ChangeNotifier {
  final GetTodayUsageUseCase _getTodayUsageUseCase;
  final GetActiveSimInfoUseCase _getActiveSimInfoUseCase;
  final GetDataPlanUseCase _getDataPlanUseCase;
  final NativeNetworkService _nativeService;
  final IPlanRepository? _planRepository;

  DashboardViewModel({
    required GetTodayUsageUseCase getTodayUsageUseCase,
    required GetActiveSimInfoUseCase getActiveSimInfoUseCase,
    required GetDataPlanUseCase getDataPlanUseCase,
    required NativeNetworkService nativeService,
    IPlanRepository? planRepository,
  })  : _getTodayUsageUseCase = getTodayUsageUseCase,
        _getActiveSimInfoUseCase = getActiveSimInfoUseCase,
        _getDataPlanUseCase = getDataPlanUseCase,
        _nativeService = nativeService,
        _planRepository = planRepository;

  PlanCategory _selectedCategory = PlanCategory.cellular;
  PlanCategory get selectedCategory => _selectedCategory;

  NetworkSummaryEntity? _todaySummary;
  NetworkSummaryEntity? get todaySummary => _todaySummary;

  SimInfoEntity? _activeSim;
  SimInfoEntity? get activeSim => _activeSim;

  DataPlanEntity _cellularPlan = const DataPlanEntity();
  DataPlanEntity _wifiPlan = const DataPlanEntity(
    quotaBytes: 100 * 1024 * 1024 * 1024,
    cycleType: DataPlanCycleType.monthly,
    resetDay: 1,
  );

  DataPlanEntity get dataPlan =>
      _selectedCategory == PlanCategory.cellular ? _cellularPlan : _wifiPlan;
  DataPlanEntity get activePlan => dataPlan;
  DataPlanEntity get cellularPlan => _cellularPlan;
  DataPlanEntity get wifiPlan => _wifiPlan;

  int get activeUsedBytes => _selectedCategory == PlanCategory.cellular
      ? (_todaySummary?.mobileTotal ?? 0)
      : (_todaySummary?.wifiTotal ?? 0);

  void selectCategory(PlanCategory category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  SpeedSampleEntity _currentSpeed = SpeedSampleEntity(
    downloadBps: 0,
    uploadBps: 0,
    timestamp: DateTime.now(),
  );
  SpeedSampleEntity get currentSpeed => _currentSpeed;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<dynamic>? _speedSubscription;

  void init() {
    loadData();
    _startSpeedSubscription();
  }

  void _startSpeedSubscription() {
    _speedSubscription?.cancel();
    _speedSubscription = _nativeService.speedStream.listen(
      (dto) {
        _currentSpeed = SpeedSampleEntity(
          downloadBps: dto.downloadBps,
          uploadBps: dto.uploadBps,
          timestamp: DateTime.fromMillisecondsSinceEpoch(dto.timestampMs),
        );
        notifyListeners();
      },
      onError: (_) {
        // Silent recovery on event channel glitches
      },
    );
  }

  Future<void> refresh() async {
    await loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Load today's cumulative hardware accounting
      final todayResult = await _getTodayUsageUseCase();
      todayResult.when(
        success: (summary) => _todaySummary = summary,
        failure: (failure) => _errorMessage = failure.message,
      );

      // 2. Load active SIM info
      final simResult = await _getActiveSimInfoUseCase();
      simResult.when(
        success: (sim) => _activeSim = sim,
        failure: (_) {},
      );

      // 3. Load active data plan quota (cellular)
      final planResult = await _getDataPlanUseCase();
      planResult.when(
        success: (plan) => _cellularPlan = plan,
        failure: (_) {},
      );

      // 4. Load Wi-Fi data plan quota
      if (_planRepository != null) {
        final wifiResult = await _planRepository.getWifiPlan();
        wifiResult.when(
          success: (wifiPlan) => _wifiPlan = wifiPlan,
          failure: (_) {},
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _speedSubscription?.cancel();
    super.dispose();
  }
}
