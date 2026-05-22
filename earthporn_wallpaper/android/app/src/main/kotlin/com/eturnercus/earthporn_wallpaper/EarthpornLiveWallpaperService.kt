package com.eturnercus.earthporn_wallpaper

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.wallpaper.WallpaperService
import android.view.MotionEvent
import android.view.SurfaceHolder
import java.io.File
import kotlin.math.max

/**
 * Live wallpaper: draws the image path synced from Flutter; optional gyro + launcher page offset;
 * triple tap on empty wallpaper area requests the next frame via [MainActivity].
 */
class EarthpornLiveWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = EarthEngine()

    inner class EarthEngine : Engine(), SensorEventListener {
        private val handler = Handler(Looper.getMainLooper())
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        private var bitmap: Bitmap? = null
        private var sensorManager: SensorManager? = null
        private var vx = 0f
        private var vy = 0f
        private var xOffset01 = 0.5f
        private var surfaceW = 1
        private var surfaceH = 1
        private var density = 1f
        private val tapTimes = ArrayList<Long>(4)
        private var drawScheduled = false

        private val redrawReceiver = object : android.content.BroadcastReceiver() {
            override fun onReceive(context: android.content.Context?, intent: android.content.Intent?) {
                reloadBitmap()
                requestDraw()
            }
        }

        private val drawRunnable = Runnable {
            drawScheduled = false
            drawFrame()
        }

        override fun onCreate(surfaceHolder: SurfaceHolder) {
            super.onCreate(surfaceHolder)
            setTouchEventsEnabled(true)
            density = this@EarthpornLiveWallpaperService.resources.displayMetrics.density
            reloadBitmap()
            val filter = android.content.IntentFilter(EarthpornBridge.ACTION_REDRAW)
            if (Build.VERSION.SDK_INT >= 33) {
                this@EarthpornLiveWallpaperService.registerReceiver(
                    redrawReceiver,
                    filter,
                    android.content.Context.RECEIVER_NOT_EXPORTED,
                )
            } else {
                this@EarthpornLiveWallpaperService.registerReceiver(redrawReceiver, filter)
            }
            surfaceHolder.addCallback(object : SurfaceHolder.Callback {
                override fun surfaceCreated(holder: SurfaceHolder) {
                    requestDraw()
                }

                override fun surfaceChanged(
                    holder: SurfaceHolder,
                    format: Int,
                    width: Int,
                    height: Int,
                ) {
                    surfaceW = width
                    surfaceH = height
                    requestDraw()
                }

                override fun surfaceDestroyed(holder: SurfaceHolder) {
                    handler.removeCallbacks(drawRunnable)
                }
            })
        }

        override fun onDestroy() {
            handler.removeCallbacks(drawRunnable)
            try {
                this@EarthpornLiveWallpaperService.unregisterReceiver(redrawReceiver)
            } catch (_: Exception) {
            }
            unregisterSensor()
            bitmap?.recycle()
            bitmap = null
            super.onDestroy()
        }

        override fun onVisibilityChanged(visible: Boolean) {
            super.onVisibilityChanged(visible)
            if (visible) {
                reloadBitmap()
                registerSensorIfNeeded()
                requestDraw()
            } else {
                unregisterSensor()
            }
        }

        private fun prefs() = this@EarthpornLiveWallpaperService.applicationContext
            .getSharedPreferences(EarthpornBridge.PREFS, android.content.Context.MODE_PRIVATE)

        private fun reloadBitmap() {
            val path = prefs().getString(EarthpornBridge.KEY_IMAGE_PATH, null) ?: return
            val f = File(path)
            if (!f.exists()) {
                bitmap?.recycle()
                bitmap = null
                return
            }
            try {
                val opts = BitmapFactory.Options().apply { inPreferredConfig = Bitmap.Config.RGB_565 }
                val nb = BitmapFactory.decodeFile(path, opts) ?: return
                bitmap?.recycle()
                bitmap = nb
            } catch (_: Exception) {
            }
        }

        private fun registerSensorIfNeeded() {
            val p = prefs()
            if (p.getBoolean(EarthpornBridge.KEY_REDUCE_MOTION, false)) return
            if (!p.getBoolean(EarthpornBridge.KEY_GYRO_ENABLED, false)) return
            if (sensorManager != null) return
            val sm = this@EarthpornLiveWallpaperService
                .getSystemService(SENSOR_SERVICE) as SensorManager
            val s = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) ?: return
            sm.registerListener(this, s, SensorManager.SENSOR_DELAY_UI)
            sensorManager = sm
        }

        private fun unregisterSensor() {
            val sm = sensorManager ?: return
            try {
                sm.unregisterListener(this)
            } catch (_: Exception) {
            }
            sensorManager = null
        }

        override fun onSensorChanged(event: SensorEvent?) {
            if (event?.sensor?.type != Sensor.TYPE_ACCELEROMETER) return
            val p = prefs()
            val a = p.getFloat(EarthpornBridge.KEY_GYRO_SMOOTHING, 0.18f).coerceIn(0.05f, 0.55f)
            vx = vx * (1 - a) + event.values[0] * a
            vy = vy * (1 - a) + event.values[1] * a
            requestDraw()
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

        override fun onOffsetsChanged(
            xOffset: Float,
            yOffset: Float,
            xOffsetStep: Float,
            yOffsetStep: Float,
            xPixelOffset: Int,
            yPixelOffset: Int,
        ) {
            xOffset01 = xOffset
            requestDraw()
        }

        override fun onTouchEvent(event: MotionEvent?) {
            if (event == null) return
            if (event.actionMasked != MotionEvent.ACTION_DOWN) return
            if (!prefs().getBoolean(EarthpornBridge.KEY_TRIPLE_ENABLED, true)) return
            val now = System.currentTimeMillis()
            val window = prefs().getLong(EarthpornBridge.KEY_TRIPLE_WINDOW_MS, 650L).coerceIn(200L, 5000L)
            tapTimes.removeAll { now - it > window }
            tapTimes.add(now)
            if (tapTimes.size >= 3) {
                tapTimes.clear()
                val i = android.content.Intent(applicationContext, MainActivity::class.java).apply {
                    flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK or
                        android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("earthporn_action", "next_wallpaper")
                }
                try {
                    applicationContext.startActivity(i)
                } catch (_: Exception) {
                }
            }
            super.onTouchEvent(event)
        }

        private fun requestDraw() {
            if (drawScheduled) return
            drawScheduled = true
            handler.post(drawRunnable)
        }

        private fun drawFrame() {
            val holder = surfaceHolder ?: return
            val bmp = bitmap
            val c: Canvas = try {
                holder.lockCanvas()
            } catch (_: Exception) {
                return
            } ?: return
            try {
                if (surfaceW <= 0 || surfaceH <= 0 || bmp == null || bmp.isRecycled) {
                    c.drawColor(0xFF101010.toInt())
                    return
                }
                val p = prefs()
                val reduce = p.getBoolean(EarthpornBridge.KEY_REDUCE_MOTION, false)
                val gyroOn = p.getBoolean(EarthpornBridge.KEY_GYRO_ENABLED, false) && !reduce
                val pagerOn = p.getBoolean(EarthpornBridge.KEY_PAGER_ENABLED, false) && !reduce

                val maxG = p.getFloat(EarthpornBridge.KEY_GYRO_MAX_OFFSET_DP, 16f).coerceIn(4f, 48f)
                val invX = if (p.getBoolean(EarthpornBridge.KEY_GYRO_INVERT_X, false)) -1f else 1f
                val invY = if (p.getBoolean(EarthpornBridge.KEY_GYRO_INVERT_Y, false)) -1f else 1f
                val dpr = density
                val gx = if (gyroOn) {
                    ((-vx * 2.2f * invX).coerceIn(-maxG, maxG) * (dpr / 2.6f))
                } else {
                    0f
                }
                val gy = if (gyroOn) {
                    ((vy * 2.2f * invY).coerceIn(-maxG, maxG) * (dpr / 2.6f))
                } else {
                    0f
                }

                val pagerStrength =
                    p.getFloat(EarthpornBridge.KEY_PAGER_STRENGTH_DP, 22f).coerceIn(4f, 80f) * dpr / 2f
                val pagerDx = if (pagerOn) {
                    (xOffset01 - 0.5f) * 2f * pagerStrength
                } else {
                    0f
                }

                val scaleExtra = if (gyroOn) {
                    p.getFloat(EarthpornBridge.KEY_GYRO_SCALE, 1.08f).coerceIn(1f, 1.22f)
                } else {
                    1f
                }

                c.drawColor(0xFF000000.toInt())
                drawFit(c, bmp, gx + pagerDx, gy, scaleExtra)
            } finally {
                try {
                    holder.unlockCanvasAndPost(c)
                } catch (_: Exception) {
                }
            }
        }

        private fun drawFit(c: Canvas, bmp: Bitmap, tx: Float, ty: Float, scaleExtra: Float) {
            val vw = surfaceW.toFloat()
            val vh = surfaceH.toFloat()
            val bw = bmp.width.toFloat()
            val bh = bmp.height.toFloat()
            val scale = max(vw / bw, vh / bh) * scaleExtra
            val scaledW = bw * scale
            val scaledH = bh * scale
            val left = (vw - scaledW) / 2f + tx
            val top = (vh - scaledH) / 2f + ty
            val m = Matrix()
            m.postScale(scale, scale)
            m.postTranslate(left, top)
            c.drawBitmap(bmp, m, paint)
        }
    }
}
