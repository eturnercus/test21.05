import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../models/app_settings.dart';
import '../services/settings_repository.dart';
import '../services/wallpaper_engine.dart';
import 'autostart_service.dart';
import '../ui/app_keys.dart';
import '../ui/theme.dart';

/// Tray, window close-to-tray, global hotkey (Windows / Linux desktop).
class DesktopIntegration with TrayListener, WindowListener {
  DesktopIntegration._(this._engine, this._settings, this._navigatorKey);

  final WallpaperEngine _engine;
  final SettingsRepository _settings;
  final GlobalKey<NavigatorState> _navigatorKey;

  static DesktopIntegration? _instance;

  int _trayDowns = 0;
  Timer? _trayReset;

  static Future<void> init(
    WallpaperEngine engine,
    SettingsRepository settings,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    if (!Platform.isWindows && !Platform.isLinux) return;
    await windowManager.ensureInitialized();
    await hotKeyManager.unregisterAll();
    _instance?.dispose();
    final d = DesktopIntegration._(engine, settings, navigatorKey);
    _instance = d;
    windowManager.addListener(d);
    trayManager.addListener(d);

    final s = settings.settings;
    final opts = WindowOptions(
      size: Size(s.lastWindowWidth, s.lastWindowHeight),
      center: true,
      backgroundColor: Colors.transparent,
      title: appTitle(),
    );

    await windowManager.waitUntilReadyToShow(opts, () async {
      if (s.startHiddenInTray) {
        await windowManager.hide();
      } else {
        await windowManager.show();
        await windowManager.focus();
      }
    });

    await windowManager.setPreventClose(true);
    await windowManager.setTitle(appTitle());

    if (s.showTrayIcon) {
      await _setupTray(s);
    } else {
      try {
        await trayManager.destroy();
      } catch (_) {}
    }
    await d._registerHotkey(s);
    await AutostartService.apply(s);
  }

  static Future<void> refreshTrayAndHotkey(
    WallpaperEngine engine,
    SettingsRepository settings,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    if (!Platform.isWindows && !Platform.isLinux) return;
    await init(engine, settings, navigatorKey);
  }

  static Future<void> _setupTray(AppSettings s) async {
    await trayManager.setIcon('assets/tray.png');
    await trayManager.setToolTip('EarthPorn — ${AppSettings.creator}');
    await trayManager.setContextMenu(Menu(
      items: [
        MenuItem(
          key: 'show',
          label: 'Показать окно',
          onClick: (_) async {
            await windowManager.show();
            await windowManager.focus();
          },
        ),
        MenuItem(
          key: 'next',
          label: 'Следующие обои',
          onClick: (_) {
            unawaited(_instance?._engine.nextWallpaperQuick());
          },
        ),
        MenuItem(
          key: 'settings',
          label: 'Настройки…',
          onClick: (_) async {
            await windowManager.show();
            await windowManager.focus();
            _instance?._navigatorKey.currentState?.pushNamed('/settings');
          },
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit',
          label: 'Выход',
          onClick: (_) async {
            await trayManager.destroy();
            await windowManager.destroy();
          },
        ),
      ],
    ));
  }

  Future<void> _registerHotkey(AppSettings s) async {
    await hotKeyManager.unregisterAll();
    if (!s.hotkeyEnabled) return;
    final hk = HotKey(
      identifier: 'earthporn_next_wallpaper_hotkey',
      key: s.hotkeyKey,
      modifiers: s.hotkeyModifiers,
      scope: HotKeyScope.system,
    );
    await hotKeyManager.register(
      hk,
      keyDownHandler: (_) {
        unawaited(_engine.nextWallpaperQuick());
      },
    );
  }

  @override
  void onTrayIconMouseDown() {
    final s = _settings.settings;
    if (!s.trayTripleClickNext) return;
    _trayDowns++;
    _trayReset?.cancel();
    _trayReset = Timer(Duration(milliseconds: s.tripleClickWindowMs), () {
      _trayDowns = 0;
    });
    if (_trayDowns >= 3) {
      _trayDowns = 0;
      _trayReset?.cancel();
      unawaited(_engine.nextWallpaperQuick());
    }
  }

  @override
  void onWindowClose() async {
    final s = _settings.settings;
    if (s.minimizeToTrayOnClose) {
      await windowManager.hide();
    } else {
      await trayManager.destroy();
      await windowManager.destroy();
    }
  }

  void dispose() {
    _trayReset?.cancel();
    windowManager.removeListener(this);
    trayManager.removeListener(this);
  }
}

/// Call once from [main] after binding init for desktop.
Future<void> bootstrapDesktop(
  WallpaperEngine engine,
  SettingsRepository settings,
  GlobalKey<NavigatorState> navigatorKey,
) async {
  if (!Platform.isWindows && !Platform.isLinux) return;
  await DesktopIntegration.init(engine, settings, navigatorKey);
}

/// From settings UI after save.
Future<void> refreshDesktopChrome(BuildContext context) async {
  final engine = context.read<WallpaperEngine>();
  final settings = context.read<SettingsRepository>();
  final key = earthpornNavigatorKey;
  if (!Platform.isWindows && !Platform.isLinux) return;
  await DesktopIntegration.refreshTrayAndHotkey(engine, settings, key);
  await AutostartService.apply(settings.settings);
}
