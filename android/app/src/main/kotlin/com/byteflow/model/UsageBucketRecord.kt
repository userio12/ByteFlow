package com.byteflow.model

/**
 * Native record representing discrete time buckets (e.g. 1-hour slice, 1-day slice, 1-month slice).
 */
data class UsageBucketRecord(
    val startTimeMs: Long,
    val endTimeMs: Long,
    val rxBytes: Long = 0L,
    val txBytes: Long = 0L,
    val networkType: String = "mobile"
) {
    val totalBytes: Long
        get() = rxBytes + txBytes

    fun toMap(): Map<String, Any> {
        return mapOf(
            "startTimeMs" to startTimeMs,
            "endTimeMs" to endTimeMs,
            "rxBytes" to rxBytes,
            "txBytes" to txBytes,
            "totalBytes" to totalBytes,
            "networkType" to networkType
        )
    }
}
