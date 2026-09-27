# ByteFlow — Dynamic Data Pipeline & Multi-Timeframe Analytics Specification

> **Architectural Standard**: Senior Mobile Systems Architect Blueprint  
> **Skill Standard**: Official Google/Flutter Team Plugins ([`flutter-apply-architecture-best-practices`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-apply-architecture-best-practices/SKILL.md), [`dart-use-pattern-matching`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/dart-use-pattern-matching/SKILL.md))  
> **Zero-Static Data Mandate**: 100% of statistics, metrics, app usage entries, carrier names, and chart data points are dynamically polled from live Android hardware accounting and persisted time-series snapshots. Hardcoded mocks or synthetic placeholders are strictly prohibited in production paths.

---

## 1. Zero-Static Data Guarantee & Data Source Hierarchy

ByteFlow operates exclusively on **live device hardware metrics** and **real system telemetry**. If permissions are absent or data has not yet accumulated, the app renders standard Material 3 empty/loading/permission-rationale states rather than fabricating synthetic data points.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        DATA SOURCE HIERARCHY                           │
└────────────────────────────────────────────────────────────────────────┘
                                 │
         ┌───────────────────────┴───────────────────────┐
         ▼                                               ▼
┌──────────────────────────────┐              ┌──────────────────────────────┐
│     REAL-TIME / LIVE         │              │    HISTORICAL AGGREGATES     │
│   (Sub-second to Minutes)    │              │  (Hourly / Weekly / Monthly) │
├──────────────────────────────┤              ├──────────────────────────────┤
│ • Linux Kernel TrafficStats  │              │ • Android NetworkStatsManager│
│   (/proc/net/dev delta)      │              │   (Kernel iptables accounting)│
│ • SubscriptionManager        │              │ • Android PackageManager     │
│   (Hardware SIM slot & ICCID)│              │   (Live installed apps/icons)│
│ • ConnectivityManager        │              │ • SQLite Time-Series DB      │
│   (Active NetworkCapabilities)│             │   (Local encrypted rollups)  │
└──────────────────────────────┘              └──────────────────────────────┘
```

---

## 2. Multi-Timeframe Aggregation Engine (`TimeRange`)

To provide actionable insights across both microscopic spikes and macroscopic billing cycles, ByteFlow dynamically segments and aggregates network data into four standardized time resolutions:

| Time Range | Interval Window | Native Query Strategy | Visual Representation | Key Metric |
| :--- | :--- | :--- | :--- | :--- |
| **Today / Hourly** | `00:00:00` to Current Minute | Kernel `queryDetails` + SQLite Hourly Snapshots | 24 hourly bars (`00:00`–`23:00`) with peak spike badge | Sudden burst identification & culprit app |
| **Weekly** | Past 7 Rolling Days (`D-6` to `Today`) | SQLite Daily Rollup + Kernel `querySummary` | 7 grouped vertical bars (Mon–Sun or rolling dates) | Day-over-day burn rate & Wi-Fi offload % |
| **Monthly** | Current Billing Cycle or Calendar Month (1st to 28th/31st) | SQLite Daily Rollup + Kernel `querySummaryForDevice` | 28–31 day line/bar chart with cumulative quota trajectory | Projected quota exhaustion date & daily budget pace |
| **Yearly** | Past 12 Months (`M-11` to `Current Month`) | SQLite Monthly Rollup + Kernel historical cache | 12 monthly stacked bars (Jan–Dec) | Seasonal trends, annual carrier spend, and total GB consumed |

---

## 3. Native Android Accounting Engine (Kotlin Subsystem)

### 3.1 Kernel Multi-Timeframe Querying via `NetworkStatsManager`

The Android Linux kernel records hardware socket traffic inside `xt_qtaguid` and `netfilter`. `NetworkStatsManager` provides access to these hardware tables without running battery-draining VPN services. 

ByteFlow's Kotlin native helper exposes arbitrary epoch millisecond time windows (`startTimeEpochMs` to `endTimeEpochMs`), enabling dynamic aggregation for any time window:

```kotlin
// android/app/src/main/kotlin/com/byteflow/network/NetworkStatsHelper.kt

package com.byteflow.network

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.net.ConnectivityManager
import com.byteflow.model.AppUsageRecord
import com.byteflow.model.NetworkTotalRecord
import com.byteflow.model.UsageBucketRecord

class NetworkStatsHelper(private val context: Context) {
    private val networkStatsManager = 
        context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager

    /**
     * Dynamically queries device-level mobile or Wi-Fi totals for ANY arbitrary window.
     * Works for: Today, Weekly (past 7 days), Monthly (past 30 days), Yearly (past 365 days).
     */
    fun queryDeviceTotal(
        networkType: Int, // ConnectivityManager.TYPE_MOBILE or TYPE_WIFI
        startTimeMs: Long,
        endTimeMs: Long
    ): NetworkTotalRecord {
        return try {
            val bucket = networkStatsManager.querySummaryForDevice(
                networkType,
                null, // null queries all cellular interfaces on modern Android 10+
                startTimeMs,
                endTimeMs
            )
            NetworkTotalRecord(
                rxBytes = bucket.rxBytes,
                txBytes = bucket.txBytes,
                startTimeMs = startTimeMs,
                endTimeMs = endTimeMs
            )
        } catch (e: Exception) {
            NetworkTotalRecord(0L, 0L, startTimeMs, endTimeMs)
        }
    }

    /**
     * Dynamically queries per-app UID usage across the requested timeframe.
     * Iterates through kernel buckets and groups foreground vs background bytes.
     */
    fun queryAppsUsage(
        networkType: Int,
        startTimeMs: Long,
        endTimeMs: Long
    ): List<AppUsageRecord> {
        val appMap = mutableMapOf<Int, AppUsageRecord>()
        val pm = context.packageManager

        try {
            val stats = networkStatsManager.querySummary(
                networkType,
                null,
                startTimeMs,
                endTimeMs
            )
            val bucket = NetworkStats.Bucket()

            while (stats.hasNextBucket()) {
                stats.getNextBucket(bucket)
                val uid = bucket.uid
                if (uid < 1000) continue // Exclude low-level OS daemons or map to Android OS

                val existing = appMap.getOrPut(uid) {
                    val packageNames = pm.getPackagesForUid(uid)
                    val pkg = packageNames?.firstOrNull() ?: "uid_$uid"
                    val appName = try {
                        val info = pm.getApplicationInfo(pkg, 0)
                        pm.getApplicationLabel(info).toString()
                    } catch (e: Exception) {
                        pkg
                    }
                    AppUsageRecord(
                        uid = uid,
                        packageName = pkg,
                        appName = appName,
                        rxBytes = 0L,
                        txBytes = 0L,
                        fgRxBytes = 0L,
                        fgTxBytes = 0L,
                        bgRxBytes = 0L,
                        bgTxBytes = 0L
                    )
                }

                val rx = bucket.rxBytes
                val tx = bucket.txBytes
                val isForeground = (bucket.state == NetworkStats.Bucket.STATE_FOREGROUND)

                appMap[uid] = existing.copy(
                    rxBytes = existing.rxBytes + rx,
                    txBytes = existing.txBytes + tx,
                    fgRxBytes = existing.fgRxBytes + if (isForeground) rx else 0L,
                    fgTxBytes = existing.fgTxBytes + if (isForeground) tx else 0L,
                    bgRxBytes = existing.bgRxBytes + if (!isForeground) rx else 0L,
                    bgTxBytes = existing.bgTxBytes + if (!isForeground) tx else 0L
                )
            }
            stats.close()
        } catch (e: Exception) {
            return emptyList()
        }

        return appMap.values.sortedByDescending { it.rxBytes + it.txBytes }
    }

    /**
     * Dynamically slices a timeframe into discrete buckets (e.g. 24 hourly buckets for Today,
     * 7 daily buckets for Week, 30 daily buckets for Month, 12 monthly buckets for Year).
     */
    fun queryTimeBuckets(
        networkType: Int,
        startTimeMs: Long,
        endTimeMs: Long,
        stepIntervalMs: Long
    ): List<UsageBucketRecord> {
        val buckets = mutableListOf<UsageBucketRecord>()
        var currentStart = startTimeMs

        while (currentStart < endTimeMs) {
            val currentEnd = minOf(currentStart + stepIntervalMs, endTimeMs)
            val total = queryDeviceTotal(networkType, currentStart, currentEnd)
            buckets.add(
                UsageBucketRecord(
                    startTimeMs = currentStart,
                    endTimeMs = currentEnd,
                    rxBytes = total.rxBytes,
                    txBytes = total.txBytes
                )
            )
            currentStart = currentEnd
        }

        return buckets
    }
}
```

### 3.2 Cold-Start Historical Backfill (Zero Synthetic Placeholders)

On initial installation, third-party apps usually start with an empty database. However, Android OS maintains its own internal kernel logs in `/data/system/netstats/` for days or months depending on the OEM.

ByteFlow executes a **Cold-Start Backfill Routine**:
1. Checks if SQLite local time-series records exist for the past 7 days, 30 days, or 12 months.
2. If empty, it invokes `NetworkStatsHelper.queryDeviceTotal` and `queryTimeBuckets` backwards into the OS kernel tables.
3. Automatically populates `daily_network_snapshots` and `monthly_network_snapshots` with **real historical usage data** recorded by Android prior to ByteFlow's installation.
4. If the device was factory reset or OEM storage only retains 30 days, ByteFlow renders genuine recorded days with zero synthetic interpolations.

---

## 4. SQLite Time-Series Database Schema & Dynamic Aggregations

To ensure instant UI rendering (sub-16ms frame budget) without blocking the platform channel on repeated heavy kernel traversals, ByteFlow persists atomic measurements into a high-performance local SQLite database (`sqflite`).

### 4.1 Schema DDL

```sql
-- Hourly snapshots (Retained for 60 days, feeds Today & Weekly granular views)
CREATE TABLE hourly_network_snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp_ms INTEGER NOT NULL,
    hour_of_day INTEGER NOT NULL, -- 0 to 23
    network_type INTEGER NOT NULL, -- 0: Mobile, 1: Wi-Fi
    sub_id INTEGER DEFAULT -1,    -- SIM Subscription ID
    rx_bytes INTEGER NOT NULL,
    tx_bytes INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_hourly_lookup ON hourly_network_snapshots(timestamp_ms, network_type);

-- Daily rollups (Retained indefinitely, feeds Weekly & Monthly views)
CREATE TABLE daily_network_snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date_epoch_day INTEGER NOT NULL, -- Days since Unix epoch (timestamp / 86400000)
    date_string TEXT NOT NULL,       -- 'YYYY-MM-DD'
    network_type INTEGER NOT NULL,
    sub_id INTEGER DEFAULT -1,
    rx_bytes INTEGER NOT NULL,
    tx_bytes INTEGER NOT NULL,
    peak_hour INTEGER NOT NULL,      -- Hour index (0-23) with maximum throughput
    peak_bytes INTEGER NOT NULL
);

CREATE UNIQUE INDEX idx_daily_unique ON daily_network_snapshots(date_epoch_day, network_type, sub_id);

-- Monthly rollups (Retained indefinitely, feeds Yearly multi-year analytics)
CREATE TABLE monthly_network_snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    year INTEGER NOT NULL,           -- e.g. 2026
    month INTEGER NOT NULL,          -- 1 to 12
    network_type INTEGER NOT NULL,
    sub_id INTEGER DEFAULT -1,
    rx_bytes INTEGER NOT NULL,
    tx_bytes INTEGER NOT NULL
);

CREATE UNIQUE INDEX idx_monthly_unique ON monthly_network_snapshots(year, month, network_type, sub_id);

-- Daily App Usage Breakdowns
CREATE TABLE daily_app_snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date_epoch_day INTEGER NOT NULL,
    uid INTEGER NOT NULL,
    package_name TEXT NOT NULL,
    app_name TEXT NOT NULL,
    network_type INTEGER NOT NULL,
    rx_bytes INTEGER NOT NULL,
    tx_bytes INTEGER NOT NULL,
    fg_rx_bytes INTEGER NOT NULL,
    fg_tx_bytes INTEGER NOT NULL,
    bg_rx_bytes INTEGER NOT NULL,
    bg_tx_bytes INTEGER NOT NULL
);

CREATE INDEX idx_app_lookup ON daily_app_snapshots(date_epoch_day, network_type);
```

### 4.2 Dynamic SQL Aggregation Queries

```sql
-- DYNAMIC WEEKLY AGGREGATION (Past 7 days grouped by date)
SELECT 
    date_string,
    SUM(CASE WHEN network_type = 0 THEN rx_bytes + tx_bytes ELSE 0 END) AS mobile_bytes,
    SUM(CASE WHEN network_type = 1 THEN rx_bytes + tx_bytes ELSE 0 END) AS wifi_bytes
FROM daily_network_snapshots
WHERE date_epoch_day >= :sevenDaysAgoEpochDay
GROUP BY date_epoch_day, date_string
ORDER BY date_epoch_day ASC;

-- DYNAMIC MONTHLY AGGREGATION (Days 1 to 31 for Current Billing Cycle)
SELECT 
    date_string,
    SUM(CASE WHEN network_type = 0 THEN rx_bytes + tx_bytes ELSE 0 END) AS mobile_bytes,
    SUM(CASE WHEN network_type = 1 THEN rx_bytes + tx_bytes ELSE 0 END) AS wifi_bytes
FROM daily_network_snapshots
WHERE date_epoch_day BETWEEN :cycleStartDay AND :cycleEndDay
GROUP BY date_epoch_day, date_string
ORDER BY date_epoch_day ASC;

-- DYNAMIC YEARLY AGGREGATION (12 Months of Year)
SELECT 
    year,
    month,
    SUM(CASE WHEN network_type = 0 THEN rx_bytes + tx_bytes ELSE 0 END) AS mobile_bytes,
    SUM(CASE WHEN network_type = 1 THEN rx_bytes + tx_bytes ELSE 0 END) AS wifi_bytes
FROM monthly_network_snapshots
WHERE (year = :currentYear) OR (year = :currentYear - 1 AND month > :currentMonth)
GROUP BY year, month
ORDER BY year ASC, month ASC;
```

---

## 5. Domain Layer Architecture & Time Range Modeling

### 5.1 `TimeRange` Enumeration & Date Math Utilities

```dart
// lib/domain/models/time_range.dart

enum TimeRange {
  today,
  week,
  month,
  year;

  String get displayName {
    return switch (this) {
      TimeRange.today => 'Today',
      TimeRange.week => 'Weekly',
      TimeRange.month => 'Monthly',
      TimeRange.year => 'Yearly',
    };
  }

  /// Calculates the exact start and end DateTime boundaries for this time range.
  DateTimeRange calculateBounds({int billingCycleResetDay = 1}) {
    final now = DateTime.now();
    return switch (this) {
      TimeRange.today => DateTimeRange(
          start: DateTime(now.year, now.month, now.day, 0, 0, 0),
          end: now,
        ),
      TimeRange.week => DateTimeRange(
          start: DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 6)),
          end: now,
        ),
      TimeRange.month => _calculateBillingCycleBounds(now, billingCycleResetDay),
      TimeRange.year => DateTimeRange(
          start: DateTime(now.year - 1, now.month + 1, 1),
          end: now,
        ),
    };
  }

  static DateTimeRange _calculateBillingCycleBounds(DateTime now, int resetDay) {
    final DateTime cycleStart;
    final DateTime cycleEnd;

    if (now.day >= resetDay) {
      cycleStart = DateTime(now.year, now.month, resetDay);
      // Next cycle starts next month on resetDay
      cycleEnd = DateTime(now.year, now.month + 1, resetDay)
          .subtract(const Duration(seconds: 1));
    } else {
      // Current cycle started last month
      cycleStart = DateTime(now.year, now.month - 1, resetDay);
      cycleEnd = DateTime(now.year, now.month, resetDay)
          .subtract(const Duration(seconds: 1));
    }

    return DateTimeRange(start: cycleStart, end: now.isBefore(cycleEnd) ? now : cycleEnd);
  }
}
```

### 5.2 Immutable Domain Entities

```dart
// lib/domain/models/usage_time_bucket.dart

class UsageTimeBucket {
  final DateTime startTime;
  final DateTime endTime;
  final String label; // e.g., '14:00', 'Tue', 'Day 12', 'Aug'
  final int mobileRxBytes;
  final int mobileTxBytes;
  final int wifiRxBytes;
  final int wifiTxBytes;

  const UsageTimeBucket({
    required this.startTime,
    required this.endTime,
    required this.label,
    required this.mobileRxBytes,
    required this.mobileTxBytes,
    required this.wifiRxBytes,
    required this.wifiTxBytes,
  });

  int get totalMobileBytes => mobileRxBytes + mobileTxBytes;
  int get totalWifiBytes => wifiRxBytes + wifiTxBytes;
  int get totalBytes => totalMobileBytes + totalWifiBytes;
}

// lib/domain/models/historical_summary_entity.dart

class HistoricalSummaryEntity {
  final TimeRange range;
  final DateTimeRange dateBounds;
  final int totalMobileBytes;
  final int totalWifiBytes;
  final List<UsageTimeBucket> buckets;
  final List<AppUsageEntity> topApps;
  final double averageDailyBytes;
  final UsageTimeBucket? peakBucket;

  const HistoricalSummaryEntity({
    required this.range,
    required this.dateBounds,
    required this.totalMobileBytes,
    required this.totalWifiBytes,
    required this.buckets,
    required this.topApps,
    required this.averageDailyBytes,
    this.peakBucket,
  });

  double get wifiOffloadPercentage {
    final total = totalMobileBytes + totalWifiBytes;
    if (total == 0) return 0.0;
    return (totalWifiBytes / total) * 100.0;
  }
}
```

---

## 6. Presentation Layer & UI Behavior (Adaptive Visualizations)

Across the **Dashboard**, **App Detective**, and **History & Spikes** screens, a unified Material 3 `SegmentedButton<TimeRange>` or row of FilterChips empowers users to toggle between **Today**, **Weekly**, **Monthly**, and **Yearly** views dynamically:

```
┌────────────────────────────────────────────────────────┐
│  [ Today ]     [ Weekly ]     [ Monthly ]    [ Yearly ]│
└────────────────────────────────────────────────────────┘
```

### 6.1 Chart Adaptation Strategy (`fl_chart`)

1. **Today (`TimeRange.today`)**:
   - **X-Axis**: 24 discrete hour markers (`0h`, `4h`, `8h`, `12h`, `16h`, `20h`, `23h`).
   - **Type**: Interactive BarChart with individual hourly columns.
   - **Action**: Tapping an hour displays a BottomSheet identifying the culprit app that generated that specific spike.

2. **Weekly (`TimeRange.week`)**:
   - **X-Axis**: 7 day labels (`Mon`, `Tue`, `Wed`, `Thu`, `Fri`, `Sat`, `Sun`).
   - **Type**: Grouped side-by-side or stacked BarChart comparing Cellular (Primary Monet Color) vs Wi-Fi (Secondary Surface Container).
   - **Insights**: Displays average daily consumption and identifies the heaviest usage day of the week.

3. **Monthly (`TimeRange.month`)**:
   - **X-Axis**: Days of billing cycle (`1`, `5`, `10`, `15`, `20`, `25`, `30`).
   - **Type**: Smooth curved LineChart with dual lines:
     - Solid Line: Actual recorded cumulative consumption.
     - Dotted Line: Ideal linear quota pace (Quota / Total Cycle Days × Current Day).
   - **Alert**: Renders warning pill if current trajectory projects early quota exhaustion.

4. **Yearly (`TimeRange.year`)**:
   - **X-Axis**: 12 month labels (`Jan`, `Feb`, `Mar`, `Apr`, `May`, `Jun`, `Jul`, `Aug`, `Sep`, `Oct`, `Nov`, `Dec`).
   - **Type**: High-level BarChart showing annual cellular vs Wi-Fi distribution.
   - **Insights**: Displays year-to-date total data offloaded to Wi-Fi vs billed cellular data.

---

## 7. Performance & Threading Protections

1. **Isolate Computations (`compute()`)**:
   - Transforming 365 days of raw bucket records or sorting 150+ installed apps by usage across a 1-year window is strictly offloaded to a background Dart isolate via Flutter's `compute(parseAppBreakdown, rawMap)`. The main UI thread never drops below 60/120 fps.
2. **Debounced Range Switching**:
   - User switching rapidly between `Today -> Week -> Month -> Year` triggers a 150ms debounce before dispatching database queries to avoid UI thread thrashing.
3. **Reactive State Retention**:
   - Historical query results are cached in ViewModel state so revisiting an already-loaded range provides instantaneous rendering.
