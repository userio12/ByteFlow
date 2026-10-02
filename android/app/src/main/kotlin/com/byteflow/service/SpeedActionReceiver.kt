package com.byteflow.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * BroadcastReceiver handling interactive notification actions:
 * - ACTION_PAUSE_SPEED: Pauses real-time sampling and displays paused notification state.
 * - ACTION_RESUME_SPEED: Resumes sampling immediately.
 */
class SpeedActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_PAUSE_SPEED = "com.byteflow.ACTION_PAUSE_SPEED"
        const val ACTION_RESUME_SPEED = "com.byteflow.ACTION_RESUME_SPEED"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            ACTION_PAUSE_SPEED -> {
                LiveSpeedService.pauseSampling(context)
            }
            ACTION_RESUME_SPEED -> {
                LiveSpeedService.resumeSampling(context)
            }
        }
    }
}
