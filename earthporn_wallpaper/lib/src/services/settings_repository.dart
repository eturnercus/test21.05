import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/wallpaper_orientation.dart';
import '../ui/app_keys.dart';

class SettingsRepository extends ChangeNotifier {
  static const _key = 'app_settings_json_v3';

  AppSettings _settings = AppSettings.defaults();

  AppSettings get settings => _settings;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    var raw = p.getString(_key);
    raw ??= p.getString('app_settings_json_v2');
    if (raw == null || raw.isEmpty) {
      var base = AppSettings.defaults();
      if (!kIsWeb && Platform.isAndroid) {
        base = base.copyWith(
          orientation: WallpaperOrientation.portrait,
          minWidth: 1080,
          minHeight: 1920,
        );
      }
      _settings = base;
    } else {
      _settings = AppSettings.decode(raw);
    }
    notifyListeners();
  }

  Future<void> save(AppSettings s) async {
    _settings = s;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, AppSettings.encode(s));
    notifyListeners();
  }

  /// Show main-screen help overlay again (see [MainHelpOverlay.dismissedKey]).
  Future<void> requestShowMainHelpAgain() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(kMainHelpOverlayDismissedKey, false);
    notifyListeners();
  }
}
