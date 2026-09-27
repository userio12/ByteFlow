# ByteFlow — Android Native Subsystem Specification

> **Platform IPC Bridge Governed by**:
> - [`flutter-apply-architecture-best-practices`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-apply-architecture-best-practices/SKILL.md) (Stateless Native Service layer)
> - [`flutter-implement-json-serialization`](file:///storage/emulated/0/AndroidPEProjects/ByteFlow/.agents/skills/flutter-implement-json-serialization/SKILL.md) (Type-safe DTO marshaling)

This document details the native Android layer (Kotlin) responsible for querying hardware statistics, managing multi-SIM subscriptions, hosting the live speed foreground service, and rendering the home screen widget.

---

## 1. NetworkStatsManager Implementation

Android's `NetworkStatsManager` (API 23+) provides aggregated and bucketed network accounting data.

### 1.1 Permission & Verification
To access `NetworkStatsManager`, the user must grant **Usage Access** (`android.permission.PACKAGE_USAGE_STATS`).

```kotlin
fun hasUsageStatsPermission(context: Context): Boolean {
    val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
    val mode = appOps.checkOpNoThrow(
        AppOpsManager.OPSTR_GET_USAGE_STATS,
        android.os.Process.myUid(),
        context.packageName
    )
    return mode == AppOpsManager.MODE_ALLOWED
}

fun openUsageAccessSettings(context: Context) {
    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
        data = Uri.parse("package:${context.packageName}")
        flags = Intent.FLAG_ACTIVITY_NEW_TASK
    }
    context.startActivity(intent)
}
```

### 1.2 Querying Device Totals (Mobile & Wi-Fi)
Total device usage for a given time window `[startTime, endTime]` is queried via `querySummaryForDevice`:

```kotlin
fun queryDeviceTotal(
    context: Context,
    networkType: Int, // ConnectivityManager.TYPE_MOBILE or TYPE_WIFI
    startTime: Long,
    endTime: Long
): Pair<Long, Long> {
    val nsm = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
    return try {
        // In Android 10+ (API 29+), subscriberId is null for general mobile queries
        val bucket = nsm.querySummaryForDevice(networkType, null, startTime, endTime)
        Pair(bucket.rxBytes, bucket.txBytes)
    } catch (e: Exception) {
        Pair(0L, 0L)
    }
}
```

### 1.3 Querying Per-App Usage & Foreground/Background Split
Using `querySummary`, buckets across all UIDs are aggregated:

```kotlin
fun queryAppsUsage(
    context: Context,
    networkType: Int,
    startTime: Long,
    endTime: Long
): List<AppUsageRecord> {
    val nsm = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
    val pm = context.packageManager
    val stats = nsm.querySummary(networkType, null, startTime, endTime)
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

/**
 * 1.4 Slicing Time Series into Discrete Buckets (Today/Week/Month/Year)
 * Queries discrete time buckets across any arbitrary time window.
 */
fun queryTimeBuckets(
    context: Context,
    networkType: Int,
    startTime: Long,
    endTime: Long,
    stepIntervalMs: Long
): List<Map<String, Any>> {
    val buckets = mutableListOf<Map<String, Any>>()
    var cur = startTime
    while (cur < endTime) {
        val next = minOf(cur + stepIntervalMs, endTime)
        val (rx, tx) = queryDeviceTotal(context, networkType, cur, next)
        buckets.add(
            mapOf(
                "startTimeMs" to cur,
                "endTimeMs" to next,
                "rxBytes" to rx,
                "txBytes" to tx
            )
        )
        cur = next
    }
    return buckets
}
```

---

## 2. Multi-SIM Support (SubscriptionManager)

Dual-SIM and multi-SIM devices are tracked via Android's `SubscriptionManager` (API 22+).

### 2.1 Information Retrieved
- `subId`: Android Subscription ID (unique per active SIM).
- `slotIndex`: Physical or eSIM slot (0 = SIM 1, 1 = SIM 2).
- `displayName`: User or carrier defined display name (e.g. "Personal", "Work").
- `carrierName`: Detected network operator (e.g. "Jio", "Airtel", "T-Mobile", "Verizon").
- `countryIso`: Country code of the SIM.
- `isDataRoaming`: Whether roaming is active.
- `isDefaultDataSub`: Whether this subscription is currently set as the primary data SIM (`SubscriptionManager.getDefaultDataSubscriptionId()`).

### 2.2 Permissions
- `android.permission.READ_PHONE_STATE`

---

## 3. Live Speed Service (Foreground Service)

### 3.1 Live Throughput Computation
Real-time download and upload speeds are computed using the delta of `TrafficStats.getTotalRxBytes()` and `TrafficStats.getTotalTxBytes()` across a periodic sampling interval:

$$\text{Speed (Bytes/s)} = \frac{\Delta \text{Bytes}}{\Delta \text{Time (seconds)}}$$

### 3.2 Battery-Saving Screen Lifecycle
```kotlin
class LiveSpeedService : Service() {
    private var isScreenOn = true
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    isScreenOn = false
                    stopSampling()
                }
                Intent.ACTION_SCREEN_ON -> {
                    isScreenOn = true
                    resetBaseline()
                    startSampling()
                }
            }
        }
    }
}
```

### 3.3 Ongoing Status Bar Notification
- **Channel**: `byteflow_live_speed`
- **Importance**: `NotificationManager.IMPORTANCE_LOW` (silent, does not alert or vibrate on every second).
- **Title**: `↓ 2.4 MB/s  ↑ 180 KB/s`
- **Text**: `Today: 420 MB Mobile • 1.8 GB Wi-Fi`
- **SubText**: Active SIM Carrier (e.g., `SIM 1: Jio 5G`)
- **Category**: `NotificationCompat.CATEGORY_STATUS`

---

## 4. Material 3 Home Screen Widget (AppWidgetProvider)

### 4.1 Widget Layout (`widget_byteflow.xml`)
The widget uses standard RemoteViews formatted according to Material 3 guidelines:
- Surface container with rounded corners (using `@drawable/widget_background`).
- Displays:
  1. Active Carrier Name & SIM Badge.
  2. Mobile Data consumed today vs Plan Quota.
  3. Visual progress bar showing % of quota used.
  4. Today's Wi-Fi usage metric.
  5. Tap target: PendingIntent launching `MainActivity`.

### 4.2 Widget Lifecycle
- `onUpdate`: Pulls cached statistics from SharedPreferences or `NetworkStatsHelper`.
- `updateAppWidget`: Populates `RemoteViews` and calls `AppWidgetManager.updateAppWidget()`.
