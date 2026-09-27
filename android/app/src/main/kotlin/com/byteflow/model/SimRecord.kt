package com.byteflow.model

/**
 * Native record representing an active SIM card subscription and carrier metadata.
 */
data class SimRecord(
    val subId: Int,
    val slotIndex: Int,
    val displayName: String,
    val carrierName: String,
    val countryIso: String = "",
    val isDataRoaming: Boolean = false,
    val isDefaultData: Boolean = false
) {
    fun toMap(): Map<String, Any> {
        return mapOf(
            "subId" to subId,
            "slotIndex" to slotIndex,
            "displayName" to displayName,
            "carrierName" to carrierName,
            "countryIso" to countryIso,
            "isDataRoaming" to isDataRoaming,
            "isDefaultData" to isDefaultData
        )
    }
}
