# ByteFlow — Full Performance Optimization & 120 FPS Engineering Plan

> **Architectural Standard**: Senior Mobile Systems Architect Blueprint  
> **Skill Standard**: Official Google/Flutter Team Plugins ([`flutter-apply-architecture-best-practices`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-apply-architecture-best-practices/SKILL.md), [`flutter-build-responsive-layout`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-build-responsive-layout/SKILL.md), [`flutter-fix-layout-issues`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-fix-layout-issues/SKILL.md))  
> **Performance Targets**:
> - **Display Refresh Rate**: Locked 60/120 FPS (Frame budget: **< 8.33ms** on 120Hz displays, **< 16.6ms** on 60Hz displays).
> - **Battery Efficiency**: **0% CPU sleep** during screen-off; zero wake locks; negligible background battery drain (< 0.5% per 24 hours).
> - **Cold-Start Startup**: First Meaningful Paint (FMP) **< 200ms**.
> - **Memory Footprint**: Active foreground RAM **< 55 MB**; background service RAM **< 22 MB**.
> - **Database Latency**: 1-year multi-timeframe SQL rollups executed in **< 2.5ms**.

---

## 1. Performance Architecture Overview

High-performance mobile utilities fail when heavy computation, I/O, or continuous polling takes place on the UI thread. ByteFlow enforces strict **Thread Separation & Hardware Isolation**:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        THREAD SEPARATION MODEL                         │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   [Platform UI Thread]  ◄── 120Hz VSync (Gestures, Canvas Rendering)  │
│            ▲                                                           │
│            │ (Immutable State Updates via ListenableBuilder)           │
│            ▼                                                           │
│   [Dart Main Isolate]   ◄── ViewModels & Reactive Event Dispatch       │
│            ▲                                                           │
│            │ (compute() Background Worker Isolate)                     │
│            ▼                                                           │
│   [Dart Worker Isolate] ◄── Heavy App Sorting, Parsing & Filtering     │
│            ▲                                                           │
│            │ (MethodChannel IPC / Packed Primitives)                   │
│            ▼                                                           │
│   [Android IO Thread]   ◄── Dispatchers.IO (NetworkStatsManager)       │
│            ▲                                                           │
│            │ (Native WAL SQLite C-Engine)                              │
│            ▼                                                           │
│   [Storage / Disk I/O]  ◄── Pre-Aggregated Time-Series Rollup Tables   │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Flutter UI & 120 FPS Rendering Optimizations

### 2.1 Virtualized List Optimizations (`AppUsageView`)
Rendering hundreds of installed applications with icons and progress bars is the primary vector for dropped frames during fast fling scrolling. ByteFlow applies three critical optimizations:

```dart
// lib/ui/features/app_usage/views/app_usage_view.dart

ListView.builder(
  // 1. Mandatory fixed extent: Eliminates dynamic layout measurement passes
  itemExtent: 76.0,
  
  // 2. Controlled cache window: Pre-renders 300dp ahead for 0ms hitching
  cacheExtent: 300.0,
  
  // 3. Isolated repaint boundaries: Prevents an item repaint from invalidating neighbors
  addRepaintBoundaries: true,
  
  // 4. Memory retention: Destroys off-screen widgets to keep memory under 55MB
  addAutomaticKeepAlives: false,
  
  itemCount: viewModel.apps.length,
  itemBuilder: (context, index) {
    return AppUsageTile(app: viewModel.apps[index]);
  },
);
```

### 2.2 RepaintBoundary Isolation on High-Frequency Animations
The live speedometer halo (`PulseIndicator`) and circular plan progress ring (`RadialGauge`) repaint frequently. Without boundaries, canvas repaints propagate up the entire widget tree:

```dart
// lib/ui/features/dashboard/widgets/speed_pulse_card.dart

// Isolate pulsating halo into its own compositing layer
RepaintBoundary(
  child: PulseIndicator(
    speed: viewModel.currentSpeed,
  ),
)
```

### 2.3 Granular Widget Rebuilding (`ListenableBuilder`)
- Never use monolithic `setState()` at the page level.
- Utilize Flutter’s official `ListenableBuilder` scoped strictly to the smallest visual component needing updates.
- Keep the `NavigationBar`, static headers, and container surfaces completely outside the reactive rebuild scope.

### 2.4 Constant Subtree Caching (`const` Constructors)
- Every widget with static configurations is instantiated with `const`.
- Flutter compiler compiles these once into immutable canonical instances, bypassing the element reconciliation tree entirely during rebuilds.

---

## 3. Background Isolate Architecture (`compute()`)

Transforming 150+ raw Android app usage records, grouping foreground vs background bytes, calculating relative percentage widths, and sorting by usage is strictly offloaded from the main Dart isolate:

```dart
// lib/ui/features/app_usage/view_models/app_usage_view_model.dart

Future<void> filterAndSortApps({
  required TimeRange range,
  required NetworkType filter,
  required String searchQuery,
}) async {
  _isComputing = true;
  notifyListeners();

  // Offload heavy processing to dedicated background isolate
  final filtered = await compute(
    _processAppsIsolate,
    _ProcessAppsParams(
      rawApps: _allApps,
      range: range,
      filter: filter,
      query: searchQuery,
    ),
  );

  _displayedApps = filtered;
  _isComputing = false;
  notifyListeners();
}

// Pure top-level worker function executed in background isolate
List<AppUsageEntity> _processAppsIsolate(_ProcessAppsParams params) {
  var list = params.rawApps;
  
  if (params.query.isNotEmpty) {
    list = list.where((app) => 
      app.appName.toLowerCase().contains(params.query.toLowerCase()) ||
      app.packageName.toLowerCase().contains(params.query.toLowerCase())
    ).toList();
  }
  
  // Sort descending by total data
  list.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
  return list;
}
```

### 3.1 Debounced Search Engine
- Search input keystrokes are debounced by **150ms** using a lightweight timer.
- Prevents spawning competing background isolates for every individual character typed.

---

## 4. SQLite Database & Storage Optimization

### 4.1 Write-Ahead Logging (WAL) & Synchronous Settings
SQLite default configuration blocks readers while a write occurs. ByteFlow initializes SQLite in WAL mode:

```sql
-- Executed on database open:
PRAGMA journal_mode = WAL;          -- Concurrent reading while background writes occur
PRAGMA synchronous = NORMAL;        -- Eliminates redundant disk fsyncs while maintaining durability
PRAGMA temp_store = MEMORY;         -- In-memory temporary tables for faster sorting
PRAGMA cache_size = -4000;          -- 4MB database memory cache
```

### 4.2 Compound Indexing & Multi-Timeframe Seek Speeds
All time-series queries execute in `O(log N)` time through compound indices:

```sql
-- Fast hourly lookups for 24-hr spikes
CREATE INDEX idx_hourly_seek ON hourly_network_snapshots (timestamp_ms, network_type);

-- Unique index prevents duplicate daily insertions & accelerates 7-day/30-day range scans
CREATE UNIQUE INDEX idx_daily_rollup ON daily_network_snapshots (date_epoch_day, network_type, sub_id);

-- Instant 12-month annual lookups
CREATE UNIQUE INDEX idx_monthly_rollup ON monthly_network_snapshots (year, month, network_type, sub_id);
```

### 4.3 Automated Database Pruning & Vacuuming
- Raw hourly snapshots older than **60 days** are automatically pruned, as their aggregates are permanently preserved in `daily_network_snapshots`.
- Pruning runs once per week inside a low-priority background transaction, keeping database size strictly under **3.5 MB**.

---

## 5. Android Native Subsystem & Battery-Saver Engine

### 5.1 Screen-Aware Live Speed Indicator (0% CPU Sleep)
The live status bar speed meter pauses all timers and unregisters hardware polling when the display sleeps:

```kotlin
// android/app/src/main/kotlin/com/byteflow/service/ScreenReceiver.kt

class ScreenReceiver(private val service: LiveSpeedService) : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_SCREEN_OFF -> {
                // Completely halt polling timer loop: 0% CPU consumption
                service.pauseSpeedSampling()
            }
            Intent.ACTION_SCREEN_ON -> {
                // Capture fresh baseline snapshot and resume loop
                service.resumeSpeedSampling()
            }
        }
    }
}
```

### 5.2 Strict Zero-Wakelock Guarantee
- ByteFlow declares **zero wakelocks** (`PARTIAL_WAKE_LOCK` is banned from the Android Manifest).
- The device is permitted to enter full Android Doze mode and deep CPU sleep states unhindered.

### 5.3 Native App Icon LruCache (OOM Defense)
Loading 150+ raw Android app icons as uncompressed bitmaps into memory can trigger an Out-Of-Memory (OOM) crash. ByteFlow implements a native Kotlin memory cache with downsampling:

```kotlin
// android/app/src/main/kotlin/com/byteflow/network/IconCacheHelper.kt

object IconCacheHelper {
    // 8MB dedicated memory cache for app icons
    private val maxMemory = (Runtime.getRuntime().maxMemory() / 1024).toInt()
    private val cacheSize = maxMemory / 8

    private val memoryCache = object : LruCache<String, ByteArray>(cacheSize) {
        override fun sizeOf(key: String, value: ByteArray): Int {
            return value.size / 1024
        }
    }

    /**
     * Extracts, scales down to 48x48dp (96x96px), and compresses to WebP/PNG byte array.
     */
    fun getScaledIconBytes(pm: PackageManager, packageName: String): ByteArray? {
        memoryCache.get(packageName)?.let { return it }

        return try {
            val drawable = pm.getApplicationIcon(packageName)
            val bitmap = (drawable as? BitmapDrawable)?.bitmap ?: convertToBitmap(drawable)
            val scaled = Bitmap.createScaledBitmap(bitmap, 96, 96, true)
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.PNG, 85, stream)
            val bytes = stream.toByteArray()
            memoryCache.put(packageName, bytes)
            bytes
        } catch (e: Exception) {
            null
        }
    }
}
```

---

## 6. Cold-Start Startup Latency (< 200ms)

To achieve instantaneous launch:
1. **Deferred Non-Critical Work**:
   - The Flutter main entry point initializes only `WidgetsFlutterBinding` and essential shared preferences before calling `runApp()`.
   - SQLite cold-start backfill and heavy app icon loading are deferred until after the first frame completes:
     ```dart
     WidgetsBinding.instance.addPostFrameCallback((_) {
       // Run background cache initialization after first frame is painted
       context.read<DashboardViewModel>().initializeDeferredServices();
     });
     ```
2. **Splash Screen Alignment**:
   - Uses Android 12+ native splash screen (`SplashScreen API`) configured in `styles.xml` to prevent any white-screen flashes while the Flutter engine warms up.

---

## 7. Memory Leak Protections & Lifecycle Rules

1. **Subscription Disposal**:
   - All `StreamSubscription` instances (speed stream, connectivity changes) are cancelled in `dispose()`.
2. **Controller Cleanup**:
   - `AnimationController`, `TextEditingController`, and `ScrollController` are unconditionally disposed in their parent state objects.
3. **Image Cache Bounds**:
   - Dart image cache is capped to prevent memory retention:
     ```dart
     PaintingBinding.instance.imageCache.maximumSizeBytes = 30 * 1024 * 1024; // 30 MB cap
     ```

---

## 8. Continuous Performance Profiling & Verification Protocol

Every release build is evaluated against strict automated profiling gates:

| Metric | Target Threshold | Profiling Tool | Verification Gate |
| :--- | :--- | :--- | :--- |
| **UI Frame Rasterization** | < 8.33ms (P95) | Flutter DevTools Performance | Zero dropped frames during 120 FPS fling scroll |
| **Screen-Off CPU Usage** | 0.0% CPU | Android Studio Profiler / `dumpsys cpuinfo` | Battery drain curve completely flat during sleep |
| **Cold-Start Latency (FMP)**| < 200ms | Android `adb shell am start -W` | `TotalTime < 220ms` |
| **Heap Memory (RAM)** | < 55 MB | Flutter DevTools Memory / DevTools Allocation | Zero memory leaks across 20 tab switches |
| **SQL Query Time** | < 2.5ms | SQLite `EXPLAIN QUERY PLAN` | 100% index seeks, zero full table scans |
