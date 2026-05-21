import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/services/settings_repository.dart';
import 'src/services/wallpaper_engine.dart';
import 'src/ui/earthporn_app.dart';

/// One desktop instance: second launch exits immediately (first keeps port).
ServerSocket? _desktopSingletonSocket;

Future<void> _acquireDesktopSingletonOrExit() async {
  if (kIsWeb) return;
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
  try {
    _desktopSingletonSocket = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      48193,
      shared: false,
    );
  } on SocketException {
    exit(0);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _acquireDesktopSingletonOrExit();
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
  // ignore: unnecessary_statements
  _desktopSingletonSocket?.port;
}
