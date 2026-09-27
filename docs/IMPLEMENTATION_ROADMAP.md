# ByteFlow — Implementation Roadmap & Verification Plan

> **Governed by Official Flutter Agent Skills**:
> - [`flutter-apply-architecture-best-practices`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-apply-architecture-best-practices/SKILL.md)
> - [`flutter-build-responsive-layout`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-build-responsive-layout/SKILL.md)
> - [`flutter-add-widget-test`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-add-widget-test/SKILL.md)
> - [`dart-add-unit-test`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/dart-add-unit-test/SKILL.md)
> - [`flutter-implement-json-serialization`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-implement-json-serialization/SKILL.md)
> - [`flutter-setup-localization`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-setup-localization/SKILL.md)

This document outlines the phased execution strategy, automated test plan, and manual validation checklist for **ByteFlow**.

---

## 1. Phased Execution Roadmap

### Phase 1: Environment & Android Native Foundation
- [x] Configure `android/app/build.gradle.kts` (Kotlin source sets, AndroidX dependencies).
- [x] Update `android/app/src/main/AndroidManifest.xml` with permissions, foreground service, and widget receivers.
- [x] Implement `NetworkStatsHelper.kt`:
  - Usage access verification (`AppOpsManager`) and settings intent.
  - Automatic active SIM querying via `SubscriptionManager` (carrier name, slot, active data SIM).
  - Total device usage queries for Mobile and Wi-Fi via `querySummaryForDevice` (any epoch range: Today, Weekly, Monthly, Yearly).
  - Time bucket slicing via `queryTimeBuckets` (24h, 7d, 30d, 12mo).
  - Per-app usage queries via `querySummary` with foreground and background breakdowns.
- [x] Implement `LiveSpeedService.kt`:
  - Foreground service with low-priority ongoing notification.
  - Real-time `TrafficStats` delta calculation.
  - `ScreenReceiver` (`ACTION_SCREEN_OFF` / `ACTION_SCREEN_ON`) for 0% battery drain in sleep mode.
- [x] Implement `ByteFlowWidgetProvider.kt`:
  - Material 3 Home screen widget layout and RemoteViews data population.
- [x] Update `MainActivity.kt` to bind MethodChannel (`com.byteflow/network_v1`) and EventChannel (`com.byteflow/speed_stream_v1`).
- [x] **Phase 1 Verification Gate**: Execute `flutter analyze` (0 issues) ➔ `python3 -m graphify .`.

### Phase 2: Domain & Data Layers (Official Clean Architecture Workflow)
- [x] **Step 1: Domain Entities**: Implement immutable classes (`TimeRange`, `UsageTimeBucket`, `HistoricalSummaryEntity`, `AppUsageEntity`, `NetworkSummaryEntity`, `DataPlanEntity`, `SimInfoEntity`).
- [x] **Step 2: DTOs & Serialization**: Implement serializable DTOs (`AppUsageDto`, `NetworkSummaryDto`, `UsageTimeBucketDto`) adhering to `flutter-implement-json-serialization`.
- [x] **Step 3: Services & DAOs**: Implement stateless `NativeNetworkService`, `ColdStartBackfillService` (kernel cache ingestion), and SQLite DAOs (`NetworkSnapshotsDao`, `DailyRollupsDao`, `MonthlyRollupsDao`, `AppUsageDao`).
- [x] **Step 4: Repositories**: Implement `NetworkRepositoryImpl` (single source of truth with SQLite caching) and `PlanRepositoryImpl`.
- [x] **Step 5: Use Cases**: Implement pure business logic interactors:
  - `GetTodayUsageUseCase`
  - `GetHistoricalSummaryUseCase` (dynamic Today/Week/Month/Year aggregation)
  - `GetAppBreakdownUseCase` (filtered by TimeRange)
  - `GetHourlySpikesUseCase`
  - `SaveDataPlanUseCase`
- [x] **Phase 2 Verification Gate**: Execute `flutter analyze` (0 issues) ➔ `python3 -m graphify update .`.

### Phase 3: Presentation Layer (MVVM + Adaptive Responsive Layouts)
- [x] **Step 6: ViewModels (`ChangeNotifier`)**:
  - `DashboardViewModel`
  - `AppUsageViewModel` (TimeRange filtering & isolate `compute()`)
  - `HistoryViewModel` (Today 24h, Weekly 7d, Monthly 30d, Yearly 12mo)
  - `PlanViewModel`
  - `SettingsViewModel`
- [x] **Step 7: Adaptive Views (`ListenableBuilder` + `LayoutBuilder`)**:
  - Implement `AdaptiveScaffold` with breakpoint (`600dp` for Bottom NavigationBar vs NavigationRail).
  - Build `DashboardView` with `SpeedPulseCard`, active carrier badge, and `PlanProgressRing`.
  - Build `AppUsageView` with fixed `itemExtent: 76.0`, search filtering, and TimeRange selector.
  - Build `HistoryView` with `TimeRangeSegmentedButton` and `fl_chart` charts (`HourlySpikeChart`, `WeeklyComparisonChart`, `MonthlyTrajectoryChart`, `YearlyDistributionChart`).
  - Build `PlanView` for plan configuration.
  - Build `SettingsView` for status bar speed toggle, intervals, and permission health check.
- [x] **Step 8: Dependency Injection**: Register services, repositories, use cases, and view models using `Provider`.
- [x] **Phase 3 Verification Gate**: Execute `flutter analyze` (0 issues) ➔ `python3 -m graphify update .`.

### Phase 4: Quality Assurance & Automated Testing
- [x] **Step 9: Unit Tests (`dart-add-unit-test`)**:
  - `test/unit/core/byte_formatter_test.dart`: Exhaustive test of B, KB, MB, GB, TB conversion.
  - `test/unit/core/date_utils_test.dart`: Billing cycle reset day & leap year math.
  - `test/unit/core/result_test.dart`: Result<Success, Failure> monad branching.
  - `test/unit/domain/time_range_test.dart`: Verify Today, Week, Month, Year date bounds math.
  - `test/unit/domain/historical_summary_entity_test.dart`: Verify totals and Wi-Fi offload calculations.
  - `test/unit/domain/data_plan_entity_test.dart`: Quota percentage & remaining math.
  - `test/unit/domain/get_today_usage_use_case_test.dart`: UseCase business logic validation.
  - `test/unit/domain/get_hourly_spikes_use_case_test.dart`: Spike detection algorithm test.
  - `test/unit/domain/save_data_plan_use_case_test.dart`: Quota & cycle validation rules.
  - `test/unit/data/app_usage_dto_test.dart`: JSON serialization roundtrip test.
- [x] **Step 10: Widget Tests (`flutter-add-widget-test`)**:
  - Verify ViewModel state transitions and UI rendering across primary screens (`DashboardView`, `AppUsageView`, `PlanView`, `HistoryView`, `SettingsView`).
- [x] **Step 11: Static Analysis & Validation**:
  - Run `flutter test` (100% pass) ➔ `flutter analyze` (0 warnings) ➔ `python3 -m graphify update .`.

### Phase 5: Production Hardening & Advanced Capabilities
- [x] **Data Management & Backup**: CSV export utility and SQLite database vacuuming in `LocalDatabaseService` and `SettingsView`.
- [x] **Dual Wi-Fi Plan & FUP Tracking**: Wi-Fi plan quota management and policy cards in `PlanViewModel` and `PlanView`.
- [x] **Localization Coverage**: Comprehensive `lib/l10n/app_en.arb` string catalog and strongly-typed getters in `AppLocalizations`.
- [x] **R8 / ProGuard Minification Rules**: ProGuard keep rules for models, handlers, and widget providers in `proguard-rules.pro`.
- [x] **Root Documentation**: Comprehensive root `README.md` with system architecture diagrams, benchmark comparisons, and developer setup.

### Phase 6: Advanced System Interop & Quota Monitoring
- [x] **Native Boot & Alert Subsystem**: `BootCompletedReceiver.kt` and high-priority alert notification channel `AlertNotificationHelper.kt`.
- [x] **App Launch & Settings Interop**: `launchApp` and `openAppDetails` methods in `NetworkChannelHandler.kt` and `INetworkRepository`.
- [x] **OEM Battery Exemption Defense**: `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` status check and request dispatch in `BatterySaverCard`.
- [x] **Proactive Quota Alert Monitoring**: 80% warning and 100% critical quota threshold evaluations with system notifications in `PlanViewModel`.

---

## 2. Verification Plan

### 2.1 Automated Tests Command Matrix
```bash
# 1. Run all unit and widget tests
flutter test

# 2. Run static analysis ensuring 0 warnings and deprecation-free code
flutter analyze

# 3. Verify localization template compilation
flutter gen-l10n
```

### 2.2 Manual Verification Checklist
1. **Permission Flow**:
   - Launch app -> verify Usage Access prompt -> tap button -> opens system Settings -> grant permission -> return to app -> verify immediate data refresh.
2. **Carrier Detection**:
   - Verify active carrier name and SIM slot badge match the device's actual network status.
3. **Data Accuracy**:
   - Compare displayed Wi-Fi and Mobile data usage with Android System Settings -> Network & Internet -> Data usage.
4. **Live Speed Indicator & Battery Saver**:
   - Enable Live Speed Indicator in Settings -> verify persistent notification appears with current speeds and daily Mobile & Wi-Fi usage.
   - Turn screen off and on -> verify timer ticks halt completely during sleep mode.
5. **Home Screen Widget**:
   - Add ByteFlow widget to home screen -> verify it displays current usage, carrier name, and launches app on tap.
