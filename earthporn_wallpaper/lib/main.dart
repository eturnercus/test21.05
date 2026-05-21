import 'package:flutter/material.dart';

import 'src/services/settings_repository.dart';
import 'src/services/wallpaper_engine.dart';
import 'src/ui/earthporn_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsRepository();
  await settings.load();
  final engine = WallpaperEngine(settingsRepository: settings);

  runApp(EarthpornApp(engine: engine, settings: settings));
}
