package com.byteflow.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * Dynamic broadcast receiver monitoring screen on/off events to halt
 * polling during display sleep (0.0% CPU overhead).
 */
class ScreenReceiver(
    private val onScreenOff: () -> Unit,
    private val onScreenOn: () -> Unit
) : BroadcastReceiver() {

    private var isRegistered = false

    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_SCREEN_OFF -> onScreenOff()
            Intent.ACTION_SCREEN_ON -> onScreenOn()
        }
    }

    fun register(context: Context) {
        if (!isRegistered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_SCREEN_ON)
            }
            try {
                ContextCompat.registerReceiver(
                    context,
                    this,
                    filter,
                    ContextCompat.RECEIVER_NOT_EXPORTED
                )
                isRegistered = true
            } catch (e: Exception) {
                Log.w("ScreenReceiver", "Failed to register screen receiver with RECEIVER_NOT_EXPORTED, trying fallback: ${e.message}")
                try {
                    context.registerReceiver(this, filter)
                    isRegistered = true
                } catch (err: Exception) {
                    Log.e("ScreenReceiver", "Could not register screen receiver: ${err.message}")
                }
            }
        }
    }

    fun unregister(context: Context) {
        if (isRegistered) {
            try {
                context.unregisterReceiver(this)
            } catch (_: Exception) {}
            isRegistered = false
        }
    }
}
