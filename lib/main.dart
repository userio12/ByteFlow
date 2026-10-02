import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/di/dependency_injection.dart';
import 'core/theme/app_theme.dart';
import 'data/services/local_preferences_service.dart';
import 'data/services/native_network_service.dart';
import 'domain/repositories/i_settings_repository.dart';
import 'l10n/app_localizations.dart';
import 'ui/core/widgets/adaptive_scaffold.dart';
import 'ui/features/app_usage/view_models/app_usage_view_model.dart';
import 'ui/features/app_usage/views/app_usage_view.dart';
import 'ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'ui/features/dashboard/views/dashboard_view.dart';
import 'ui/features/history/view_models/history_view_model.dart';
import 'ui/features/history/views/history_view.dart';
import 'ui/features/onboarding/view_models/onboarding_view_model.dart';
import 'ui/features/onboarding/views/onboarding_view.dart';
import 'ui/features/plan/view_models/plan_view_model.dart';
import 'ui/features/plan/views/plan_view.dart';
import 'ui/features/settings/view_models/settings_view_model.dart';
import 'ui/features/settings/views/settings_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final providers = await DependencyInjection.createProviders();

    runApp(
      MultiProvider(
        providers: providers,
        child: const ByteFlowApp(),
      ),
    );
  } catch (error, stackTrace) {
    debugPrint('ByteFlow fatal initialization error: $error\n$stackTrace');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF3B82F6),
        ),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to initialize ByteFlow',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The root ByteFlow application widget configuring Material 3 dynamic Monet palettes and localization.
class ByteFlowApp extends StatelessWidget {
  const ByteFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel?>();
    final themeMode = settingsVm?.themeMode ?? ThemeMode.system;

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'ByteFlow',
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)?.appTitle ?? 'ByteFlow',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.lightTheme(lightDynamic?.harmonized()),
          darkTheme: AppTheme.darkTheme(darkDynamic?.harmonized()),
          themeMode: themeMode,
          home: const AppRootRouter(),
        );
      },
    );
  }
}

/// Top-level router selecting between guided onboarding and the adaptive main navigation scaffold.
class AppRootRouter extends StatefulWidget {
  const AppRootRouter({super.key});

  @override
  State<AppRootRouter> createState() => _AppRootRouterState();
}

class _AppRootRouterState extends State<AppRootRouter> {
  late bool _isOnboardingCompleted;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<LocalPreferencesService>();
    _isOnboardingCompleted = prefs.getOnboardingCompleted();
  }

  void _handleOnboardingFinished() {
    setState(() {
      _isOnboardingCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnboardingCompleted) {
      return OnboardingView(
        viewModel: context.read<OnboardingViewModel>(),
        onFinished: _handleOnboardingFinished,
      );
    }

    return const MainNavigationHost();
  }
}

/// The main navigation host binding the 4 primary tabs to [AdaptiveScaffold] with state preservation.
class MainNavigationHost extends StatefulWidget {
  const MainNavigationHost({super.key});

  @override
  State<MainNavigationHost> createState() => _MainNavigationHostState();
}

class _MainNavigationHostState extends State<MainNavigationHost> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreLiveSpeedServiceIfEnabled();
    });
  }

  Future<void> _restoreLiveSpeedServiceIfEnabled() async {
    if (!mounted) return;
    try {
      final settingsRepo = context.read<ISettingsRepository>();
      final isEnabledResult = await settingsRepo.isLiveSpeedEnabled();
      final isEnabled = isEnabledResult.dataOrNull ?? true;
      if (isEnabled && mounted) {
        final nativeService = context.read<NativeNetworkService>();

        // Ensure POST_NOTIFICATIONS is granted on Android 13+
        final hasPermission = await nativeService.hasNotificationPermission();
        if (!hasPermission) {
          final granted = await nativeService.requestNotificationPermission();
          if (!granted) return;
        }

        final intervalResult = await settingsRepo.getLiveSpeedIntervalMs();
        final intervalMs = intervalResult.dataOrNull ?? 1000;
        await nativeService.startLiveSpeedService(intervalMs: intervalMs);
      }
    } catch (_) {}
  }

  void _setDestination(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsView(
          viewModel: context.read<SettingsViewModel>(),
          planViewModel: context.read<PlanViewModel>(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();
    final planVm = context.watch<PlanViewModel>();
    final settingsVm = context.watch<SettingsViewModel>();

    final hasActiveTraffic = dashboardVm.currentSpeed.totalBps > 1024;
    final hasPlanWarning = planVm.plan.isWarning(planVm.cycleUsedBytes);

    final children = [
      DashboardView(
        key: const ValueKey('tab_dashboard'),
        viewModel: dashboardVm,
        useBits: settingsVm.isSpeedUnitBits,
        onNavigateToApps: () => _setDestination(1),
        onNavigateToPlan: () => _setDestination(3),
        onOpenSettings: _openSettings,
      ),
      AppUsageView(
        key: const ValueKey('tab_apps'),
        viewModel: context.watch<AppUsageViewModel>(),
      ),
      HistoryView(
        key: const ValueKey('tab_history'),
        viewModel: context.watch<HistoryViewModel>(),
      ),
      PlanView(
        key: const ValueKey('tab_plan'),
        viewModel: planVm,
      ),
    ];

    return AdaptiveScaffold(
      currentIndex: _currentIndex,
      onDestinationSelected: _setDestination,
      hasActiveTraffic: hasActiveTraffic,
      hasPlanWarning: hasPlanWarning,
      children: children,
    );
  }
}