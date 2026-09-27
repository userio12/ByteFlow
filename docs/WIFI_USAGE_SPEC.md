# ByteFlow — Wi-Fi Tracking & Analytics Specification

> **Governed by Official Flutter Agent Skills**:
> - [`flutter-apply-architecture-best-practices`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-apply-architecture-best-practices/SKILL.md)
> - [`flutter-build-responsive-layout`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-build-responsive-layout/SKILL.md)

This document details the architecture, native Android implementation, UI presentation, and features dedicated to **Wi-Fi Usage Tracking** in ByteFlow.

---

## 1. Native Android Wi-Fi Accounting

Android tracks Wi-Fi data at the kernel level using `ConnectivityManager.TYPE_WIFI` (or `NetworkCapabilities.TRANSPORT_WIFI`).

### 1.1 Device Total Wi-Fi Query
To query total Wi-Fi consumption for any time window `[startTime, endTime]`:

```kotlin
fun queryWifiDeviceTotal(
    context: Context,
    startTime: Long,
    endTime: Long
): Pair<Long, Long> {
    val nsm = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
    return try {
        // subscriberId is empty or null for Wi-Fi queries
        val bucket = nsm.querySummaryForDevice(
            ConnectivityManager.TYPE_WIFI,
            "",
            startTime,
            endTime
        )
        Pair(bucket.rxBytes, bucket.txBytes)
    } catch (e: Exception) {
        Pair(0L, 0L)
    }
}
```

### 1.2 Per-App Wi-Fi Breakdown & FG/BG Split
`querySummary` with `ConnectivityManager.TYPE_WIFI` yields exact Wi-Fi consumption for every application:

```kotlin
fun queryWifiAppsUsage(
    context: Context,
    startTime: Long,
    endTime: Long
): List<AppUsageRecord> {
    val nsm = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
    val pm = context.packageManager
    val stats = nsm.querySummary(ConnectivityManager.TYPE_WIFI, "", startTime, endTime)
    val bucket = NetworkStats.Bucket()
    val appMap = mutableMapOf<Int, AppUsageRecord>()

    while (stats.hasNextBucket()) {
        stats.getNextBucket(bucket)
        val uid = bucket.uid
        val record = appMap.getOrPut(uid) {
            val packages = pm.getPackagesForUid(uid)
            val packageName = packages?.firstOrNull() ?: "uid_$uid"
            val appName = try {
                val appInfo = pm.getApplicationInfo(packageName, 0)
                pm.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                packageName
            }
            AppUsageRecord(uid, packageName, appName)
        }

        val rx = bucket.rxBytes
        val tx = bucket.txBytes
        if (bucket.state == NetworkStats.Bucket.STATE_FOREGROUND) {
            record.foregroundRx += rx
            record.foregroundTx += tx
        } else {
            record.backgroundRx += rx
            record.backgroundTx += tx
        }
        record.totalRx += rx
        record.totalTx += tx
    }
    stats.close()
    return appMap.values.filter { (it.totalRx + it.totalTx) > 0 }.sortedByDescending { it.totalRx + it.totalTx }
}
```

---

## 2. Wi-Fi Features in ByteFlow

### 2.1 Dashboard Integration
- **Dedicated Wi-Fi Card**:
  - Displays total Wi-Fi data consumed Today (e.g. `1.82 GB`).
  - Breakdown into Download (`↓ 1.60 GB`) and Upload (`↑ 220 MB`).
- **Live Active Interface Indicator**:
  - The live speed card detects current connectivity: displays `[Wi-Fi Connected 📶]` or `[Cellular: SIM 1 📶]`.
  - When connected to Wi-Fi, live throughput reflects Wi-Fi speeds.

### 2.2 App Usage Detective (Wi-Fi Filter)
- **Network Toggle Chips**: `[All Networks]` | `[Mobile Only]` | `[Wi-Fi Only]`.
- Selecting **Wi-Fi Only** reveals:
  - Top Wi-Fi data hogs (e.g., Netflix, YouTube 4K streaming, Google Photos cloud backup, Play Store auto-updates).
  - Background Wi-Fi usage: Catch apps that upload gigabytes in the background while on Wi-Fi.

### 2.3 History & Multi-Timeframe Analytics (Zero-Static Data)
- **100% Dynamic Hardware Polling**: All Wi-Fi statistics are polled directly from Android's `NetworkStatsManager.querySummaryForDevice(ConnectivityManager.TYPE_WIFI)` with zero synthetic placeholders.
- **Multi-Timeframe Comparative Breakdown**:
  - **Today (Hourly 24h)**: 24-hour visual curve showing when Wi-Fi usage peaked throughout the day.
  - **Weekly (Past 7 Days)**: 7-day comparative stacked bars detailing daily Wi-Fi vs Cellular volumes.
  - **Monthly (Billing Cycle / 30D)**: Daily Wi-Fi trajectory and cumulative offload volume.
  - **Yearly (Past 12 Months)**: Annual Wi-Fi offload ratio (e.g. "84% of 1.2 TB total annual network traffic was offloaded to Wi-Fi").
- **Wi-Fi Offload Ratio**:
  - Calculated dynamically as: `(totalWifiBytes / (totalWifiBytes + totalMobileBytes)) * 100%`.
  - Displayed prominently in the Insights Grid.

### 2.4 Optional Metered Wi-Fi Plan (FUP Tracking)
- Many users use:
  - Pocket Wi-Fi / MiFi hotspots.
  - Mobile Hotspot from a secondary phone.
  - Home Broadband with Fair Usage Policies (e.g. 300 GB or 1 TB/month).
- **ByteFlow Feature**: Optional Wi-Fi Plan Tracker where users can set a monthly quota (e.g. 500 GB) with billing reset day and low-data warnings.

### 2.5 Status Bar & Notification
- The ongoing notification displays both cellular and Wi-Fi tallies side by side:
  - Title: `↓ 1.4 MB/s  ↑ 120 KB/s`
  - Subtext: `Wi-Fi Active`
  - Content: `Today: 420 MB Mobile • 2.1 GB Wi-Fi`
