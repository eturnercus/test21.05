import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/services/settings_repository.dart';
import 'src/services/wallpaper_engine.dart';
import 'src/ui/earthporn_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint(details.exceptionAsString());
    }
  };
  final settings = SettingsRepository();
  await settings.load();
  final engine = WallpaperEngine(settingsRepository: settings);

  runApp(EarthpornApp(engine: engine, settings: settings));
}
