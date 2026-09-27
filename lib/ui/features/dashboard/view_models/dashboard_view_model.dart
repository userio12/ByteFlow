import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../data/services/native_network_service.dart';
import '../../../../domain/models/app_usage_entity.dart';
import '../../../../domain/models/data_plan_entity.dart';
import '../../../../domain/models/network_summary_entity.dart';
import '../../../../domain/models/sim_info_entity.dart';
import '../../../../domain/models/speed_sample_entity.dart';
import '../../../../domain/models/time_range.dart';
import '../../../../domain/repositories/i_network_repository.dart';
import '../../../../domain/use_cases/get_active_sim_info_use_case.dart';
import '../../../../domain/use_cases/get_data_plan_use_case.dart';
import '../../../../domain/use_cases/get_today_usage_use_case.dart';

/// ViewModel driving real-time throughput pulses and daily summary metrics on the Dashboard.
class DashboardViewModel extends ChangeNotifier {
  final GetTodayUsageUseCase _getTodayUsageUseCase;
  final GetActiveSimInfoUseCase _getActiveSimInfoUseCase;
  final GetDataPlanUseCase _getDataPlanUseCase;
  final INetworkRepository _networkRepository;
  final NativeNetworkService _nativeService;

  DashboardViewModel({
    required GetTodayUsageUseCase getTodayUsageUseCase,
    required GetActiveSimInfoUseCase getActiveSimInfoUseCase,
    required GetDataPlanUseCase getDataPlanUseCase,
    required INetworkRepository networkRepository,
    required NativeNetworkService nativeService,
  })  : _getTodayUsageUseCase = getTodayUsageUseCase,
        _getActiveSimInfoUseCase = getActiveSimInfoUseCase,
        _getDataPlanUseCase = getDataPlanUseCase,
        _networkRepository = networkRepository,
        _nativeService = nativeService;

  NetworkSummaryEntity? _todaySummary;
  NetworkSummaryEntity? get todaySummary => _todaySummary;

  SimInfoEntity? _activeSim;
  SimInfoEntity? get activeSim => _activeSim;

  DataPlanEntity _dataPlan = const DataPlanEntity();
  DataPlanEntity get dataPlan => _dataPlan;

  List<AppUsageEntity> _topApps = const [];
  List<AppUsageEntity> get topApps => _topApps;

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

      // 3. Load active data plan quota
      final planResult = await _getDataPlanUseCase();
      planResult.when(
        success: (plan) => _dataPlan = plan,
        failure: (_) {},
      );

      // 4. Load top apps today (top 3)
      final appsResult = await _networkRepository.getAppsUsage(
        range: TimeRange.today,
        includeIcons: true,
      );
      appsResult.when(
        success: (apps) {
          _topApps = apps.take(3).toList();
        },
        failure: (_) {},
      );
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
