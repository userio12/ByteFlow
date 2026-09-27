package com.byteflow.model

/**
 * Native record representing cumulative device network totals across mobile cellular and Wi-Fi networks.
 */
data class NetworkTotalRecord(
    val mobileRx: Long = 0L,
    val mobileTx: Long = 0L,
    val wifiRx: Long = 0L,
    val wifiTx: Long = 0L,
    val startTimeMs: Long = 0L,
    val endTimeMs: Long = 0L
) {
    val mobileTotal: Long
        get() = mobileRx + mobileTx

    val wifiTotal: Long
        get() = wifiRx + wifiTx

    val grandTotal: Long
        get() = mobileTotal + wifiTotal

    fun toMap(): Map<String, Any> {
        return mapOf(
            "mobileRx" to mobileRx,
            "mobileTx" to mobileTx,
            "mobileTotal" to mobileTotal,
            "wifiRx" to wifiRx,
            "wifiTx" to wifiTx,
            "wifiTotal" to wifiTotal,
            "grandTotal" to grandTotal,
            "startTimeMs" to startTimeMs,
            "endTimeMs" to endTimeMs
        )
    }
}
