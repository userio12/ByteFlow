import 'package:flutter/foundation.dart';
import '../../../../core/constants/channel_constants.dart';
import '../../../../domain/models/app_type_filter.dart';
import '../../../../domain/models/app_usage_entity.dart';
import '../../../../domain/models/time_range.dart';
import '../../../../domain/use_cases/get_app_breakdown_use_case.dart';

/// ViewModel managing multi-timeframe app data usage breakdowns, search filtering, and network slicing.
class AppUsageViewModel extends ChangeNotifier {
  final GetAppBreakdownUseCase _getAppBreakdownUseCase;

  AppUsageViewModel({
    required GetAppBreakdownUseCase getAppBreakdownUseCase,
  }) : _getAppBreakdownUseCase = getAppBreakdownUseCase;

  TimeRange _selectedRange = TimeRange.today;
  TimeRange get selectedRange => _selectedRange;

  int _selectedNetworkType = ChannelConstants.networkTypeAll;
  int get selectedNetworkType => _selectedNetworkType;

  AppTypeFilter _selectedAppType = AppTypeFilter.userInstalled;
  AppTypeFilter get selectedAppType => _selectedAppType;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<AppUsageEntity> _allApps = const [];
  List<AppUsageEntity> _filteredApps = const [];
  List<AppUsageEntity> get filteredApps => _filteredApps;

  int get totalFilteredBytes =>
      _filteredApps.fold(0, (sum, app) => sum + app.totalBytes);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void init() {
    loadApps();
  }

  Future<void> setTimeRange(TimeRange range) async {
    if (_selectedRange != range) {
      _selectedRange = range;
      notifyListeners();
      await loadApps();
    }
  }

  Future<void> setNetworkType(int networkType) async {
    if (_selectedNetworkType != networkType) {
      _selectedNetworkType = networkType;
      notifyListeners();
      await loadApps();
    }
  }

  void setAppType(AppTypeFilter type) {
    if (_selectedAppType != type) {
      _selectedAppType = type;
      _applyFilter();
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  Future<void> loadApps() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _getAppBreakdownUseCase(
        range: _selectedRange,
        networkType: _selectedNetworkType,
        includeIcons: true,
      );

      result.when(
        success: (apps) {
          _allApps = apps;
          _applyFilter();
        },
        failure: (failure) {
          _errorMessage = failure.message;
        },
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilter() {
    Iterable<AppUsageEntity> filtered = _allApps;

    // 1. App Type Filtering (User Installed vs System vs All)
    switch (_selectedAppType) {
      case AppTypeFilter.userInstalled:
        filtered = filtered.where((app) => !app.isSystemApp);
        break;
      case AppTypeFilter.system:
        filtered = filtered.where((app) => app.isSystemApp);
        break;
      case AppTypeFilter.all:
        break;
    }

    // 2. Search Query Filtering
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((app) {
        final nameMatch = app.appName.toLowerCase().contains(_searchQuery);
        final pkgMatch = app.packageName.toLowerCase().contains(_searchQuery);
        return nameMatch || pkgMatch;
      });
    }

    _filteredApps = filtered.toList();
  }
}
