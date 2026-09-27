package com.byteflow.network

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import android.util.LruCache
import java.io.ByteArrayOutputStream

/**
 * Memory-safe LRU icon cache with bitmap downsampling (48x48dp) to prevent OOM
 * when serializing hundreds of installed application icons to Flutter.
 */
object IconCacheHelper {
    // 8 MB max memory cache
    private const val MAX_CACHE_SIZE_BYTES = 8 * 1024 * 1024
    private val iconCache = object : LruCache<String, String>(MAX_CACHE_SIZE_BYTES) {
        override fun sizeOf(key: String, value: String): Int {
            return value.length
        }
    }

    private const val TARGET_SIZE_PX = 96 // 48dp on 2x display

    fun getAppIconBase64(context: Context, packageName: String): String? {
        val cached = iconCache.get(packageName)
        if (cached != null) return cached

        return try {
            val pm = context.packageManager
            val drawable = pm.getApplicationIcon(packageName)
            val bitmap = drawableToBitmap(drawable, TARGET_SIZE_PX, TARGET_SIZE_PX)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 85, stream)
            val byteArray = stream.toByteArray()
            val base64String = Base64.encodeToString(byteArray, Base64.NO_WRAP)
            iconCache.put(packageName, base64String)
            base64String
        } catch (_: Exception) {
            null
        }
    }

    private fun drawableToBitmap(drawable: Drawable, targetWidth: Int, targetHeight: Int): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return Bitmap.createScaledBitmap(drawable.bitmap, targetWidth, targetHeight, true)
        }

        val bitmap = Bitmap.createBitmap(targetWidth, targetHeight, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    fun clearCache() {
        iconCache.evictAll()
    }
}
