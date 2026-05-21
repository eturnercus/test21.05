package com.eturnercus.earthporn_wallpaper

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.eturnercus.earthporn_wallpaper/installer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "openLiveWallpaperPicker") {
                    try {
                        val chooser = Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER)
                        startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val cn = ComponentName(
                                this,
                                "np.com.sawin.wallpaper_manager_plus.LiveWallpaperService"
                            )
                            val i = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER)
                            i.putExtra(WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT, cn)
                            startActivity(i)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("OPEN_FAILED", e2.message, null)
                        }
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
