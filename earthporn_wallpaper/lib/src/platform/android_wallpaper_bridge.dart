import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';

/// Native live wallpaper prefs, foreground keep-alive, and launch intents (Android).
class AndroidWallpaperBridge {
  static const _bridge = MethodChannel(
    'com.eturnercus.earthporn_wallpaper/bridge',
  );

  static Future<void> syncLiveWallpaperFromSettings(
    String imagePath,
    AppSettings s,
  ) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _bridge.invokeMethod<void>('syncLiveWallpaperState', {
        'imagePath': imagePath,
        'gyroEnabled': s.androidGyroParallaxEnabled,
        'gyroScale': s.androidGyroParallaxScale,
        'gyroMaxOffsetDp': s.androidGyroMaxOffsetDp,
        'gyroSmoothing': s.androidGyroSmoothing,
        'gyroInvertX': s.androidGyroInvertX,
        'gyroInvertY': s.androidGyroInvertY,
        'pagerEnabled': s.androidPagerParallaxEnabled,
        'pagerStrengthDp': s.androidPagerStrengthDp,
        'reduceMotion': s.reduceMotion,
        'tripleEnabled':
            s.androidHomeTripleTapEnabled && s.windowTripleClickNext,
        'tripleWindowMs': s.tripleClickWindowMs,
      });
    } catch (e) {
      debugPrint('AndroidWallpaperBridge.syncLiveWallpaper: $e');
    }
  }

  static Future<void> setKeepAlive(bool enabled) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _bridge.invokeMethod<void>('setKeepAliveEnabled', enabled);
    } catch (e) {
      debugPrint('AndroidWallpaperBridge.setKeepAlive: $e');
    }
  }

  static Future<String?> getPendingLaunchAction() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final v = await _bridge.invokeMethod<String?>('getPendingLaunchAction');
      return v;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearPendingLaunchAction() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _bridge.invokeMethod<void>('clearPendingLaunchAction');
    } catch (_) {}
  }

  static Future<void> moveTaskToBack() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _bridge.invokeMethod<void>('moveTaskToBack');
    } catch (_) {}
  }
}
