import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/network_repository_impl.dart';
import '../../data/repositories/plan_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/services/cold_start_backfill_service.dart';
import '../../data/services/local_database_service.dart';
import '../../data/services/local_preferences_service.dart';
import '../../data/services/native_network_service.dart';
import '../../domain/repositories/i_network_repository.dart';
import '../../domain/repositories/i_plan_repository.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../../domain/use_cases/get_active_sim_info_use_case.dart';
import '../../domain/use_cases/get_app_breakdown_use_case.dart';
import '../../domain/use_cases/get_data_plan_use_case.dart';
import '../../domain/use_cases/get_historical_summary_use_case.dart';
import '../../domain/use_cases/get_hourly_spikes_use_case.dart';
import '../../domain/use_cases/get_today_usage_use_case.dart';
import '../../domain/use_cases/save_data_plan_use_case.dart';
import '../../domain/use_cases/toggle_live_speed_use_case.dart';
import '../../ui/features/app_usage/view_models/app_usage_view_model.dart';
import '../../ui/features/dashboard/view_models/dashboard_view_model.dart';
import '../../ui/features/history/view_models/history_view_model.dart';
import '../../ui/features/onboarding/view_models/onboarding_view_model.dart';
import '../../ui/features/plan/view_models/plan_view_model.dart';
import '../../ui/features/settings/view_models/settings_view_model.dart';

/// Service locator and dependency injection container configured for Provider.
abstract final class DependencyInjection {
  /// Asynchronously builds all providers for the global MultiProvider widget tree.
  static Future<List<SingleChildWidget>> createProviders({
    SharedPreferences? sharedPreferences,
    AppDatabase? appDatabase,
  }) async {
    final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
    final db = appDatabase ?? AppDatabase();
    final localDbService = LocalDatabaseService(db);
    try {
      await localDbService.init();
    } catch (e, stack) {
      debugPrint('LocalDatabaseService pre-warm warning (will initialize lazily): $e\n$stack');
    }

    final nativeNetworkService = NativeNetworkService();
    final localPrefsService = LocalPreferencesService(prefs);
    final coldStartBackfillService = ColdStartBackfillService(
      nativeService: nativeNetworkService,
      databaseService: localDbService,
      preferencesService: localPrefsService,
    );

    final networkRepository = NetworkRepositoryImpl(
      nativeService: nativeNetworkService,
      databaseService: localDbService,
      backfillService: coldStartBackfillService,
    );

    final planRepository = PlanRepositoryImpl(localPrefsService);
    final settingsRepository = SettingsRepositoryImpl(
      preferencesService: localPrefsService,
      nativeService: nativeNetworkService,
      databaseService: localDbService,
    );

    return [
      Provider<NativeNetworkService>.value(value: nativeNetworkService),
      Provider<LocalPreferencesService>.value(value: localPrefsService),
      Provider<LocalDatabaseService>.value(value: localDbService),
      Provider<ColdStartBackfillService>.value(value: coldStartBackfillService),
      Provider<INetworkRepository>.value(value: networkRepository),
      Provider<IPlanRepository>.value(value: planRepository),
      Provider<ISettingsRepository>.value(value: settingsRepository),
      Provider<GetTodayUsageUseCase>(
        create: (context) =>
            GetTodayUsageUseCase(context.read<INetworkRepository>()),
      ),
      Provider<GetHistoricalSummaryUseCase>(
        create: (context) =>
            GetHistoricalSummaryUseCase(context.read<INetworkRepository>()),
      ),
      Provider<GetAppBreakdownUseCase>(
        create: (context) =>
            GetAppBreakdownUseCase(context.read<INetworkRepository>()),
      ),
      Provider<GetHourlySpikesUseCase>(
        create: (context) =>
            GetHourlySpikesUseCase(context.read<INetworkRepository>()),
      ),
      Provider<GetActiveSimInfoUseCase>(
        create: (context) =>
            GetActiveSimInfoUseCase(context.read<INetworkRepository>()),
      ),
      Provider<GetDataPlanUseCase>(
        create: (context) =>
            GetDataPlanUseCase(context.read<IPlanRepository>()),
      ),
      Provider<SaveDataPlanUseCase>(
        create: (context) =>
            SaveDataPlanUseCase(context.read<IPlanRepository>()),
      ),
      Provider<ToggleLiveSpeedUseCase>(
        create: (context) =>
            ToggleLiveSpeedUseCase(context.read<ISettingsRepository>()),
      ),
      ChangeNotifierProvider<OnboardingViewModel>(
        create: (context) => OnboardingViewModel(
          settingsRepository: context.read<ISettingsRepository>(),
          nativeService: context.read<NativeNetworkService>(),
        ),
      ),
      ChangeNotifierProvider<DashboardViewModel>(
        create: (context) => DashboardViewModel(
          getTodayUsageUseCase: context.read<GetTodayUsageUseCase>(),
          getActiveSimInfoUseCase: context.read<GetActiveSimInfoUseCase>(),
          getDataPlanUseCase: context.read<GetDataPlanUseCase>(),
          nativeService: context.read<NativeNetworkService>(),
          planRepository: context.read<IPlanRepository>(),
        ),
      ),
      ChangeNotifierProvider<AppUsageViewModel>(
        create: (context) => AppUsageViewModel(
          getAppBreakdownUseCase: context.read<GetAppBreakdownUseCase>(),
        ),
      ),
      ChangeNotifierProvider<HistoryViewModel>(
        create: (context) => HistoryViewModel(
          getHistoricalSummaryUseCase:
              context.read<GetHistoricalSummaryUseCase>(),
          getHourlySpikesUseCase: context.read<GetHourlySpikesUseCase>(),
          planRepository: context.read<IPlanRepository>(),
        ),
      ),
      ChangeNotifierProvider<PlanViewModel>(
        create: (context) => PlanViewModel(
          getDataPlanUseCase: context.read<GetDataPlanUseCase>(),
          saveDataPlanUseCase: context.read<SaveDataPlanUseCase>(),
          getActiveSimInfoUseCase: context.read<GetActiveSimInfoUseCase>(),
          getTodayUsageUseCase: context.read<GetTodayUsageUseCase>(),
          planRepository: context.read<IPlanRepository>(),
          settingsRepository: context.read<ISettingsRepository>(),
        ),
      ),
      ChangeNotifierProvider<SettingsViewModel>(
        create: (context) => SettingsViewModel(
          settingsRepository: context.read<ISettingsRepository>(),
          toggleLiveSpeedUseCase: context.read<ToggleLiveSpeedUseCase>(),
          nativeService: context.read<NativeNetworkService>(),
        )..init(),
      ),
    ];
  }
}
