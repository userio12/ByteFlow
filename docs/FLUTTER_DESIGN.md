# ByteFlow — Flutter Design & State Specification

> **Governed by Official Flutter Agent Skills**:
> - [`flutter-apply-architecture-best-practices`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-apply-architecture-best-practices/SKILL.md)
> - [`flutter-build-responsive-layout`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-build-responsive-layout/SKILL.md)
> - [`flutter-implement-json-serialization`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-implement-json-serialization/SKILL.md)
> - [`flutter-setup-localization`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-setup-localization/SKILL.md)

This document details the presentation, architecture, state management, and user experience for the Flutter layer of ByteFlow following official Flutter engineering standards.

---

## 1. UI/UX Principles & Theming

- **Material 3 Foundation**: Leverages Material 3 design tokens, adaptive typography, elevation levels, and dynamic color harmonization (`dynamic_color`).
- **Dark Mode First**: Clean dark and light themes that adapt automatically to device preferences with high-contrast data visualization.
- **Adaptive Layouts**: Uses `MediaQuery.sizeOf(context)` and `LayoutBuilder` with adaptive breakpoints (`largeScreenMinWidth = 600.0`) to provide two-pane or sidebar layouts on foldables and tablets.
- **Micro-Interactions**: Subtle animated speedometers, smooth progress bars, and tactile feedback.
- **Glanceable Information**: Critical plan metrics (data used, quota remaining, days left, top consumers) are visible within 2 seconds of opening the app.

---

## 2. Feature-Driven Layered Structure

Following `flutter-apply-architecture-best-practices`, the codebase is organized with UI grouped by feature, and Data/Domain grouped by type:

```text
lib/
├── data/
│   ├── models/                # JSON / Platform DTO models
│   │   ├── app_usage_dto.dart
│   │   ├── network_summary_dto.dart
│   │   └── usage_time_bucket_dto.dart
│   ├── database/              # SQLite DAOs (sqflite)
│   │   ├── app_database.dart
│   │   ├── daos/network_snapshots_dao.dart
│   │   ├── daos/daily_rollups_dao.dart
│   │   ├── daos/monthly_rollups_dao.dart
│   │   └── daos/app_usage_dao.dart
│   ├── repositories/          # Repository implementations
│   │   ├── network_repository_impl.dart
│   │   └── plan_repository_impl.dart
│   └── services/              # Platform IPC & SQLite local storage
│       ├── native_network_service.dart
│       ├── cold_start_backfill_service.dart
│       └── local_database_service.dart
├── domain/
│   ├── models/                # Clean, immutable domain entities
│   │   ├── time_range.dart    # TimeRange enum (today, week, month, year)
│   │   ├── usage_time_bucket.dart # Sliced time series bucket
│   │   ├── historical_summary_entity.dart # Multi-timeframe totals
│   │   ├── app_usage_entity.dart
│   │   ├── network_summary_entity.dart
│   │   ├── data_plan_entity.dart
│   │   └── sim_info_entity.dart
│   └── use_cases/             # Interactors (reusable business logic)
│       ├── get_today_usage_use_case.dart
│       ├── get_historical_summary_use_case.dart
│       ├── get_app_breakdown_use_case.dart
│       └── get_hourly_spikes_use_case.dart
└── ui/
    ├── core/                  # Shared widgets, themes, typography
    │   ├── theme/
    │   ├── utils/
    │   └── widgets/
    └── features/              # Feature modules (MVVM: ViewModel + View)
        ├── dashboard/
        │   ├── view_models/dashboard_view_model.dart
        │   └── views/dashboard_view.dart
        ├── app_usage/
        │   ├── view_models/app_usage_view_model.dart
        │   └── views/app_usage_view.dart
        ├── history/
        │   ├── view_models/history_view_model.dart
        │   └── views/history_view.dart
        ├── plan/
        │   ├── view_models/plan_view_model.dart
        │   └── views/plan_view.dart
        └── settings/
            ├── view_models/settings_view_model.dart
            └── views/settings_view.dart
```

---

## 3. Domain Models (Immutable Entities)

### 3.1 `SimInfoEntity`
```dart
class SimInfoEntity {
  final int subId;
  final int slotIndex;
  final String displayName;
  final String carrierName;
  final String countryIso;
  final bool isDataRoaming;
  final bool isDefaultDataSub;

  const SimInfoEntity({
    required this.subId,
    required this.slotIndex,
    required this.displayName,
    required this.carrierName,
    required this.countryIso,
    required this.isDataRoaming,
    required this.isDefaultDataSub,
  });
}
```

### 3.2 `DataPlanEntity`
```dart
enum PlanCycleType { monthly, daily, customDays }

class DataPlanEntity {
  final int planSizeBytes;
  final PlanCycleType cycleType;
  final int resetDay; // 1-31
  final int warningThresholdPercent; // e.g. 80

  const DataPlanEntity({
    required this.planSizeBytes,
    this.cycleType = PlanCycleType.monthly,
    this.resetDay = 1,
    this.warningThresholdPercent = 80,
  });

  double calculateUsagePercent(int usedBytes) {
    if (planSizeBytes <= 0) return 0.0;
    return (usedBytes / planSizeBytes).clamp(0.0, 1.0);
  }

  int calculateRemainingBytes(int usedBytes) {
    final remaining = planSizeBytes - usedBytes;
    return remaining > 0 ? remaining : 0;
  }
}
```

### 3.3 `AppUsageEntity`
```dart
class AppUsageEntity {
  final int uid;
  final String packageName;
  final String appName;
  final int totalRx;
  final int totalTx;
  final int foregroundRx;
  final int foregroundTx;
  final int backgroundRx;
  final int backgroundTx;

  int get totalBytes => totalRx + totalTx;
  int get foregroundBytes => foregroundRx + foregroundTx;
  int get backgroundBytes => backgroundRx + backgroundTx;

  const AppUsageEntity({
    required this.uid,
    required this.packageName,
    required this.appName,
    required this.totalRx,
    required this.totalTx,
    required this.foregroundRx,
    required this.foregroundTx,
    required this.backgroundRx,
    required this.backgroundTx,
  });
}
```

---

## 4. MVVM Implementation Example (Official Skill Pattern)

### 4.1 Dashboard ViewModel (`ChangeNotifier`)
```dart
class DashboardViewModel extends ChangeNotifier {
  final GetTodayUsageUseCase _getTodayUsageUseCase;
  final NativeNetworkService _nativeService;

  DashboardViewModel({
    required GetTodayUsageUseCase getTodayUsageUseCase,
    required NativeNetworkService nativeService,
  })  : _getTodayUsageUseCase = getTodayUsageUseCase,
        _nativeService = nativeService;

  NetworkSummaryEntity? _todaySummary;
  NetworkSummaryEntity? get todaySummary => _todaySummary;

  SpeedSample _currentSpeed = const SpeedSample(0, 0);
  SpeedSample get currentSpeed => _currentSpeed;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<SpeedSample>? _speedSub;

  void initialize() {
    loadTodayUsage();
    _speedSub = _nativeService.speedStream.listen((sample) {
      _currentSpeed = sample;
      notifyListeners();
    });
  }

  Future<void> loadTodayUsage() async {
    _isLoading = true;
    notifyListeners();

    final result = await _getTodayUsageUseCase.execute();
    result.when(
      success: (summary) => _todaySummary = summary,
      failure: (failure) => /* handle failure */ null,
    );

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _speedSub?.cancel();
    super.dispose();
  }
}
```

### 4.2 Dashboard View (`ListenableBuilder`)
```dart
class DashboardView extends StatelessWidget {
  const DashboardView({super.key, required this.viewModel});

  final DashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.isLoading && viewModel.todaySummary == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600.0;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800.0),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    SpeedPulseCard(speed: viewModel.currentSpeed),
                    const SizedBox(height: 16.0),
                    if (viewModel.todaySummary != null)
                      PlanProgressRing(summary: viewModel.todaySummary!),
                    // ... other dashboard components
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
```
