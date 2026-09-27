# ByteFlow — Production Engineering & Architecture Specification (Senior Developer Blueprint)

This document outlines the **production-ready, enterprise-grade architecture** for ByteFlow, designed by senior mobile systems engineers to ensure rock-solid stability, zero memory leaks, sub-16ms frame budgets, OEM-resilient background services, and strict clean architecture layering.

---

## 1. Enterprise Clean Architecture Layering

ByteFlow adopts strict **Clean Architecture + Feature-Driven Layering** with unidirectional data flow (UDF):

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                              │
│   Widgets / Screens ──► Controllers / StateNotifiers ──► UI State      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ (Calls UseCases)
┌───────────────────────────────────▼────────────────────────────────────┐
│                           DOMAIN LAYER                                 │
│   UseCases (Pure Business Logic) ──► Repository Interfaces (Contracts) │
│   Entities & Value Objects ──► Failure & Exception Hierarchy           │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ (Implements Contracts)
┌───────────────────────────────────┴────────────────────────────────────┐
│                            DATA LAYER                                  │
│   Repository Implementations ──► Data Sources (Local DB / Platform IPC)│
│   DTOs & Serializers ──► Database DAO (SQLite Schema & Migrations)     │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ (Platform IPC)
┌───────────────────────────────────▼────────────────────────────────────┐
│                    NATIVE PLATFORM CHANNEL LAYER                       │
│   Kotlin NetworkStatsHelper ──► Kotlin Foreground Service & Notification│
│   TrafficStats Delta Engine ──► AppWidgetProvider RemoteViews          │
└────────────────────────────────────────────────────────────────────────┘
```

### 1.1 Layer Separation Rules
1. **Domain Layer has ZERO Flutter or External Dependencies**: It contains pure Dart entities, use cases, and abstract repository contracts.
2. **Data Layer Handles All Transformation & Serialization**: Converts raw native Maps/JSON into strongly-typed domain entities and encapsulates database transactions.
3. **Presentation Layer is Purely Reactive**: Widgets only listen to immutable UI states (`StateNotifier` / `ValueNotifier` / `ChangeNotifier`) and emit intents/events to controllers.
4. **Core Layer Houses Cross-Cutting Concerns**: Functional error handling (`Result<T, AppFailure>`), logging, formatters, and dependency injection.

---

## 2. Robust Domain Modeling & Error Handling (`Result<T, Failure>`)

Instead of throwing unhandled exceptions across the UI thread, ByteFlow enforces functional error handling via a `Result<T, AppFailure>` monad:

```dart
// core/errors/app_failure.dart
sealed class AppFailure {
  final String message;
  final StackTrace? stackTrace;
  const AppFailure(this.message, [this.stackTrace]);
}

class PermissionRevokedFailure extends AppFailure {
  final String requiredPermission;
  const PermissionRevokedFailure(this.requiredPermission, [super.stackTrace])
      : super('Required permission $requiredPermission was revoked.');
}

class PlatformChannelFailure extends AppFailure {
  final String code;
  const PlatformChannelFailure(this.code, super.message, [super.stackTrace]);
}

class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message, [super.stackTrace]);
}

// core/functional/result.dart
sealed class Result<S, F extends AppFailure> {
  const Result();
  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is Failure<S, F>;
  
  R when<R>({
    required R Function(S data) success,
    required R Function(F failure) failure,
  });
}

class Success<S, F extends AppFailure> extends Result<S, F> {
  final S data;
  const Success(this.data);
  @override
  R when<R>({required R Function(S data) success, required R Function(F failure) failure}) =>
      success(data);
}

class Failure<S, F extends AppFailure> extends Result<S, F> {
  final F error;
  const Failure(this.error);
  @override
  R when<R>({required R Function(S data) success, required R Function(F failure) failure}) =>
      failure(error);
}
```

---

## 3. High-Performance Time-Series Database Schema (SQLite)

Querying `NetworkStatsManager` across 500 installed apps repeatedly causes disk I/O lag and drops frames. Production ByteFlow implements a **Local SQLite Time-Series Cache** with indexes:

```sql
-- Schema Migration Version: 1
CREATE TABLE IF NOT EXISTS hourly_network_snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp_hour INTEGER NOT NULL,          -- Unix epoch truncated to hour (e.g. 1774656000000)
    network_type INTEGER NOT NULL,            -- 0 = Mobile, 1 = Wi-Fi
    carrier_name TEXT,                        -- e.g. "Jio 5G"
    rx_bytes INTEGER NOT NULL,
    tx_bytes INTEGER NOT NULL,
    created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_hourly_network_time 
ON hourly_network_snapshots (timestamp_hour, network_type);

CREATE TABLE IF NOT EXISTS app_usage_snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    snapshot_date INTEGER NOT NULL,           -- Unix epoch at 00:00:00 (Day bucket)
    package_name TEXT NOT NULL,
    app_name TEXT NOT NULL,
    uid INTEGER NOT NULL,
    network_type INTEGER NOT NULL,
    foreground_rx INTEGER NOT NULL DEFAULT 0,
    foreground_tx INTEGER NOT NULL DEFAULT 0,
    background_rx INTEGER NOT NULL DEFAULT 0,
    background_tx INTEGER NOT NULL DEFAULT 0,
    total_bytes INTEGER NOT NULL,
    icon_cached_uri TEXT
);

CREATE INDEX IF NOT EXISTS idx_app_usage_date_net 
ON app_usage_snapshots (snapshot_date, network_type);

ON app_usage_snapshots (total_bytes DESC);

-- Daily Rollup Table (Feeds Weekly 7-day and Monthly 30-day views)
CREATE TABLE IF NOT EXISTS daily_network_rollups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date_epoch_day INTEGER NOT NULL,          -- Days since Unix epoch
    date_string TEXT NOT NULL,                -- YYYY-MM-DD
    network_type INTEGER NOT NULL,            -- 0 = Mobile, 1 = Wi-Fi
    rx_bytes INTEGER NOT NULL,
    tx_bytes INTEGER NOT NULL,
    peak_hour INTEGER NOT NULL,               -- Hour index 0-23
    peak_bytes INTEGER NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_rollup_uniq 
ON daily_network_rollups (date_epoch_day, network_type);

-- Monthly Rollup Table (Feeds Yearly 12-month views)
CREATE TABLE IF NOT EXISTS monthly_network_rollups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    year INTEGER NOT NULL,                    -- e.g. 2026
    month INTEGER NOT NULL,                   -- 1 to 12
    network_type INTEGER NOT NULL,
    rx_bytes INTEGER NOT NULL,
    tx_bytes INTEGER NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_monthly_rollup_uniq 
ON monthly_network_rollups (year, month, network_type);
```

### 3.1 Zero-Static Data & Cold-Start Backfill Mandate
ByteFlow strictly forbids mock arrays, hardcoded JSON fallbacks, or synthetic chart placeholders. 
- On first launch, the app initiates `ColdStartBackfillService`, which queries Android's `NetworkStatsManager` backwards into OS kernel logs stored in `/data/system/netstats/`.
- This backfills the local SQLite database with genuine historical metrics (past 7 days, past 30 days, or past 12 months, according to system log retention).
- If system logs are unavailable (e.g. immediately after factory reset), ByteFlow displays genuine empty/permission states rather than fictional placeholder data.

### 3.2 Background Compute Isolate
When grouping and sorting hundreds of applications by usage, computation is offloaded to a background Dart isolate via `compute()` to prevent any UI thread hiccups:

```dart
Future<List<AppUsageEntity>> processAppsInBackground(List<Map<String, dynamic>> rawData) {
  return compute(_aggregateAndSortApps, rawData);
}

List<AppUsageEntity> _aggregateAndSortApps(List<Map<String, dynamic>> rawData) {
  // Heavy aggregation, icon decoding, and sorting happens off main thread
  return rawData.map(AppUsageDto.fromMap).map((dto) => dto.toEntity()).toList()
    ..sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
}
```

---

## 4. Production-Ready Platform Channel IPC Architecture

Instead of loose untyped strings, we define strict DTO serialization and bidirectional channel contracts.

### 4.1 Native Platform Channel Contracts
Channel Names:
- MethodChannel: `com.byteflow/network_v1`
- EventChannel: `com.byteflow/speed_stream_v1`

### 4.2 Safe IPC Execution Protocol
```kotlin
// android/app/src/main/kotlin/com/byteflow/network/NetworkChannelHandler.kt
class NetworkChannelHandler(
    private val context: Context,
    private val statsHelper: NetworkStatsHelper
) : MethodChannel.MethodCallHandler {

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceUsage" -> {
                val startTime = call.argument<Long>("startTime") ?: 0L
                val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                val netType = call.argument<Int>("networkType") ?: 0

                scope.launch {
                    try {
                        val usage = statsHelper.queryDeviceUsage(netType, startTime, endTime)
                        withContext(Dispatchers.Main) {
                            result.success(usage)
                        }
                    } catch (e: SecurityException) {
                        withContext(Dispatchers.Main) {
                            result.error("PERMISSION_DENIED", e.localizedMessage, null)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("QUERY_FAILED", e.localizedMessage, null)
                        }
                    }
                }
            }
            // ... other methods
        }
    }
}
```

---

## 5. Android Native Resilience & OEM Killer Defenses

Standard Android documentation assumes stock AOSP, but real-world Android devices (Xiaomi MIUI/HyperOS, Samsung OneUI, OnePlus OxygenOS, Oppo ColorOS) kill background services aggressively. Production ByteFlow implements:

1. **Foreground Service Crash Defenses (Android 14 API 34+)**:
   - Explicit declaration of `android:foregroundServiceType="dataSync"` in manifest.
   - Guarded invocation of `startForeground` with `ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC`.
   - Notification channel created with `IMPORTANCE_LOW` and `setShowBadge(false)` so status bar updates remain silent without triggering notification spam.
2. **Screen-Off Sensor Listener (`ACTION_SCREEN_OFF`)**:
   - Dynamically unregisters/stops `TrafficStats` delta sampling to guarantee **zero CPU cycles** in sleep mode.
3. **Runtime Permission Revocation Recovery**:
   - `AppOpsManager.checkOpNoThrow` evaluated before every hardware query. If the user revokes Usage Access in Settings, the app gracefully falls back to empty state with a 1-tap "Permission Reconnect" card rather than crashing.

---

## 6. Zero-Jank UI Rendering & Frame Budget (120 Hz Target)

For an app that handles live speedometer pulses and dense lists of apps:
1. **List Virtualization**: `ListView.builder` utilizes fixed `itemExtent: 76.0` to eliminate dynamic layout recalculations during rapid scrolling.
2. **Repaint Boundaries**: Wrap the live speedometer and pulsing glow in `RepaintBoundary` so that 1-second live speed ticks do NOT cause the entire screen or bottom navigation bar to repaint.
3. **Animated Numbers with ValueNotifier**: Avoid full widget rebuilds (`setState`) for live speed tickers; use targeted `ValueListenableBuilder<SpeedSample>` scoped strictly to the speed badge.

---

## 7. Testing Strategy & CI/CD Verification

| Test Type | Scope | Target Coverage |
| :--- | :--- | :--- |
| **Unit Tests** | Domain UseCases, Date/Cycle Math, ByteFormatter, Result Monad | **> 90%** |
| **Repository Tests** | Mocked Platform Channel via `TestDefaultBinaryMessengerBinding` | **100%** |
| **State Tests** | Controller/Provider state transitions (Loading ➔ Data ➔ Error) | **> 85%** |
| **Widget Tests** | Gauge rendering, filter toggles, search debouncing | Key flows |
| **Lint & Static Analysis** | `flutter analyze` with 0 warnings, deprecation-free | **100%** |

---

## 8. Directory & Package Structure (Clean Architecture Blueprint)

```
lib/
├── core/
│   ├── errors/               # AppFailure, Exception mappings
│   ├── functional/           # Result<S, F> monad
│   ├── theme/                # Material 3 tokens, dynamic Monet palette
│   └── utils/                # ByteFormatter, DateUtils, PlatformUtils
├── domain/
│   ├── entities/             # AppUsage, NetworkSummary, DataPlan, SimInfo
│   ├── repositories/         # INetworkRepository, IPlanRepository, ISettingsRepository
│   └── usecases/             # GetTodayUsageUseCase, GetAppBreakdownUseCase, GetHourlySpikesUseCase
├── data/
│   ├── datasources/
│   │   ├── native_channel_datasource.dart   # MethodChannel & EventChannel implementation
│   │   └── local_database_datasource.dart   # SQLite database & queries
│   ├── dtos/                 # AppUsageDto, NetworkSummaryDto, SimInfoDto
│   └── repositories/         # NetworkRepositoryImpl, PlanRepositoryImpl
└── presentation/
    ├── controllers/          # DashboardController, AppsController, HistoryController, PlanController
    ├── screens/              # DashboardView, AppsView, HistoryView, PlanView, SettingsView, OnboardingView
    └── widgets/              # RadialGauge, SpeedPulseCard, AppUsageItem, StackedHistoryChart
```

---

## 9. Official Flutter Agent Skills Integration (`.agents/skills`)

The project is configured with the official **Flutter Agent Plugins** (`https://github.com/flutter/agent-plugins.git`) installed in `.agents/skills/` and `.agents/rules/`:

| Official Skill | Scope & Enforced Standard |
| :--- | :--- |
| **`flutter-apply-architecture-best-practices`** | Enforces MVVM in Presentation, Repository pattern in Data layer, and optional UseCases in Domain. Separates concerns strictly so Views are dumb widgets driven by `ListenableBuilder` / `ViewModel`. |
| **`flutter-build-responsive-layout`** | Mandates `MediaQuery.sizeOf(context)` over `MediaQuery.of(context)` for targeted rebuilds, `LayoutBuilder` with adaptive breakpoints (`> 600dp` for tablets/foldables), and `ConstrainedBox(maxWidth: 800)` to prevent horizontal stretching. |
| **`flutter-add-widget-test`** | Guides component testing for ViewModels and Views with proper pump and pumpAndSettle cycles. |
| **`dart-add-unit-test`** | Mandates pure Dart test suites for all UseCases, Repositories, and Date/Cycle calculation algorithms. |
| **`flutter-implement-json-serialization`** | Enforces immutable DTOs with pattern-matched serialization and primary constructors. |
| **`flutter-setup-localization`** | Standardizes internationalization via `l10n.yaml` and `lib/l10n/*.arb` templates. |
| **`flutter-hot-reload` (Rule)** | Ensures ViewModels avoid static states and closures that break state preservation during development. |

