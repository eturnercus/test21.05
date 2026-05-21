import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

import '../models/app_settings.dart';

class AutostartService {
  static bool _configured = false;

  static void ensureConfigured() {
    if (_configured || kIsWeb) return;
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return;
    }
    LaunchAtStartup.instance.setup(
      appName: 'EarthPorn Wallpaper',
      appPath: Platform.resolvedExecutable,
    );
    _configured = true;
  }

  static Future<void> apply(AppSettings settings) async {
    if (kIsWeb) return;
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return;
    }
    ensureConfigured();
    if (settings.runAtStartup) {
      await LaunchAtStartup.instance.enable();
    } else {
      await LaunchAtStartup.instance.disable();
    }
  }
}
