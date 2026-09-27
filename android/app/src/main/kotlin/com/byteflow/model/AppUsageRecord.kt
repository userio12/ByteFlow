package com.byteflow.model

/**
 * Native record representing network data consumption for an individual application or system UID.
 */
data class AppUsageRecord(
    val uid: Int,
    val packageName: String,
    val appName: String,
    var rxBytes: Long = 0L,
    var txBytes: Long = 0L,
    var foregroundRx: Long = 0L,
    var foregroundTx: Long = 0L,
    var backgroundRx: Long = 0L,
    var backgroundTx: Long = 0L,
    var appIconBase64: String? = null
) {
    val totalBytes: Long
        get() = rxBytes + txBytes

    val foregroundBytes: Long
        get() = foregroundRx + foregroundTx

    val backgroundBytes: Long
        get() = backgroundRx + backgroundTx

    fun toMap(): Map<String, Any?> {
        return mapOf(
            "uid" to uid,
            "packageName" to packageName,
            "appName" to appName,
            "rxBytes" to rxBytes,
            "txBytes" to txBytes,
            "totalBytes" to totalBytes,
            "foregroundRx" to foregroundRx,
            "foregroundTx" to foregroundTx,
            "foregroundBytes" to foregroundBytes,
            "backgroundRx" to backgroundRx,
            "backgroundTx" to backgroundTx,
            "backgroundBytes" to backgroundBytes,
            "appIconBase64" to appIconBase64
        )
    }
}
