package com.eturnercus.earthporn_wallpaper

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        @Volatile
        var pendingLaunchAction: String? = null
    }

    private val installerChannel = "com.eturnercus.earthporn_wallpaper/installer"
    private val bridgeChannel = "com.eturnercus.earthporn_wallpaper/bridge"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        captureIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureIntent(intent)
    }

    private fun captureIntent(i: Intent?) {
        val a = i?.getStringExtra("earthporn_action") ?: return
        if (a.isNotEmpty()) {
            pendingLaunchAction = a
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, installerChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "openLiveWallpaperPicker") {
                    try {
                        val cn = ComponentName(this, EarthpornLiveWallpaperService::class.java)
                        val i = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER)
                        i.putExtra(WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT, cn)
                        startActivity(i)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            startActivity(Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER))
                            result.success(true)
                        } catch (e2: Exception) {
                            try {
                                val cn = ComponentName(
                                    this,
                                    "np.com.sawin.wallpaper_manager_plus.LiveWallpaperService",
                                )
                                val i = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER)
                                i.putExtra(WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT, cn)
                                startActivity(i)
                                result.success(true)
                            } catch (e3: Exception) {
                                result.error("OPEN_FAILED", e3.message, null)
                            }
                        }
                    }
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, bridgeChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPendingLaunchAction" -> {
                        result.success(pendingLaunchAction)
                    }
                    "clearPendingLaunchAction" -> {
                        pendingLaunchAction = null
                        result.success(null)
                    }
                    "syncLiveWallpaperState" -> {
                        @Suppress("UNCHECKED_CAST")
                        val m = call.arguments as? Map<String, Any?>
                        EarthpornBridge.syncFromMap(this, m)
                        result.success(true)
                    }
                    "setKeepAliveEnabled" -> {
                        val en = call.arguments as? Boolean ?: false
                        val svc = Intent(this, WallpaperKeepAliveService::class.java)
                        if (en) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                ContextCompat.startForegroundService(this, svc)
                            } else {
                                startService(svc)
                            }
                        } else {
                            stopService(svc)
                        }
                        result.success(true)
                    }
                    "moveTaskToBack" -> {
                        moveTaskToBack(true)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
