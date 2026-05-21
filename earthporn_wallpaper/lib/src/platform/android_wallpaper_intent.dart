import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Opens Android live wallpaper chooser / plugin live wallpaper flow.
class AndroidWallpaperIntent {
  static const _channel =
      MethodChannel('com.eturnercus.earthporn_wallpaper/installer');

  static Future<bool> openLiveWallpaperFlow() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('openLiveWallpaperPicker');
      return ok ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
