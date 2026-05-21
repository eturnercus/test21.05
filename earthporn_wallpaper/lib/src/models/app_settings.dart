import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'wallpaper_orientation.dart';

/// Persistent user preferences.
class AppSettings {
  const AppSettings({
    required this.rssUrl,
    required this.proxyFirst,
    required this.intervalSeconds,
    required this.maxCachedFiles,
    required this.minWidth,
    required this.minHeight,
    required this.orientation,
    required this.minimizeToTrayOnClose,
    required this.startHiddenInTray,
    required this.showTrayIcon,
    required this.trayTripleClickNext,
    required this.tripleClickWindowMs,
    required this.windowTripleClickNext,
    required this.hotkeyEnabled,
    required this.hotkeyKey,
    required this.hotkeyModifiers,
    required this.prefetchNext,
    required this.filterNsfw,
    required this.skipUsedHashes,
    required this.maxUsedHashEntries,
    required this.httpTimeoutSeconds,
    required this.androidWallpaperLocation,
    required this.runAtStartup,
    required this.onlyWifiDownloads,
    required this.reduceMotion,
    required this.accentColorValue,
    required this.denseUi,
    required this.showEngineLogPanel,
    this.lastWindowWidth = 1040,
    this.lastWindowHeight = 720,
  });

  static const String creator = 'eturnercus';

  static const String defaultRss = 'https://www.reddit.com/r/EarthPorn/.rss';

  /// Default interval: **30 minutes** (same as the original Python script, `CHECK_INTERVAL = 1800`).
  static const int defaultIntervalSeconds = 1800;

  static AppSettings defaults() => AppSettings(
    rssUrl: defaultRss,
    proxyFirst: true,
    intervalSeconds: defaultIntervalSeconds,
    maxCachedFiles: 10,
    minWidth: 1920,
    minHeight: 1080,
    orientation: WallpaperOrientation.landscape,
    minimizeToTrayOnClose: true,
    startHiddenInTray: false,
    showTrayIcon: true,
    trayTripleClickNext: true,
    tripleClickWindowMs: 650,
    windowTripleClickNext: true,
    hotkeyEnabled: true,
    hotkeyKey: LogicalKeyboardKey.keyW,
    hotkeyModifiers: const [HotKeyModifier.alt, HotKeyModifier.shift],
    prefetchNext: true,
    filterNsfw: true,
    skipUsedHashes: true,
    maxUsedHashEntries: 4000,
    httpTimeoutSeconds: 35,
    androidWallpaperLocation: 1,
    runAtStartup: false,
    onlyWifiDownloads: false,
    reduceMotion: false,
    accentColorValue: 0xFF1B4332,
    denseUi: false,
    showEngineLogPanel: true,
  );

  final String rssUrl;
  final bool proxyFirst;
  final int intervalSeconds;
  final int maxCachedFiles;
  final int minWidth;
  final int minHeight;
  final WallpaperOrientation orientation;
  final bool minimizeToTrayOnClose;
  final bool startHiddenInTray;
  final bool showTrayIcon;
  final bool trayTripleClickNext;
  final int tripleClickWindowMs;
  final bool windowTripleClickNext;
  final bool hotkeyEnabled;
  final LogicalKeyboardKey hotkeyKey;
  final List<HotKeyModifier> hotkeyModifiers;
  final bool prefetchNext;
  final bool filterNsfw;
  final bool skipUsedHashes;
  final int maxUsedHashEntries;
  final int httpTimeoutSeconds;
  final int androidWallpaperLocation;

  /// Windows / Linux / macOS autostart (launch_at_startup).
  final bool runAtStartup;

  /// Android: do not download unless on Wi‑Fi or Ethernet.
  final bool onlyWifiDownloads;
  final bool reduceMotion;

  /// ARGB for Color(seed) — use `Color(accentColorValue)` with full opacity in theme.
  final int accentColorValue;
  final bool denseUi;
  final bool showEngineLogPanel;
  final double lastWindowWidth;
  final double lastWindowHeight;

  AppSettings copyWith({
    String? rssUrl,
    bool? proxyFirst,
    int? intervalSeconds,
    int? maxCachedFiles,
    int? minWidth,
    int? minHeight,
    WallpaperOrientation? orientation,
    bool? minimizeToTrayOnClose,
    bool? startHiddenInTray,
    bool? showTrayIcon,
    bool? trayTripleClickNext,
    int? tripleClickWindowMs,
    bool? windowTripleClickNext,
    bool? hotkeyEnabled,
    LogicalKeyboardKey? hotkeyKey,
    List<HotKeyModifier>? hotkeyModifiers,
    bool? prefetchNext,
    bool? filterNsfw,
    bool? skipUsedHashes,
    int? maxUsedHashEntries,
    int? httpTimeoutSeconds,
    int? androidWallpaperLocation,
    bool? runAtStartup,
    bool? onlyWifiDownloads,
    bool? reduceMotion,
    int? accentColorValue,
    bool? denseUi,
    bool? showEngineLogPanel,
    double? lastWindowWidth,
    double? lastWindowHeight,
  }) {
    return AppSettings(
      rssUrl: rssUrl ?? this.rssUrl,
      proxyFirst: proxyFirst ?? this.proxyFirst,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      maxCachedFiles: maxCachedFiles ?? this.maxCachedFiles,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      orientation: orientation ?? this.orientation,
      minimizeToTrayOnClose:
          minimizeToTrayOnClose ?? this.minimizeToTrayOnClose,
      startHiddenInTray: startHiddenInTray ?? this.startHiddenInTray,
      showTrayIcon: showTrayIcon ?? this.showTrayIcon,
      trayTripleClickNext: trayTripleClickNext ?? this.trayTripleClickNext,
      tripleClickWindowMs: tripleClickWindowMs ?? this.tripleClickWindowMs,
      windowTripleClickNext:
          windowTripleClickNext ?? this.windowTripleClickNext,
      hotkeyEnabled: hotkeyEnabled ?? this.hotkeyEnabled,
      hotkeyKey: hotkeyKey ?? this.hotkeyKey,
      hotkeyModifiers: hotkeyModifiers ?? this.hotkeyModifiers,
      prefetchNext: prefetchNext ?? this.prefetchNext,
      filterNsfw: filterNsfw ?? this.filterNsfw,
      skipUsedHashes: skipUsedHashes ?? this.skipUsedHashes,
      maxUsedHashEntries: maxUsedHashEntries ?? this.maxUsedHashEntries,
      httpTimeoutSeconds: httpTimeoutSeconds ?? this.httpTimeoutSeconds,
      androidWallpaperLocation:
          androidWallpaperLocation ?? this.androidWallpaperLocation,
      runAtStartup: runAtStartup ?? this.runAtStartup,
      onlyWifiDownloads: onlyWifiDownloads ?? this.onlyWifiDownloads,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      denseUi: denseUi ?? this.denseUi,
      showEngineLogPanel: showEngineLogPanel ?? this.showEngineLogPanel,
      lastWindowWidth: lastWindowWidth ?? this.lastWindowWidth,
      lastWindowHeight: lastWindowHeight ?? this.lastWindowHeight,
    );
  }

  Map<String, dynamic> toJson() => {
    'rssUrl': rssUrl,
    'proxyFirst': proxyFirst,
    'intervalSeconds': intervalSeconds,
    'maxCachedFiles': maxCachedFiles,
    'minWidth': minWidth,
    'minHeight': minHeight,
    'orientation': orientation.name,
    'minimizeToTrayOnClose': minimizeToTrayOnClose,
    'startHiddenInTray': startHiddenInTray,
    'showTrayIcon': showTrayIcon,
    'trayTripleClickNext': trayTripleClickNext,
    'tripleClickWindowMs': tripleClickWindowMs,
    'windowTripleClickNext': windowTripleClickNext,
    'hotkeyEnabled': hotkeyEnabled,
    'hotkeyKeyId': hotkeyKey.keyId,
    'hotkeyModifiers': hotkeyModifiers.map((m) => m.name).toList(),
    'prefetchNext': prefetchNext,
    'filterNsfw': filterNsfw,
    'skipUsedHashes': skipUsedHashes,
    'maxUsedHashEntries': maxUsedHashEntries,
    'httpTimeoutSeconds': httpTimeoutSeconds,
    'androidWallpaperLocation': androidWallpaperLocation,
    'runAtStartup': runAtStartup,
    'onlyWifiDownloads': onlyWifiDownloads,
    'reduceMotion': reduceMotion,
    'accentColorValue': accentColorValue,
    'denseUi': denseUi,
    'showEngineLogPanel': showEngineLogPanel,
    'lastWindowWidth': lastWindowWidth,
    'lastWindowHeight': lastWindowHeight,
  };

  static AppSettings fromJson(Map<String, dynamic> j) {
    HotKeyModifier parseMod(String s) => HotKeyModifier.values.firstWhere(
      (e) => e.name == s,
      orElse: () => HotKeyModifier.alt,
    );
    final keyId =
        (j['hotkeyKeyId'] as num?)?.toInt() ?? LogicalKeyboardKey.keyW.keyId;
    final key =
        LogicalKeyboardKey.findKeyByKeyId(keyId) ?? LogicalKeyboardKey.keyW;
    final mods =
        (j['hotkeyModifiers'] as List?)
            ?.map((e) => parseMod(e as String))
            .toList() ??
        const [HotKeyModifier.alt, HotKeyModifier.shift];
    return AppSettings(
      rssUrl: j['rssUrl'] as String? ?? defaultRss,
      proxyFirst: j['proxyFirst'] as bool? ?? true,
      intervalSeconds:
          (j['intervalSeconds'] as num?)?.toInt() ?? defaultIntervalSeconds,
      maxCachedFiles: (j['maxCachedFiles'] as num?)?.toInt() ?? 10,
      minWidth: (j['minWidth'] as num?)?.toInt() ?? 1920,
      minHeight: (j['minHeight'] as num?)?.toInt() ?? 1080,
      orientation: WallpaperOrientation.values.firstWhere(
        (o) => o.name == (j['orientation'] as String?),
        orElse: () => WallpaperOrientation.landscape,
      ),
      minimizeToTrayOnClose: j['minimizeToTrayOnClose'] as bool? ?? true,
      startHiddenInTray: j['startHiddenInTray'] as bool? ?? false,
      showTrayIcon: j['showTrayIcon'] as bool? ?? true,
      trayTripleClickNext: j['trayTripleClickNext'] as bool? ?? true,
      tripleClickWindowMs: (j['tripleClickWindowMs'] as num?)?.toInt() ?? 650,
      windowTripleClickNext: j['windowTripleClickNext'] as bool? ?? true,
      hotkeyEnabled: j['hotkeyEnabled'] as bool? ?? true,
      hotkeyKey: key,
      hotkeyModifiers: mods,
      prefetchNext: j['prefetchNext'] as bool? ?? true,
      filterNsfw: j['filterNsfw'] as bool? ?? true,
      skipUsedHashes: j['skipUsedHashes'] as bool? ?? true,
      maxUsedHashEntries: (j['maxUsedHashEntries'] as num?)?.toInt() ?? 4000,
      httpTimeoutSeconds: (j['httpTimeoutSeconds'] as num?)?.toInt() ?? 35,
      androidWallpaperLocation:
          (j['androidWallpaperLocation'] as num?)?.toInt() ?? 1,
      runAtStartup: j['runAtStartup'] as bool? ?? false,
      onlyWifiDownloads: j['onlyWifiDownloads'] as bool? ?? false,
      reduceMotion: j['reduceMotion'] as bool? ?? false,
      accentColorValue: (j['accentColorValue'] as num?)?.toInt() ?? 0xFF1B4332,
      denseUi: j['denseUi'] as bool? ?? false,
      showEngineLogPanel: j['showEngineLogPanel'] as bool? ?? true,
      lastWindowWidth: (j['lastWindowWidth'] as num?)?.toDouble() ?? 1040,
      lastWindowHeight: (j['lastWindowHeight'] as num?)?.toDouble() ?? 720,
    );
  }

  static String encode(AppSettings s) => jsonEncode(s.toJson());

  static AppSettings decode(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettings.fromJson(map);
    } catch (_) {
      return AppSettings.defaults();
    }
  }
}
