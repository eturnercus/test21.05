package com.eturnercus.earthporn_wallpaper

import android.content.Context
import android.content.Intent

/**
 * Shared prefs + broadcast consumed by [EarthpornLiveWallpaperService] (Flutter syncs after apply).
 */
object EarthpornBridge {
    const val PREFS = "earthporn_live_wp"
    const val ACTION_REDRAW = "com.eturnercus.earthporn_wallpaper.ACTION_REDRAW"

    const val KEY_IMAGE_PATH = "image_path"
    const val KEY_GYRO_ENABLED = "gyro_enabled"
    const val KEY_GYRO_SCALE = "gyro_scale"
    const val KEY_GYRO_MAX_OFFSET_DP = "gyro_max_offset_dp"
    const val KEY_GYRO_SMOOTHING = "gyro_smoothing"
    const val KEY_GYRO_INVERT_X = "gyro_invert_x"
    const val KEY_GYRO_INVERT_Y = "gyro_invert_y"
    const val KEY_PAGER_ENABLED = "pager_enabled"
    const val KEY_PAGER_STRENGTH_DP = "pager_strength_dp"
    const val KEY_REDUCE_MOTION = "reduce_motion"
    const val KEY_TRIPLE_ENABLED = "triple_enabled"
    const val KEY_TRIPLE_WINDOW_MS = "triple_window_ms"

    @Suppress("UNCHECKED_CAST")
    fun syncFromMap(ctx: Context, map: Map<String, Any?>?) {
        if (map == null) return
        val app = ctx.applicationContext
        val e = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
        (map["imagePath"] as? String)?.let { e.putString(KEY_IMAGE_PATH, it) }
        (map["gyroEnabled"] as? Boolean)?.let { e.putBoolean(KEY_GYRO_ENABLED, it) }
        (map["gyroScale"] as? Number)?.let { e.putFloat(KEY_GYRO_SCALE, it.toFloat()) }
        (map["gyroMaxOffsetDp"] as? Number)?.let { e.putFloat(KEY_GYRO_MAX_OFFSET_DP, it.toFloat()) }
        (map["gyroSmoothing"] as? Number)?.let { e.putFloat(KEY_GYRO_SMOOTHING, it.toFloat()) }
        (map["gyroInvertX"] as? Boolean)?.let { e.putBoolean(KEY_GYRO_INVERT_X, it) }
        (map["gyroInvertY"] as? Boolean)?.let { e.putBoolean(KEY_GYRO_INVERT_Y, it) }
        (map["pagerEnabled"] as? Boolean)?.let { e.putBoolean(KEY_PAGER_ENABLED, it) }
        (map["pagerStrengthDp"] as? Number)?.let { e.putFloat(KEY_PAGER_STRENGTH_DP, it.toFloat()) }
        (map["reduceMotion"] as? Boolean)?.let { e.putBoolean(KEY_REDUCE_MOTION, it) }
        (map["tripleEnabled"] as? Boolean)?.let { e.putBoolean(KEY_TRIPLE_ENABLED, it) }
        (map["tripleWindowMs"] as? Number)?.let { e.putLong(KEY_TRIPLE_WINDOW_MS, it.toLong()) }
        e.apply()
        app.sendBroadcast(
            Intent(ACTION_REDRAW).setPackage(app.packageName),
        )
    }
}
