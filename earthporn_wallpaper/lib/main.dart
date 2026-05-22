import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/desktop/desktop_next_port.dart';
import 'src/services/settings_repository.dart';
import 'src/services/wallpaper_engine.dart';
import 'src/ui/earthporn_app.dart';

/// Primary desktop instance listens here; hook / CLI sends NEXT without UI.
ServerSocket? _desktopCommandServer;

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

  if (!kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    _desktopCommandServer = await DesktopNextPort.tryBindPrimary();
    if (_desktopCommandServer == null) {
      await DesktopNextPort.secondaryInstanceMaybeSignalAndExit();
      return;
    }
    DesktopNextPort.listenForNextCommands(
      _desktopCommandServer!,
      () => unawaited(engine.nextWallpaperQuick()),
    );
  }

  runApp(EarthpornApp(engine: engine, settings: settings));
  // ignore: unnecessary_statements
  _desktopCommandServer?.port;
}
