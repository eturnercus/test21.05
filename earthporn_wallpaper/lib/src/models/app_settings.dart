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
    required this.tripleTapOnlyIfAppliedByApp,
    required this.hotkeyEnabled,
    required this.hotkeyKey,
    required this.hotkeyModifiers,
    required this.prefetchNext,
    required this.prefetchSlots,
    required this.wallpaperStoragePath,
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
    required this.uiLanguageCode,
    required this.androidGyroParallaxEnabled,
    required this.androidGyroParallaxScale,
    required this.androidGyroMaxOffsetDp,
    required this.androidGyroSmoothing,
    required this.androidGyroInvertX,
    required this.androidGyroInvertY,
    required this.androidPagerParallaxEnabled,
    required this.androidPagerVirtualPages,
    required this.androidPagerStrengthDp,
    required this.androidPagerSmoothing,
    required this.windowsSpanAllMonitors,
    required this.windowsSpanFitMode,
    required this.windowsSpanBezelPx,
    required this.windowsSpanJpegQuality,
    required this.offlineWallpaperBehavior,
    required this.checkGithubUpdates,
    this.lastWindowWidth = 1040,
    this.lastWindowHeight = 720,
  });

  static const String creator = 'eturnercus';

  static const String defaultRss = 'https://www.reddit.com/r/EarthPorn/.rss';

  /// Default wallpaper refresh interval: **30 minutes** (1800 seconds).
  static const int defaultIntervalSeconds = 1800;

  /// 0 = follow OS, 1 = ru, 2 = en
  static const int uiLanguageSystem = 0;
  static const int uiLanguageRu = 1;
  static const int uiLanguageEn = 2;

  /// Windows span: 0 = cover (fill virtual desktop), 1 = contain (letterbox)
  static const int windowsSpanFitFill = 0;
  static const int windowsSpanFitContain = 1;

  /// When there is no usable network (desktop: no link; Android: optional Wi‑Fi gate).
  static const int offlineTryNetwork = 0;
  static const int offlinePauseScheduled = 1;
  static const int offlineCycleCache = 2;

  static const int prefetchSlotsMax = 32;

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
    tripleTapOnlyIfAppliedByApp: true,
    hotkeyEnabled: true,
    hotkeyKey: LogicalKeyboardKey.keyW,
    hotkeyModifiers: const [HotKeyModifier.alt, HotKeyModifier.shift],
    prefetchNext: true,
    prefetchSlots: 1,
    wallpaperStoragePath: '',
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
    uiLanguageCode: uiLanguageSystem,
    androidGyroParallaxEnabled: false,
    androidGyroParallaxScale: 1.08,
    androidGyroMaxOffsetDp: 16,
    androidGyroSmoothing: 0.18,
    androidGyroInvertX: false,
    androidGyroInvertY: false,
    androidPagerParallaxEnabled: false,
    androidPagerVirtualPages: 5,
    androidPagerStrengthDp: 22,
    androidPagerSmoothing: 0.22,
    windowsSpanAllMonitors: false,
    windowsSpanFitMode: windowsSpanFitFill,
    windowsSpanBezelPx: 0,
    windowsSpanJpegQuality: 92,
    offlineWallpaperBehavior: offlineTryNetwork,
    checkGithubUpdates: true,
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

  /// Triple-tap strip advances only after this app has successfully applied a wallpaper
  /// (tracked file still exists).
  final bool tripleTapOnlyIfAppliedByApp;
  final bool hotkeyEnabled;
  final LogicalKeyboardKey hotkeyKey;
  final List<HotKeyModifier> hotkeyModifiers;
  final bool prefetchNext;

  /// How many `_prefetch_N` files to keep (1–[prefetchSlotsMax]).
  final int prefetchSlots;

  /// Optional absolute directory for `wp_*.jpg` / prefetch files. Empty = app support dir.
  final String wallpaperStoragePath;

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

  final int uiLanguageCode;

  /// In-app preview on Android: slight zoom + tilt from accelerometer (not system wallpaper).
  final bool androidGyroParallaxEnabled;
  final double androidGyroParallaxScale;
  final double androidGyroMaxOffsetDp;
  final double androidGyroSmoothing;
  final bool androidGyroInvertX;
  final bool androidGyroInvertY;

  /// In-app horizontal pager preview: image shifts when swiping between pages.
  final bool androidPagerParallaxEnabled;
  final int androidPagerVirtualPages;
  final double androidPagerStrengthDp;
  final double androidPagerSmoothing;

  /// Windows: build one image covering the virtual screen (all monitors), then set as wallpaper.
  final bool windowsSpanAllMonitors;
  final int windowsSpanFitMode;
  final double windowsSpanBezelPx;
  final int windowsSpanJpegQuality;

  /// [offlineTryNetwork], [offlinePauseScheduled], or [offlineCycleCache].
  final int offlineWallpaperBehavior;

  /// Query GitHub Releases (throttled) and notify if a newer tag exists.
  final bool checkGithubUpdates;

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
    bool? tripleTapOnlyIfAppliedByApp,
    bool? hotkeyEnabled,
    LogicalKeyboardKey? hotkeyKey,
    List<HotKeyModifier>? hotkeyModifiers,
    bool? prefetchNext,
    int? prefetchSlots,
    String? wallpaperStoragePath,
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
    int? uiLanguageCode,
    bool? androidGyroParallaxEnabled,
    double? androidGyroParallaxScale,
    double? androidGyroMaxOffsetDp,
    double? androidGyroSmoothing,
    bool? androidGyroInvertX,
    bool? androidGyroInvertY,
    bool? androidPagerParallaxEnabled,
    int? androidPagerVirtualPages,
    double? androidPagerStrengthDp,
    double? androidPagerSmoothing,
    bool? windowsSpanAllMonitors,
    int? windowsSpanFitMode,
    double? windowsSpanBezelPx,
    int? windowsSpanJpegQuality,
    int? offlineWallpaperBehavior,
    bool? checkGithubUpdates,
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
      tripleTapOnlyIfAppliedByApp:
          tripleTapOnlyIfAppliedByApp ?? this.tripleTapOnlyIfAppliedByApp,
      hotkeyEnabled: hotkeyEnabled ?? this.hotkeyEnabled,
      hotkeyKey: hotkeyKey ?? this.hotkeyKey,
      hotkeyModifiers: hotkeyModifiers ?? this.hotkeyModifiers,
      prefetchNext: prefetchNext ?? this.prefetchNext,
      prefetchSlots: prefetchSlots ?? this.prefetchSlots,
      wallpaperStoragePath:
          wallpaperStoragePath ?? this.wallpaperStoragePath,
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
      uiLanguageCode: uiLanguageCode ?? this.uiLanguageCode,
      androidGyroParallaxEnabled:
          androidGyroParallaxEnabled ?? this.androidGyroParallaxEnabled,
      androidGyroParallaxScale:
          androidGyroParallaxScale ?? this.androidGyroParallaxScale,
      androidGyroMaxOffsetDp:
          androidGyroMaxOffsetDp ?? this.androidGyroMaxOffsetDp,
      androidGyroSmoothing: androidGyroSmoothing ?? this.androidGyroSmoothing,
      androidGyroInvertX: androidGyroInvertX ?? this.androidGyroInvertX,
      androidGyroInvertY: androidGyroInvertY ?? this.androidGyroInvertY,
      androidPagerParallaxEnabled:
          androidPagerParallaxEnabled ?? this.androidPagerParallaxEnabled,
      androidPagerVirtualPages:
          androidPagerVirtualPages ?? this.androidPagerVirtualPages,
      androidPagerStrengthDp:
          androidPagerStrengthDp ?? this.androidPagerStrengthDp,
      androidPagerSmoothing:
          androidPagerSmoothing ?? this.androidPagerSmoothing,
      windowsSpanAllMonitors:
          windowsSpanAllMonitors ?? this.windowsSpanAllMonitors,
      windowsSpanFitMode: windowsSpanFitMode ?? this.windowsSpanFitMode,
      windowsSpanBezelPx: windowsSpanBezelPx ?? this.windowsSpanBezelPx,
      windowsSpanJpegQuality:
          windowsSpanJpegQuality ?? this.windowsSpanJpegQuality,
      offlineWallpaperBehavior:
          offlineWallpaperBehavior ?? this.offlineWallpaperBehavior,
      checkGithubUpdates: checkGithubUpdates ?? this.checkGithubUpdates,
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
    'tripleTapOnlyIfAppliedByApp': tripleTapOnlyIfAppliedByApp,
    'hotkeyEnabled': hotkeyEnabled,
    'hotkeyKeyId': hotkeyKey.keyId,
    'hotkeyModifiers': hotkeyModifiers.map((m) => m.name).toList(),
    'prefetchNext': prefetchNext,
    'prefetchSlots': prefetchSlots,
    'wallpaperStoragePath': wallpaperStoragePath,
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
    'uiLanguageCode': uiLanguageCode,
    'androidGyroParallaxEnabled': androidGyroParallaxEnabled,
    'androidGyroParallaxScale': androidGyroParallaxScale,
    'androidGyroMaxOffsetDp': androidGyroMaxOffsetDp,
    'androidGyroSmoothing': androidGyroSmoothing,
    'androidGyroInvertX': androidGyroInvertX,
    'androidGyroInvertY': androidGyroInvertY,
    'androidPagerParallaxEnabled': androidPagerParallaxEnabled,
    'androidPagerVirtualPages': androidPagerVirtualPages,
    'androidPagerStrengthDp': androidPagerStrengthDp,
    'androidPagerSmoothing': androidPagerSmoothing,
    'windowsSpanAllMonitors': windowsSpanAllMonitors,
    'windowsSpanFitMode': windowsSpanFitMode,
    'windowsSpanBezelPx': windowsSpanBezelPx,
    'windowsSpanJpegQuality': windowsSpanJpegQuality,
    'offlineWallpaperBehavior': offlineWallpaperBehavior,
    'checkGithubUpdates': checkGithubUpdates,
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
      tripleTapOnlyIfAppliedByApp:
          j['tripleTapOnlyIfAppliedByApp'] as bool? ?? true,
      hotkeyEnabled: j['hotkeyEnabled'] as bool? ?? true,
      hotkeyKey: key,
      hotkeyModifiers: mods,
      prefetchNext: j['prefetchNext'] as bool? ?? true,
      prefetchSlots:
          ((j['prefetchSlots'] as num?)?.toInt() ?? 1).clamp(1, prefetchSlotsMax),
      wallpaperStoragePath: j['wallpaperStoragePath'] as String? ?? '',
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
      uiLanguageCode: (j['uiLanguageCode'] as num?)?.toInt() ?? uiLanguageSystem,
      androidGyroParallaxEnabled:
          j['androidGyroParallaxEnabled'] as bool? ?? false,
      androidGyroParallaxScale:
          (j['androidGyroParallaxScale'] as num?)?.toDouble() ?? 1.08,
      androidGyroMaxOffsetDp:
          (j['androidGyroMaxOffsetDp'] as num?)?.toDouble() ?? 16,
      androidGyroSmoothing:
          (j['androidGyroSmoothing'] as num?)?.toDouble() ?? 0.18,
      androidGyroInvertX: j['androidGyroInvertX'] as bool? ?? false,
      androidGyroInvertY: j['androidGyroInvertY'] as bool? ?? false,
      androidPagerParallaxEnabled:
          j['androidPagerParallaxEnabled'] as bool? ?? false,
      androidPagerVirtualPages:
          ((j['androidPagerVirtualPages'] as num?)?.toInt() ?? 5).clamp(3, 9),
      androidPagerStrengthDp:
          (j['androidPagerStrengthDp'] as num?)?.toDouble() ?? 22,
      androidPagerSmoothing:
          (j['androidPagerSmoothing'] as num?)?.toDouble() ?? 0.22,
      windowsSpanAllMonitors: j['windowsSpanAllMonitors'] as bool? ?? false,
      windowsSpanFitMode:
          (j['windowsSpanFitMode'] as num?)?.toInt() ?? windowsSpanFitFill,
      windowsSpanBezelPx:
          (j['windowsSpanBezelPx'] as num?)?.toDouble() ?? 0,
      windowsSpanJpegQuality:
          ((j['windowsSpanJpegQuality'] as num?)?.toInt() ?? 92).clamp(60, 100),
      offlineWallpaperBehavior:
          ((j['offlineWallpaperBehavior'] as num?)?.toInt() ?? offlineTryNetwork)
              .clamp(offlineTryNetwork, offlineCycleCache),
      checkGithubUpdates: j['checkGithubUpdates'] as bool? ?? true,
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
