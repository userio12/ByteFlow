package com.byteflow.network

import android.Manifest
import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.telephony.SubscriptionManager
import androidx.core.content.ContextCompat
import com.byteflow.model.AppUsageRecord
import com.byteflow.model.NetworkTotalRecord
import com.byteflow.model.SimRecord
import com.byteflow.model.UsageBucketRecord

/**
 * Hardware network accounting helper querying Android's NetworkStatsManager,
 * SubscriptionManager, and AppOpsManager with zero synthetic data.
 */
object NetworkStatsHelper {

    /**
     * Checks whether the user has granted PACKAGE_USAGE_STATS permission via AppOpsManager.
     */
    fun hasUsageStatsPermission(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return false

        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Directs the user to the system Usage Access settings page.
     */
    fun openUsageAccessSettings(context: Context) {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            try {
                data = Uri.parse("package:${context.packageName}")
            } catch (_: Exception) {}
        }
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
            // Fallback without package URI for OEM compatibility
            val fallbackIntent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(fallbackIntent)
        }
    }

    /**
     * Checks whether the application has READ_PHONE_STATE permission.
     */
    fun hasPhoneStatePermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_PHONE_STATE
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Retrieves active SIM subscriptions and carrier information via SubscriptionManager.
     */
    fun getActiveSimCards(context: Context): List<SimRecord> {
        if (!hasPhoneStatePermission(context)) {
            return emptyList()
        }

        val subscriptionManager = context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE)
            as? SubscriptionManager ?: return emptyList()

        return try {
            val list = subscriptionManager.activeSubscriptionInfoList ?: return emptyList()
            val defaultDataSubId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                SubscriptionManager.getDefaultDataSubscriptionId()
            } else {
                -1
            }

            list.map { info ->
                val subId = info.subscriptionId
                val slotIndex = info.simSlotIndex
                val displayName = info.displayName?.toString() ?: "SIM ${slotIndex + 1}"
                val carrierName = info.carrierName?.toString() ?: "Carrier"
                val countryIso = info.countryIso ?: ""
                val isDataRoaming = info.dataRoaming == SubscriptionManager.DATA_ROAMING_ENABLE
                val isDefaultData = (subId == defaultDataSubId)

                SimRecord(
                    subId = subId,
                    slotIndex = slotIndex,
                    displayName = displayName,
                    carrierName = carrierName,
                    countryIso = countryIso,
                    isDataRoaming = isDataRoaming,
                    isDefaultData = isDefaultData
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    /**
     * Queries cumulative device total (Mobile and Wi-Fi) over an epoch interval.
     */
    fun queryDeviceTotal(
        context: Context,
        startTimeMs: Long,
        endTimeMs: Long
    ): NetworkTotalRecord {
        val nsm = context.getSystemService(Context.NETWORK_STATS_SERVICE) as? NetworkStatsManager
            ?: return NetworkTotalRecord(startTimeMs = startTimeMs, endTimeMs = endTimeMs)

        var mobileRx = 0L
        var mobileTx = 0L
        var wifiRx = 0L
        var wifiTx = 0L

        // Query Mobile Cellular
        try {
            val mobileBucket = nsm.querySummaryForDevice(
                ConnectivityManager.TYPE_MOBILE,
                null,
                startTimeMs,
                endTimeMs
            )
            mobileRx = mobileBucket.rxBytes
            mobileTx = mobileBucket.txBytes
        } catch (_: Exception) {}

        // Query Wi-Fi with resilient fallback ("" standard for Wi-Fi, fallback to null)
        try {
            val wifiBucket = try {
                nsm.querySummaryForDevice(
                    ConnectivityManager.TYPE_WIFI,
                    "",
                    startTimeMs,
                    endTimeMs
                )
            } catch (_: Exception) {
                nsm.querySummaryForDevice(
                    ConnectivityManager.TYPE_WIFI,
                    null,
                    startTimeMs,
                    endTimeMs
                )
            }
            wifiRx = wifiBucket.rxBytes
            wifiTx = wifiBucket.txBytes
        } catch (_: Exception) {}

        return NetworkTotalRecord(
            mobileRx = mobileRx,
            mobileTx = mobileTx,
            wifiRx = wifiRx,
            wifiTx = wifiTx,
            startTimeMs = startTimeMs,
            endTimeMs = endTimeMs
        )
    }

    /**
     * Queries per-app data consumption across a specified network type (Mobile, Wi-Fi, or All).
     * networkType: 0 for Mobile (ConnectivityManager.TYPE_MOBILE), 1 for Wi-Fi (ConnectivityManager.TYPE_WIFI), -1 for Both.
     */
    fun queryAppsUsage(
        context: Context,
        networkType: Int,
        startTimeMs: Long,
        endTimeMs: Long,
        includeIcons: Boolean = true
    ): List<AppUsageRecord> {
        val nsm = context.getSystemService(Context.NETWORK_STATS_SERVICE) as? NetworkStatsManager
            ?: return emptyList()
        val pm = context.packageManager
        val appMap = mutableMapOf<Int, AppUsageRecord>()

        val typesToQuery = when (networkType) {
            ConnectivityManager.TYPE_MOBILE -> listOf(ConnectivityManager.TYPE_MOBILE)
            ConnectivityManager.TYPE_WIFI -> listOf(ConnectivityManager.TYPE_WIFI)
            else -> listOf(ConnectivityManager.TYPE_MOBILE, ConnectivityManager.TYPE_WIFI)
        }

        for (type in typesToQuery) {
            try {
                val stats = try {
                    if (type == ConnectivityManager.TYPE_WIFI) {
                        try {
                            nsm.querySummary(type, "", startTimeMs, endTimeMs)
                        } catch (_: Exception) {
                            nsm.querySummary(type, null, startTimeMs, endTimeMs)
                        }
                    } else {
                        nsm.querySummary(type, null, startTimeMs, endTimeMs)
                    }
                } catch (_: Exception) {
                    null
                } ?: continue

                val bucket = NetworkStats.Bucket()

                while (stats.hasNextBucket()) {
                    stats.getNextBucket(bucket)
                    val uid = bucket.uid
                    val record = appMap.getOrPut(uid) {
                        val packages = pm.getPackagesForUid(uid)
                        val packageName = packages?.firstOrNull() ?: resolveSpecialUidPackage(uid)
                        val appName = resolveAppLabel(pm, packageName, uid)
                        val isSystem = isSystemApp(pm, packageName, uid)
                        AppUsageRecord(
                            uid = uid,
                            packageName = packageName,
                            appName = appName,
                            isSystemApp = isSystem
                        )
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
                    record.rxBytes += rx
                    record.txBytes += tx
                }
                stats.close()
            } catch (_: Exception) {}
        }

        val sortedList = appMap.values
            .filter { it.totalBytes > 0 }
            .sortedByDescending { it.totalBytes }

        if (includeIcons) {
            for (record in sortedList.take(60)) {
                if (record.uid > 0 && !record.packageName.startsWith("uid_")) {
                    record.appIconBase64 = IconCacheHelper.getAppIconBase64(context, record.packageName)
                }
            }
        }

        return sortedList
    }

    /**
     * Slices an arbitrary interval into discrete time buckets (e.g. 24 hourly slices, 7 daily slices).
     */
    fun queryTimeBuckets(
        context: Context,
        networkType: Int,
        startTimeMs: Long,
        endTimeMs: Long,
        stepIntervalMs: Long
    ): List<UsageBucketRecord> {
        val nsm = context.getSystemService(Context.NETWORK_STATS_SERVICE) as? NetworkStatsManager
            ?: return emptyList()

        val actualNetworkType = if (networkType == ConnectivityManager.TYPE_WIFI) {
            ConnectivityManager.TYPE_WIFI
        } else {
            ConnectivityManager.TYPE_MOBILE
        }
        val typeLabel = if (actualNetworkType == ConnectivityManager.TYPE_WIFI) "wifi" else "mobile"

        val buckets = mutableListOf<UsageBucketRecord>()
        var cur = startTimeMs

        while (cur < endTimeMs) {
            val next = minOf(cur + stepIntervalMs, endTimeMs)
            var rx = 0L
            var tx = 0L
            try {
                val bucket = if (actualNetworkType == ConnectivityManager.TYPE_WIFI) {
                    try {
                        nsm.querySummaryForDevice(actualNetworkType, "", cur, next)
                    } catch (_: Exception) {
                        nsm.querySummaryForDevice(actualNetworkType, null, cur, next)
                    }
                } else {
                    nsm.querySummaryForDevice(actualNetworkType, null, cur, next)
                }
                rx = bucket.rxBytes
                tx = bucket.txBytes
            } catch (_: Exception) {}

            buckets.add(
                UsageBucketRecord(
                    startTimeMs = cur,
                    endTimeMs = next,
                    rxBytes = rx,
                    txBytes = tx,
                    networkType = typeLabel
                )
            )
            cur = next
        }
        return buckets
    }

    private fun resolveSpecialUidPackage(uid: Int): String {
        return when (uid) {
            0 -> "android.os.kernel"
            1000 -> "android.uid.system"
            NetworkStats.Bucket.UID_REMOVED -> "android.uid.removed"
            NetworkStats.Bucket.UID_TETHERING -> "android.uid.tethering"
            else -> "uid_$uid"
        }
    }

    private fun resolveAppLabel(pm: PackageManager, packageName: String, uid: Int): String {
        when (uid) {
            0 -> return "Android OS / Kernel"
            1000 -> return "Android System"
            NetworkStats.Bucket.UID_REMOVED -> return "Removed Apps"
            NetworkStats.Bucket.UID_TETHERING -> return "Hotspot & Tethering"
        }

        return try {
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {
            packageName
        }
    }

    private fun isSystemApp(pm: PackageManager, packageName: String, uid: Int): Boolean {
        if (uid < Process.FIRST_APPLICATION_UID) return true
        if (packageName == "android" || packageName.startsWith("android.") || packageName.startsWith("uid_")) {
            return true
        }
        return try {
            // User-facing apps that can be launched from app drawer (e.g. YouTube, Chrome, Maps)
            // should not be hidden as system daemons even if pre-installed in /system.
            val hasLaunchIntent = pm.getLaunchIntentForPackage(packageName) != null
            if (hasLaunchIntent) {
                false
            } else {
                val appInfo = pm.getApplicationInfo(packageName, 0)
                (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 ||
                (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
            }
        } catch (_: Exception) {
            uid < Process.FIRST_APPLICATION_UID
        }
    }
}
