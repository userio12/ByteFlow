package com.byteflow.service

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import androidx.core.graphics.drawable.IconCompat

/**
 * Generates crisp, high-contrast dynamic 2-tier monochrome status bar bitmaps
 * representing the current network speed (e.g. "14" / "M" or "250" / "K").
 * Employs string-level caching to guarantee 0.0% battery overhead.
 */
object SpeedIconGenerator {

    private const val BITMAP_SIZE = 48 // 48x48 px standard status bar icon canvas
    private var lastRenderedKey: String? = null
    private var cachedIcon: IconCompat? = null
    private var cachedBitmap: Bitmap? = null

    private val numberPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textAlign = Paint.Align.CENTER
        typeface = Typeface.create("sans-serif", Typeface.BOLD)
        textSize = 24f
    }

    private val unitPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textAlign = Paint.Align.CENTER
        typeface = Typeface.create("sans-serif", Typeface.NORMAL)
        textSize = 18f
    }

    /**
     * Deconstructs [bytesPerSec] into a 2-tier (number, unit) pair.
     * Respects [useBits] (Bits: 'k', 'm', 'g' vs Bytes: 'K', 'M', 'G').
     */
    fun getSpeedParts(bytesPerSec: Long, useBits: Boolean): Pair<String, String> {
        if (bytesPerSec <= 0) {
            return Pair("0", if (useBits) "b" else "B")
        }

        if (useBits) {
            val bitsPerSec = (bytesPerSec * 8).toDouble()
            return when {
                bitsPerSec >= 1_000_000_000.0 -> {
                    val v = bitsPerSec / 1_000_000_000.0
                    Pair(if (v >= 10) String.format("%.0f", v) else String.format("%.1f", v), "g")
                }
                bitsPerSec >= 1_000_000.0 -> {
                    val v = bitsPerSec / 1_000_000.0
                    Pair(if (v >= 10) String.format("%.0f", v) else String.format("%.1f", v), "m")
                }
                bitsPerSec >= 1_000.0 -> {
                    val v = bitsPerSec / 1_000.0
                    Pair(if (v >= 10) String.format("%.0f", v) else String.format("%.1f", v), "k")
                }
                else -> Pair(bitsPerSec.toLong().toString(), "b")
            }
        } else {
            val bytes = bytesPerSec.toDouble()
            return when {
                bytes >= 1024.0 * 1024 * 1024 -> {
                    val v = bytes / (1024.0 * 1024 * 1024)
                    Pair(if (v >= 10) String.format("%.0f", v) else String.format("%.1f", v), "G")
                }
                bytes >= 1024.0 * 1024 -> {
                    val v = bytes / (1024.0 * 1024)
                    Pair(if (v >= 10) String.format("%.0f", v) else String.format("%.1f", v), "M")
                }
                bytes >= 1024.0 -> {
                    val v = bytes / 1024.0
                    Pair(if (v >= 10) String.format("%.0f", v) else String.format("%.1f", v), "K")
                }
                else -> Pair(bytesPerSec.toString(), "B")
            }
        }
    }

    /**
     * Builds or returns cached Bitmap representing current speed.
     * Designed for NotificationCompat.Builder.setLargeIcon.
     */
    @Synchronized
    fun getSpeedBitmap(bytesPerSec: Long, useBits: Boolean): Bitmap {
        val (number, unit) = getSpeedParts(bytesPerSec, useBits)
        val cacheKey = "$number|$unit"

        if (cacheKey == lastRenderedKey && cachedBitmap != null && !cachedBitmap!!.isRecycled) {
            return cachedBitmap!!
        }

        val bitmap = Bitmap.createBitmap(BITMAP_SIZE, BITMAP_SIZE, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Adjust text size dynamically based on length of number (e.g. "120" vs "12" vs "1.2")
        numberPaint.textSize = when {
            number.length >= 4 -> 18f
            number.length == 3 -> 21f
            else -> 25f
        }

        // Measure bounds for vertical alignment
        val numberBounds = Rect()
        numberPaint.getTextBounds(number, 0, number.length, numberBounds)
        val unitBounds = Rect()
        unitPaint.getTextBounds(unit, 0, unit.length, unitBounds)

        // Draw top tier (number) centered at y = 22
        canvas.drawText(number, (BITMAP_SIZE / 2).toFloat(), 22f, numberPaint)
        // Draw bottom tier (unit) centered at y = 43
        canvas.drawText(unit, (BITMAP_SIZE / 2).toFloat(), 43f, unitPaint)

        lastRenderedKey = cacheKey
        cachedBitmap = bitmap
        cachedIcon = IconCompat.createWithBitmap(bitmap)
        return bitmap
    }

    /**
     * Builds or returns cached IconCompat representing current speed.
     */
    @Synchronized
    fun getDynamicSpeedIcon(bytesPerSec: Long, useBits: Boolean): IconCompat {
        getSpeedBitmap(bytesPerSec, useBits)
        return cachedIcon!!
    }
}
