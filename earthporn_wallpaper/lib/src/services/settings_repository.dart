import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsRepository extends ChangeNotifier {
  static const _key = 'app_settings_json_v2';

  AppSettings _settings = AppSettings.defaults();

  AppSettings get settings => _settings;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) {
      _settings = AppSettings.defaults();
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
}
