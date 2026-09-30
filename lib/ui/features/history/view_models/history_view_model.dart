import 'package:flutter/foundation.dart';
import '../../../../core/constants/channel_constants.dart';
import '../../../../domain/models/historical_summary_entity.dart';
import '../../../../domain/models/hourly_spike_entity.dart';
import '../../../../domain/models/time_range.dart';
import '../../../../domain/models/usage_time_bucket.dart';
import '../../../../domain/repositories/i_plan_repository.dart';
import '../../../../domain/use_cases/get_historical_summary_use_case.dart';
import '../../../../domain/use_cases/get_hourly_spikes_use_case.dart';

/// ViewModel orchestrating multi-timeframe historical rollups and network slice filtering.
class HistoryViewModel extends ChangeNotifier {
  final GetHistoricalSummaryUseCase _getHistoricalSummaryUseCase;
  final GetHourlySpikesUseCase? _getHourlySpikesUseCase;
  final IPlanRepository _planRepository;

  HistoryViewModel({
    required GetHistoricalSummaryUseCase getHistoricalSummaryUseCase,
    GetHourlySpikesUseCase? getHourlySpikesUseCase,
    required IPlanRepository planRepository,
  })  : _getHistoricalSummaryUseCase = getHistoricalSummaryUseCase,
        _getHourlySpikesUseCase = getHourlySpikesUseCase,
        _planRepository = planRepository;

  TimeRange _selectedRange = TimeRange.today;
  TimeRange get selectedRange => _selectedRange;

  int _selectedNetworkType = ChannelConstants.networkTypeAll;
  int get selectedNetworkType => _selectedNetworkType;

  void setNetworkType(int networkType) {
    if (_selectedNetworkType != networkType) {
      _selectedNetworkType = networkType;
      notifyListeners();
    }
  }

  HistoricalSummaryEntity? _summary;
  HistoricalSummaryEntity? get summary => _summary;

  List<HourlySpikeEntity> _hourlySpikes = const [];
  List<HourlySpikeEntity> get hourlySpikes => _hourlySpikes;

  int? _selectedHourIndex;
  int? get selectedHourIndex => _selectedHourIndex;

  HourlySpikeEntity? get selectedSpike {
    if (_hourlySpikes.isEmpty) return null;
    if (_selectedHourIndex != null) {
      return _hourlySpikes.firstWhere(
        (s) => s.hourOfDay == _selectedHourIndex,
        orElse: () => _hourlySpikes.first,
      );
    }
    return _hourlySpikes.first; // Peak burst by default
  }

  UsageTimeBucket? get peakBucket => _summary?.peakBucket;

  int _quotaBytes = 5 * 1024 * 1024 * 1024;
  int get quotaBytes => _quotaBytes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void init() {
    loadData();
  }

  Future<void> setTimeRange(TimeRange range) async {
    if (_selectedRange != range) {
      _selectedRange = range;
      _selectedHourIndex = null;
      notifyListeners();
      await loadData();
    }
  }

  void selectHour(int hour) {
    if (_selectedHourIndex != hour) {
      _selectedHourIndex = hour;
      notifyListeners();
    }
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Load active data plan for monthly quota pace calculations
      final planResult = await _planRepository.getDataPlan();
      planResult.when(
        success: (plan) => _quotaBytes = plan.quotaBytes,
        failure: (_) {},
      );

      // 2. Load historical summary for selected timeframe
      final summaryResult = await _getHistoricalSummaryUseCase(
        range: _selectedRange,
      );
      summaryResult.when(
        success: (summary) => _summary = summary,
        failure: (failure) => _errorMessage = failure.message,
      );

      // 3. If Today range and spikes use case provided, also fetch granular hourly spikes
      if (_selectedRange == TimeRange.today && _getHourlySpikesUseCase != null) {
        final spikesResult = await _getHourlySpikesUseCase();
        spikesResult.when(
          success: (spikes) {
            _hourlySpikes = spikes;
          },
          failure: (_) {},
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
