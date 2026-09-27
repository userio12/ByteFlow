# ByteFlow — Detailed Phase-by-Phase Implementation Tracker

> **Execution Standard**: Senior Mobile Systems Architect Blueprint  
> **Skill Standard**: Official Google/Flutter Team Plugins ([`.agents/skills/`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/))  
> **Continuous Verification Protocol**: After every single phase, execute **`flutter analyze`** (ensuring 0 errors/warnings) and **`graphify update .`** (updating the AST knowledge graph).

---

## Progress Overview

| Phase | Description | Status | Verification Gate |
| :--- | :--- | :--- | :--- |
| **Phase 1** | Environment, Dependencies & Android Native Subsystem | ✅ Complete | `flutter analyze` + `python3 -m graphify .` |
| **Phase 2** | Core Infrastructure, Domain Layer & SQLite Data Layer | ✅ Complete | `flutter analyze` + `python3 -m graphify extract . --code-only` |
| **Phase 3** | Presentation Layer (MVVM Features, UI Widgets & Animations) | ✅ Complete | `flutter analyze` + `graphify extract . --code-only` |
| **Phase 4** | Automated Testing Suite, Static Analysis & Final Walkthrough | ✅ Complete | `flutter test` + `flutter analyze` + `python3 -m graphify extract . --code-only` |
| **Phase 5** | Production Hardening, Polish, Advanced Capabilities & Release | ✅ Complete | `flutter test` + `flutter analyze` + `python3 -m graphify extract . --code-only` |
| **Phase 6** | Advanced System Interop, Background Quota Monitoring & Deep App Diagnostics | ✅ Complete | `flutter test` + `flutter analyze` + `python3 -m graphify extract . --code-only` |

---

## Phase 1: Environment, Dependencies & Android Native Subsystem

**Objective**: Configure Flutter dependencies, native Android Gradle builds, permissions, Kotlin hardware network accounting, foreground live speed service, and home screen widget.

### 1.1 Flutter Configuration & Dependencies
- [x] Configure [pubspec.yaml](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/pubspec.yaml):
  - [x] Package name: `byteflow`
  - [x] Dependencies: `provider: ^6.1.5`, `shared_preferences: ^2.5.4`, `intl: ^0.20.2`, `fl_chart: ^1.2.0`, `sqflite: ^2.4.2`, `path: ^1.9.1`
  - [x] Dev dependencies: `flutter_test`, `flutter_lints: ^5.0.0`
- [x] Run `flutter pub get` and verify dependency tree lockfile.

### 1.2 Android Native Build Configuration & Manifest
- [x] Configure [android/app/build.gradle.kts](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/android/app/build.gradle.kts):
  - [x] Target SDK 35, compile SDK 35, min SDK 21
  - [x] Include sourceSets: `src/main/kotlin`, `src/main/java`
  - [x] Dependencies: `androidx.core:core-ktx:1.15.0`, `androidx.appcompat:appcompat:1.7.0`, `kotlinx-coroutines-android:1.8.1`
  - [x] Remove unused CMake build block.
- [x] Configure [android/app/src/main/AndroidManifest.xml](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/android/app/src/main/AndroidManifest.xml):
  - [x] Update app label to `"ByteFlow"`.
  - [x] Declare permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `READ_PHONE_STATE`, `PACKAGE_USAGE_STATS`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`.
  - [x] Register `LiveSpeedService` with `foregroundServiceType="dataSync"`.
  - [x] Register `ByteFlowWidgetProvider` with `android.appwidget.action.APPWIDGET_UPDATE`.

### 1.3 Native Android Resources (XML Layouts, Drawables & Metadata)
- [x] Create `android/app/src/main/res/xml/byteflow_widget_info.xml` (Widget dimensions, update interval, initial layout).
- [x] Create `android/app/src/main/res/drawable/widget_background.xml` (Material 3 rounded container drawable).
- [x] Create `android/app/src/main/res/drawable/widget_progress_bar.xml` (Custom XML progress drawable).
- [x] Create `android/app/src/main/res/layout/widget_byteflow.xml` (RemoteViews layout: Carrier badge, Today's data, % bar).
- [x] Create `android/app/src/main/res/values/colors.xml` and update `strings.xml`.

### 1.4 Native Kotlin Models & Records
- [x] Create `android/app/src/main/kotlin/com/byteflow/model/AppUsageRecord.kt` (uid, packageName, appName, rx, tx, fgRx, fgTx, bgRx, bgTx).
- [x] Create `android/app/src/main/kotlin/com/byteflow/model/NetworkTotalRecord.kt` (mobileRx, mobileTx, wifiRx, wifiTx, startTimeMs, endTimeMs).
- [x] Create `android/app/src/main/kotlin/com/byteflow/model/UsageBucketRecord.kt` (startTimeMs, endTimeMs, rxBytes, txBytes).
- [x] Create `android/app/src/main/kotlin/com/byteflow/model/SimRecord.kt` (subId, slotIndex, displayName, carrierName, isDefaultData).

### 1.5 Native Kotlin Hardware Accounting & Telephony Helper (Zero-Static Data)
- [x] Create `android/app/src/main/kotlin/com/byteflow/network/NetworkStatsHelper.kt`:
  - [x] `hasUsageStatsPermission(context): Boolean`
  - [x] `openUsageAccessSettings(context)`
  - [x] `hasPhoneStatePermission(context): Boolean`
  - [x] `getActiveSimCards(context): List<SimRecord>` via `SubscriptionManager`
  - [x] `queryDeviceTotal(context, networkType, startMs, endMs): NetworkTotalRecord` (Dynamically queries kernel tables for any epoch window: Today, Weekly, Monthly, Yearly)
  - [x] `queryAppsUsage(context, networkType, startMs, endMs): List<AppUsageRecord>` via `NetworkStatsManager.querySummary` (Zero synthetic apps; live `PackageManager` labels & icons)
  - [x] `queryTimeBuckets(context, networkType, startMs, endMs, stepIntervalMs): List<UsageBucketRecord>` (Discrete bucket slices: 24h, 7d, 30d, 12mo)
- [x] Create `android/app/src/main/kotlin/com/byteflow/network/IconCacheHelper.kt` (8MB memory LruCache with 48x48dp downsampling to prevent OOM).

### 1.6 Native Kotlin Live Speed Service & Screen-Off Battery Saver
- [x] Create `android/app/src/main/kotlin/com/byteflow/service/ScreenReceiver.kt` (Listens to `ACTION_SCREEN_OFF` / `ACTION_SCREEN_ON`).
- [x] Create `android/app/src/main/kotlin/com/byteflow/service/SpeedNotificationHelper.kt` (Low-priority silent notification channel).
- [x] Create `android/app/src/main/kotlin/com/byteflow/service/LiveSpeedService.kt`:
  - [x] Compute real-time throughput from `TrafficStats` delta.
  - [x] Emit speed samples to EventChannel sink.
  - [x] Screen-aware lifecycle: halt sampling loop during display sleep (0% CPU).
  - [x] Foreground notification updates (`↓ X MB/s  ↑ Y KB/s`).

### 1.7 Native Kotlin Home Screen Widget Provider
- [x] Create `android/app/src/main/kotlin/com/byteflow/widget/ByteFlowWidgetProvider.kt`:
  - [x] `onUpdate`: Pulls cached statistics from SharedPreferences.
  - [x] Builds `RemoteViews` for `widget_byteflow.xml` and updates `AppWidgetManager`.
  - [x] Binds click PendingIntent launching `MainActivity`.

### 1.8 Platform Channel Handler & Activity Wiring
- [x] Create `android/app/src/main/kotlin/com/byteflow/network/NetworkChannelHandler.kt` (Coroutine `Dispatchers.IO` handler for `com.byteflow/network_v1`).
- [x] Update `android/app/src/main/kotlin/com/byteflow/MainActivity.kt` (Registers MethodChannel and EventChannel).

### 🛡️ Phase 1 Verification Protocol
- [x] **Run Static Analysis**: `flutter analyze` ➔ Verify **0 issues found**.
- [x] **Update Knowledge Graph**: `python3 -m graphify .` ➔ Generates `graphify-out/index.html` & `GRAPH_REPORT.md`.

---

## Phase 2: Core Infrastructure, Domain Layer & SQLite Data Layer

**Objective**: Implement functional error handling, clean domain entities, isolated use cases, DTO serialization, and SQLite time-series caching.

### 2.1 Core Infrastructure & Foundations
- [x] Create `lib/core/functional/result.dart` (Functional `Result<Success, AppFailure>` monad).
- [x] Create `lib/core/errors/app_failure.dart` (Sealed typed failures: `PermissionFailure`, `PlatformFailure`, `DatabaseFailure`).
- [x] Create `lib/core/errors/exceptions.dart` (Low-level platform exceptions).
- [x] Create `lib/core/constants/channel_constants.dart` (`'com.byteflow/network_v1'`, `'com.byteflow/speed_stream_v1'`).
- [x] Create `lib/core/constants/storage_keys.dart` (Key definitions).
- [x] Create `lib/core/utils/byte_formatter.dart` (B, KB, MB, GB, TB conversion with formatting).
- [x] Create `lib/core/utils/date_utils.dart` (24-hour time slices, billing reset date math, leap year support).
- [x] Create `lib/core/utils/platform_utils.dart` (OS version & permission checks).
- [x] Create `lib/core/theme/app_icons.dart` (Material 3 rounded icon registry).
- [x] Create `lib/core/theme/app_colors.dart` (Monet dynamic color harmonization helpers).
- [x] Create `lib/core/theme/app_typography.dart` (Material 3 type scale).
- [x] Create `lib/core/theme/app_theme.dart` (Light and OLED Dark theme configurations).

### 2.2 Pure Dart Domain Layer (Clean Architecture & Dynamic Timeframes)
- [x] Create `lib/domain/models/time_range.dart` (Enum: `today`, `week`, `month`, `year` with dynamic date bounds math).
- [x] Create `lib/domain/models/usage_time_bucket.dart` (Discrete bucket: start, end, label, mobile/wifi rx/tx).
- [x] Create `lib/domain/models/historical_summary_entity.dart` (Aggregated summary: range, bounds, totals, buckets, offload %).
- [x] Create `lib/domain/models/app_usage_entity.dart` (Immutable app record with FG/BG split and live app icon).
- [x] Create `lib/domain/models/network_summary_entity.dart` (Mobile vs Wi-Fi totals, Rx/Tx split).
- [x] Create `lib/domain/models/data_plan_entity.dart` (Quota size, cycle type, reset day, alert threshold %).
- [x] Create `lib/domain/models/sim_info_entity.dart` (SubId, carrier name, slot index, isDefaultData).
- [x] Create `lib/domain/models/speed_sample_entity.dart` (Real-time download/upload B/s).
- [x] Create `lib/domain/models/hourly_spike_entity.dart` (Hour index 0-23, peak bytes, culprit app).
- [x] Create `lib/domain/repositories/i_network_repository.dart` (Contract supporting dynamic time ranges).
- [x] Create `lib/domain/repositories/i_plan_repository.dart` (Contract for plan quotas).
- [x] Create `lib/domain/repositories/i_settings_repository.dart` (Contract for user preferences).
- [x] Create `lib/domain/use_cases/get_today_usage_use_case.dart`.
- [x] Create `lib/domain/use_cases/get_historical_summary_use_case.dart` (Dynamic multi-timeframe aggregation).
- [x] Create `lib/domain/use_cases/get_app_breakdown_use_case.dart` (Parameterized by `TimeRange` or custom bounds).
- [x] Create `lib/domain/use_cases/get_hourly_spikes_use_case.dart`.
- [x] Create `lib/domain/use_cases/get_active_sim_info_use_case.dart`.
- [x] Create `lib/domain/use_cases/get_data_plan_use_case.dart`.
- [x] Create `lib/domain/use_cases/save_data_plan_use_case.dart`.
- [x] Create `lib/domain/use_cases/toggle_live_speed_use_case.dart`.

### 2.3 Data Layer & SQLite Database (DAO Pattern & Zero-Static Rollups)
- [x] Create `lib/data/models/app_usage_dto.dart` (Pattern-matched serialization per `flutter-implement-json-serialization`).
- [x] Create `lib/data/models/network_summary_dto.dart`.
- [x] Create `lib/data/models/usage_time_bucket_dto.dart`.
- [x] Create `lib/data/models/data_plan_dto.dart`.
- [x] Create `lib/data/models/sim_info_dto.dart`.
- [x] Create `lib/data/models/speed_sample_dto.dart`.
- [x] Create `lib/data/services/native_network_service.dart` (MethodChannel and EventChannel wrapper).
- [x] Create `lib/data/services/cold_start_backfill_service.dart` (Extracts real past kernel records on launch; zero fake data).
- [x] Create `lib/data/services/local_preferences_service.dart` (SharedPreferences wrapper).
- [x] Create `lib/data/database/database_tables.dart` (DDL statements: hourly, daily, monthly, and app snapshots).
- [x] Create `lib/data/database/app_database.dart` (Database connection, migrations, and schema creation).
- [x] Create `lib/data/database/daos/network_snapshots_dao.dart` (Hourly snapshot CRUD).
- [x] Create `lib/data/database/daos/daily_rollups_dao.dart` (Daily snapshots for Weekly & Monthly aggregation).
- [x] Create `lib/data/database/daos/monthly_rollups_dao.dart` (Monthly snapshots for Yearly aggregation).
- [x] Create `lib/data/database/daos/app_usage_dao.dart` (Daily per-app snapshot CRUD).
- [x] Create `lib/data/services/local_database_service.dart` (SQLite coordination service).
- [x] Create `lib/data/repositories/network_repository_impl.dart` (Coordinates Native IPC + SQLite cache).
- [x] Create `lib/data/repositories/plan_repository_impl.dart` (DataPlan persistence).
- [x] Create `lib/data/repositories/settings_repository_impl.dart` (Preference persistence).
- [x] Create `lib/core/di/dependency_injection.dart` (MultiProvider service locator graph).

### 🛡️ Phase 2 Verification Protocol
- [x] **Run Static Analysis**: `flutter analyze` ➔ Verify **0 issues found**.
- [x] **Update Knowledge Graph**: `python3 -m graphify extract . --code-only` ➔ Re-extracts changed files and keeps the graph current.

---

## Phase 3: Presentation Layer (MVVM Features, UI Widgets & Animations)

**Objective**: Implement feature ViewModels (`ChangeNotifier`), dumb Views (`ListenableBuilder`), adaptive layouts (`LayoutBuilder`), animations, and Material 3 design tokens.

### 3.1 Shared Presentation Core & Custom Animations
- [x] Create `lib/ui/core/animations/count_up_text.dart` (Rolling numeric ticker animation).
- [x] Create `lib/ui/core/animations/pulse_indicator.dart` (Real-time speed halo throb).
- [x] Create `lib/ui/core/animations/radial_gauge.dart` (Custom-painted circular plan progress arc).
- [x] Create `lib/ui/core/widgets/adaptive_scaffold.dart` (Switches between NavigationBar and NavigationRail at 600dp).
- [x] Create `lib/ui/core/widgets/time_range_segmented_button.dart` (Interactive Today / Weekly / Monthly / Yearly switcher).
- [x] Create `lib/ui/core/widgets/metric_card.dart` (Material 3 tonal surface card).
- [x] Create `lib/ui/core/widgets/carrier_badge.dart` (Active carrier chip).
- [x] Create `lib/ui/core/widgets/empty_state_card.dart` (Permission guidance).
- [x] Create `lib/ui/core/widgets/error_snackbar.dart` (Error display banner).

### 3.2 Feature 0: Guided Onboarding Carousel
- [x] Create `lib/ui/features/onboarding/view_models/onboarding_view_model.dart`.
- [x] Create `lib/ui/features/onboarding/widgets/permission_slide.dart`.
- [x] Create `lib/ui/features/onboarding/views/onboarding_view.dart` (5-step guided carousel).

### 3.3 Feature 1: Dashboard (Home & Live Pulse)
- [x] Create `lib/ui/features/dashboard/widgets/speed_pulse_card.dart` (Dual download/upload speedometer).
- [x] Create `lib/ui/features/dashboard/widgets/plan_progress_ring.dart` (Progress arc, consumed GB, days left, pace chip).
- [x] Create `lib/ui/features/dashboard/widgets/daily_comparison_tile.dart` (Cellular vs Wi-Fi today).
- [x] Create `lib/ui/features/dashboard/widgets/top_apps_preview_card.dart` (Top 3 apps mini progress bars).
- [x] Create `lib/ui/features/dashboard/view_models/dashboard_view_model.dart` (Drives live pulse and dynamic dashboard state).
- [x] Create `lib/ui/features/dashboard/views/dashboard_view.dart` (Material 3 responsive dashboard).

### 3.4 Feature 2: App Usage Detective (Multi-Timeframe Filtering)
- [x] Create `lib/ui/features/app_usage/widgets/foreground_background_bar.dart` (Stacked FG vs BG bar).
- [x] Create `lib/ui/features/app_usage/widgets/app_usage_tile.dart` (App row with live icon, dynamic bytes, FG/BG badges).
- [x] Create `lib/ui/features/app_usage/widgets/app_search_filter_bar.dart` (Search input + Network & TimeRange chips).
- [x] Create `lib/ui/features/app_usage/widgets/app_details_bottom_sheet.dart` (Dynamic timeline bottom sheet).
- [x] Create `lib/ui/features/app_usage/view_models/app_usage_view_model.dart` (Sorting, debouncing, isolate compute across Today/Week/Month/Year).
- [x] Create `lib/ui/features/app_usage/views/app_usage_view.dart` (Virtualized ListView with fixed `itemExtent: 76.0`).

### 3.5 Feature 3: History & Spikes Analytics (Hourly, Weekly, Monthly, Yearly)
- [x] Create `lib/ui/features/history/widgets/hourly_spike_chart.dart` (Interactive `fl_chart` 24-hr spike timeline for Today).
- [x] Create `lib/ui/features/history/widgets/weekly_comparison_chart.dart` (7-day comparative grouped bars).
- [x] Create `lib/ui/features/history/widgets/monthly_trajectory_chart.dart` (30-day cumulative burn curve vs ideal quota pace).
- [x] Create `lib/ui/features/history/widgets/yearly_distribution_chart.dart` (12-month annual cellular vs Wi-Fi distribution).
- [x] Create `lib/ui/features/history/widgets/spike_culprit_card.dart` (Identifies culprit app for selected time bucket).
- [x] Create `lib/ui/features/history/widgets/insights_grid.dart` (Daily average, projected total, offload ratio).
- [x] Create `lib/ui/features/history/view_models/history_view_model.dart` (Drives dynamic multi-timeframe aggregations).
- [x] Create `lib/ui/features/history/views/history_view.dart` (Host view with TimeRange selector).

### 3.6 Feature 4: Plan & Quota Settings
- [x] Create `lib/ui/features/plan/widgets/carrier_status_card.dart` (Active carrier network status).
- [x] Create `lib/ui/features/plan/widgets/plan_summary_card.dart` (Quota used, remaining, daily allowance).
- [x] Create `lib/ui/features/plan/widgets/edit_plan_modal_sheet.dart` (Quota slider, cycle picker, alert threshold).
- [x] Create `lib/ui/features/plan/view_models/plan_view_model.dart` (Quota calculations & validation).
- [x] Create `lib/ui/features/plan/views/plan_view.dart` (Plan settings view).

### 3.7 Feature 5: Settings & Status Bar Indicator
- [x] Create `lib/ui/features/settings/widgets/status_bar_settings_tile.dart` (Live speed switch, 1.0s-3.0s interval picker).
- [x] Create `lib/ui/features/settings/widgets/battery_saver_card.dart` (Explains `ACTION_SCREEN_OFF` sleep pause).
- [x] Create `lib/ui/features/settings/widgets/permission_health_card.dart` (Live status of system permissions).
- [x] Create `lib/ui/features/settings/widgets/privacy_guarantee_tile.dart` (100% on-device pledge).
- [x] Create `lib/ui/features/settings/view_models/settings_view_model.dart` (Notification switch & interval state).
- [x] Create `lib/ui/features/settings/views/settings_view.dart` (Grouped settings view).

### 3.8 App Entry Point Bootstrap
- [x] Update `lib/main.dart` (Wires `DynamicColorBuilder`, `MultiProvider`, `MaterialApp`, and `AdaptiveScaffold`).

### 🛡️ Phase 3 Verification Protocol
- [x] **Run Static Analysis**: `flutter analyze` ➔ Verify **0 issues found**.
- [x] **Update Knowledge Graph**: `graphify extract . --code-only` ➔ Re-extracts presentation nodes and UI data flows.

---

## Phase 4: Automated Testing Suite, Verification & Final Walkthrough

**Objective**: Implement automated unit tests, widget tests, platform channel mocks, and verify full build health.

### 4.1 Automated Unit Tests (`dart-add-unit-test`)
- [x] Create `test/unit/core/byte_formatter_test.dart` (0 B, 1024 B, 1.5 MB, 10.2 GB, 2 TB formatting).
- [x] Create `test/unit/core/date_utils_test.dart` (Billing cycle reset day math & leap year tests).
- [x] Create `test/unit/core/result_test.dart` (Result monad success/failure branching).
- [x] Create `test/unit/domain/time_range_test.dart` (Boundary calculations for today, week, month, year).
- [x] Create `test/unit/domain/historical_summary_entity_test.dart` (Aggregated bucket totals, Wi-Fi offload % math).
- [x] Create `test/unit/domain/data_plan_entity_test.dart` (Percentage calculation & remaining quota math).
- [x] Create `test/unit/domain/get_today_usage_use_case_test.dart` (UseCase interaction test).
- [x] Create `test/unit/domain/get_hourly_spikes_use_case_test.dart` (Spike detection algorithm test).
- [x] Create `test/unit/domain/save_data_plan_use_case_test.dart` (Quota and cycle validation rules).
- [x] Create `test/unit/data/app_usage_dto_test.dart` (JSON/Map serialization roundtrip test).

### 4.2 Automated Widget Tests (`flutter-add-widget-test`)
- [x] Create `test/mocks/mock_native_network_service.dart` (Mock platform channel).
- [x] Create `test/mocks/mock_repositories.dart` (Mock repository interfaces).
- [x] Create `test/widget/features/dashboard_view_test.dart` (Verify speedometer & plan gauge rendering).
- [x] Create `test/widget/features/app_usage_view_test.dart` (Verify search filtering & list interaction).
- [x] Create `test/widget/features/plan_view_test.dart` (Verify quota edit sheet interaction).
- [x] Create `test/widget/core/radial_gauge_test.dart` (Verify CustomPainter arc rendering).

### 4.3 Performance Benchmarking & Profiling Gate (`PERFORMANCE_OPTIMIZATION_PLAN.md`)
- [x] Measure UI Frame Rasterization: `WidgetsBinding.instance.addTimingsCallback` ➔ Verify P95 frame time < 8.33ms (120 FPS).
- [x] Verify Screen-Off CPU State: `dumpsys cpuinfo` ➔ Verify 0.0% CPU when screen turned off (`ACTION_SCREEN_OFF`).
- [x] Verify Memory Footprint: DevTools Memory ➔ Confirm Heap RAM < 55 MB with zero memory leaks across 20 tab switches.
- [x] Verify SQLite Seek Performance: `EXPLAIN QUERY PLAN` ➔ Verify 100% index seeks, < 2.5ms execution.

### 4.4 Full Test Execution & Walkthrough
- [x] Run full automated test suite: `flutter test` ➔ Verify **100% test pass rate** (62/62 tests passing).
- [x] Run static analysis: `flutter analyze` ➔ Verify **0 lint errors or warnings**.
- [x] Run Graphify update: `python3 -m graphify extract . --code-only` ➔ Update complete knowledge graph (1605 nodes, 2172 edges, 112 communities).
- [x] Create final `walkthrough.md` artifact detailing architecture, tests, and verification results.

---

## Phase 5: Production Hardening, Polish, Advanced Capabilities & Release Engineering

**Objective**: Complete advanced settings and data utilities, dual Wi-Fi FUP plan tracking, full localization coverage, extended test suites, R8 ProGuard hardening, root README, and complete verification gates.

### 5.1 Data Management & Backup in Settings (`APP_ARCHITECTURE_AND_SPECS.md`)
- [x] Implement CSV report export in `LocalDatabaseService` (`exportUsageDataAsCsv()`).
- [x] Implement historical cache clearing and SQLite database vacuuming (`clearHistoricalCache()`).
- [x] Expose export and cache management through `ISettingsRepository` and `SettingsRepositoryImpl`.
- [x] Create `lib/ui/features/settings/widgets/data_management_card.dart` with CSV copy-to-clipboard and confirmation dialogs.
- [x] Add Open Source Licenses viewer (`showLicensePage`) to `SettingsView`.

### 5.2 Wi-Fi Hotspot & FUP Quota Plan Tracking (`WIFI_USAGE_SPEC.md`)
- [x] Define Wi-Fi plan storage keys in `StorageKeys` and persistence in `LocalPreferencesService`.
- [x] Expose `getWifiPlan()` and `saveWifiPlan()` in `IPlanRepository` and `PlanRepositoryImpl`.
- [x] Add `PlanCategory` (Cellular vs Wi-Fi) segmented switching in `PlanViewModel` and `PlanView`.
- [x] Display Wi-Fi Hotspot / Broadband FUP contextual policy card when Wi-Fi plan is selected.

### 5.3 Complete Internationalization (`flutter-setup-localization`)
- [x] Expand `lib/l10n/app_en.arb` with complete string catalog covering all navigation tabs, metrics, dialogs, and filters.
- [x] Run `flutter gen-l10n` to compile strongly-typed getters in `AppLocalizations`.
- [x] Update `AdaptiveScaffold` to consume dynamic localized strings with fallback defaults.

### 5.4 Extended Automated Testing Suite (`dart-add-unit-test`, `flutter-add-widget-test`)
- [x] Create `test/unit/data/network_repository_impl_test.dart` (Testing device totals, time buckets, app usage, and error mapping).
- [x] Create `test/widget/features/history_view_test.dart` (Testing multi-timeframe chart switches, culprit cards, and insights grid).
- [x] Create `test/widget/features/settings_view_test.dart` (Testing status bar toggle, CSV export modal, and cache clear dialog).
- [x] Create `test/widget/core/speed_pulse_card_test.dart` (Testing idle state, live pulse, and bits/s display).

### 5.5 R8 / ProGuard Hardening & Documentation
- [x] Configure `android/app/proguard-rules.pro` to keep ByteFlow Kotlin models (`com.byteflow.model.**`), network handlers, and widget providers.
- [x] Create comprehensive root `README.md` with system architecture diagrams, benchmark comparisons, feature breakdown, and developer instructions.

### 🛡️ Phase 5 Verification Protocol
- [x] **Run Automated Tests**: `flutter test` ➔ Verify **100% test pass rate** across all 18 test suites.
- [x] **Run Static Analysis**: `flutter analyze` ➔ Verify **0 errors, 0 warnings, 0 lints**.
- [x] **Update Knowledge Graph**: `python3 -m graphify extract . --code-only` ➔ Refresh complete knowledge graph.
- [x] **Final Phase 5 Walkthrough**: Generate `walkthrough.md` artifact detailing Phase 5 accomplishments.

---

## Phase 6: Advanced System Interop, Background Quota Monitoring & Deep App Diagnostics

**Objective**: Extend Android native capabilities with boot recovery, high-priority quota notifications, direct application launching and system details interop, OEM task killer exemption defenses, and proactive quota monitoring.

### 6.1 Native Android Subsystem & OS Interop
- [x] Implement `android/app/src/main/kotlin/com/byteflow/service/BootCompletedReceiver.kt`:
  - [x] Automatic re-initialization of `LiveSpeedService` upon device boot if enabled.
  - [x] Immediate AppWidget synchronization on `ACTION_BOOT_COMPLETED`.
- [x] Implement `android/app/src/main/kotlin/com/byteflow/service/AlertNotificationHelper.kt`:
  - [x] Dedicated high-priority notification channel (`byteflow_alerts_channel`).
  - [x] Warning and critical quota limit alert banners with tap intent back into ByteFlow.
- [x] Update `android/app/src/main/AndroidManifest.xml`:
  - [x] Declare `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
  - [x] Register `BootCompletedReceiver` with `RECEIVE_BOOT_COMPLETED` filter.
- [x] Extend `android/app/src/main/kotlin/com/byteflow/network/NetworkChannelHandler.kt`:
  - [x] Method handlers: `launchApp`, `openAppDetails`, `isIgnoringBatteryOptimizations`, `requestIgnoreBatteryOptimizations`, `sendQuotaNotification`.

### 6.2 Platform Channel & Repository Expansion
- [x] Define platform constants in `lib/core/constants/channel_constants.dart` (`launchApp`, `openAppDetails`, `isIgnoringBatteryOptimizations`, `requestIgnoreBatteryOptimizations`, `sendQuotaNotification`).
- [x] Implement native bridges in `NativeNetworkService` with defensive platform exception handling.
- [x] Expand `INetworkRepository` and `NetworkRepositoryImpl`:
  - [x] `launchApp(String packageName)`
  - [x] `openAppDetails(String packageName)`
- [x] Expand `ISettingsRepository` and `SettingsRepositoryImpl`:
  - [x] `isIgnoringBatteryOptimizations()`
  - [x] `requestIgnoreBatteryOptimizations()`
  - [x] `sendQuotaNotification({required String title, required String body, required bool isWarning})`

### 6.3 Presentation Layer Deep Diagnostics & OEM Task Killer Defense
- [x] Upgrade `AppDetailsBottomSheet` in `lib/ui/features/app_usage/widgets/app_details_bottom_sheet.dart`:
  - [x] Deep interop actions: "Open App" and "App Info" buttons.
  - [x] High background usage alert banner highlighting anomalous consumption (> 30% background).
- [x] Upgrade `BatterySaverCard` in `lib/ui/features/settings/widgets/battery_saver_card.dart`:
  - [x] Visual status indicator for OEM task killer whitelist state ("Whitelisted" vs "Optimized").
  - [x] Direct exemption request CTA dispatching native system settings intent.
- [x] Update `SettingsViewModel` and `SettingsView` with live battery exemption state and request handlers.
- [x] Update `PlanViewModel` with automated quota threshold evaluation (80% warning and 100% critical alerts) via `ISettingsRepository`.

### 6.4 Verification & Testing Suite Expansion
- [x] Create `test/unit/data/app_interop_test.dart` (Testing app launch, app info, battery exemption, and notification platform dispatches).
- [x] Create `test/unit/domain/plan_alert_test.dart` (Testing plan quota threshold evaluation and alert dispatches).
- [x] Create `test/widget/features/app_details_bottom_sheet_test.dart` (Testing bottom sheet rendering, action buttons, and repository calls).
- [x] Create `test/widget/features/battery_saver_card_test.dart` (Testing battery exemption status chips and button callbacks).

### 🛡️ Phase 6 Verification Protocol
- [x] **Run Automated Tests**: `flutter test` ➔ Verify **100% test pass rate** (91/91 tests passing across 22 test suites).
- [x] **Run Static Analysis**: `flutter analyze` ➔ Verify **0 errors, 0 warnings, 0 lints**.
- [x] **Update Knowledge Graph**: `python3 -m graphify extract . --code-only` ➔ Refresh complete knowledge graph (1845 nodes, 2491 edges, 130 communities).
- [x] **Final Phase 6 Walkthrough**: Generate `walkthrough.md` artifact detailing Phase 6 accomplishments and architecture.


