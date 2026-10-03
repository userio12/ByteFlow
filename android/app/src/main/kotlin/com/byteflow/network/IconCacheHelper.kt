package com.byteflow.network

import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import android.util.LruCache
import androidx.core.content.res.ResourcesCompat
import java.io.ByteArrayOutputStream

/**
 * Memory-safe LRU icon cache with bitmap downsampling (48x48dp) to prevent OOM
 * when serializing hundreds of installed application icons to Flutter.
 * Hardened with direct resource extraction to bypass Samsung One UI theme engine
 * lookup exceptions (SemAppIconSolution NameNotFoundException) and immediate native
 * bitmap recycling to eliminate ART finalizer memory leaks.
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
    private const val EMPTY_ICON_SENTINEL = ""

    fun getAppIconBase64(context: Context, packageName: String): String? {
        val cached = iconCache.get(packageName)
        if (cached != null) {
            return if (cached == EMPTY_ICON_SENTINEL) null else cached
        }

        return try {
            val pm = context.packageManager
            val drawable = loadAppDrawable(pm, packageName)
            if (drawable == null) {
                iconCache.put(packageName, EMPTY_ICON_SENTINEL)
                return null
            }

            val bitmap = drawableToBitmap(drawable, TARGET_SIZE_PX, TARGET_SIZE_PX)
            val base64String = try {
                ByteArrayOutputStream().use { stream ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 85, stream)
                    Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
                }
            } finally {
                // Immediately release native graphics buffer to prevent ART FinalizerDaemon leaks
                if (!bitmap.isRecycled) {
                    bitmap.recycle()
                }
            }

            iconCache.put(packageName, base64String)
            base64String
        } catch (_: Exception) {
            iconCache.put(packageName, EMPTY_ICON_SENTINEL)
            null
        }
    }

    /**
     * Bypasses OEM theme engines (such as Samsung's SemAppIconSolution) by attempting
     * direct resource extraction from the target APK before falling back to PackageManager.
     */
    private fun loadAppDrawable(pm: PackageManager, packageName: String): Drawable? {
        return try {
            val appInfo = pm.getApplicationInfo(packageName, 0)
            if (appInfo.icon != 0) {
                try {
                    val res = pm.getResourcesForApplication(appInfo)
                    ResourcesCompat.getDrawable(res, appInfo.icon, null)
                } catch (_: Exception) {
                    appInfo.loadIcon(pm)
                }
            } else {
                appInfo.loadIcon(pm)
            }
        } catch (_: Exception) {
            try {
                pm.getApplicationIcon(packageName)
            } catch (_: Exception) {
                null
            }
        }
    }

    private fun drawableToBitmap(drawable: Drawable, targetWidth: Int, targetHeight: Int): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null && !drawable.bitmap.isRecycled) {
            val orig = drawable.bitmap
            if (orig.width == targetWidth && orig.height == targetHeight) {
                // Create a mutable copy so the caller can safely recycle it without
                // corrupting the source BitmapDrawable cached in PackageManager resources.
                return orig.copy(Bitmap.Config.ARGB_8888, true)
            }
            return Bitmap.createScaledBitmap(orig, targetWidth, targetHeight, true)
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
