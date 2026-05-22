import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

import '../models/app_settings.dart';
import '../models/wallpaper_candidate.dart';
import '../models/wallpaper_orientation.dart';
import 'feed_client.dart';
import 'image_fetch_prefs.dart';
import 'settings_repository.dart';
import 'url_normalizer.dart';
import 'wallpaper_apply_service.dart';

/// Orchestrates RSS → download → validate → apply, cache rotation, prefetch, history.
class WallpaperEngine extends ChangeNotifier {
  WallpaperEngine({
    required SettingsRepository settingsRepository,
    FeedClient? feedClient,
    WallpaperApplyService? applyService,
    http.Client? httpClient,
  }) : _settingsRepository = settingsRepository,
       _feed = feedClient ?? FeedClient(httpClient: httpClient),
       _apply = applyService ?? WallpaperApplyService();

  final SettingsRepository _settingsRepository;
  final FeedClient _feed;
  final WallpaperApplyService _apply;
  final Lock _lock = Lock();

  Timer? _timer;
  DateTime _nextScheduledWallpaperAt = DateTime.now();
  bool _scheduledWallpaperTick = false;
  static const Duration _schedulePollInterval = Duration(seconds: 15);

  String _log = '';
  String? _currentWallpaperPath;
  bool _running = false;

  String get logText => _log;
  String? get currentWallpaperPath => _currentWallpaperPath;
  bool get isRunning => _running;

  AppSettings get settings => _settingsRepository.settings;

  static const _kPersistedWallpaperPath = 'wallpaper_current_path_v1';

  /// Grey strip "triple tap" works only when enabled and (if configured) we have a file this app applied.
  bool isTripleStripActive() {
    final s = settings;
    if (!s.windowTripleClickNext) return false;
    if (!s.tripleTapOnlyIfAppliedByApp) return true;
    final p = _currentWallpaperPath;
    if (p == null || !File(p).existsSync()) return false;
    return true;
  }

  Future<void> _restorePersistedWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_kPersistedWallpaperPath);
    if (path == null) return;
    if (!File(path).existsSync()) {
      await prefs.remove(_kPersistedWallpaperPath);
      return;
    }
    _currentWallpaperPath = path;
    notifyListeners();
  }

  Future<void> _rememberAppliedWallpaper(String path) async {
    _currentWallpaperPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPersistedWallpaperPath, path);
    notifyListeners();
  }

  void _append(String line) {
    _log = '$_log\n$line'.trim();
    if (_log.length > 12000) {
      _log = _log.substring(_log.length - 8000);
    }
    notifyListeners();
  }

  Future<bool> _wifiOk() async {
    final s = settings;
    if (!Platform.isAndroid || !s.onlyWifiDownloads) return true;
    try {
      final c = await Connectivity().checkConnectivity();
      if (c.contains(ConnectivityResult.none)) {
        _append('Нет сети — загрузка отложена.');
        return false;
      }
      if (c.contains(ConnectivityResult.wifi) ||
          c.contains(ConnectivityResult.ethernet)) {
        return true;
      }
      _append('Загрузка отложена: включено «только Wi‑Fi / Ethernet».');
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<void> reloadSettings() async {
    await _settingsRepository.load();
    notifyListeners();
  }

  /// After OS sleep or app resume: catch up if a scheduled rotation was missed.
  void onAppLifecycleResumed() {
    if (!_running) return;
    if (!_scheduledWallpaperTick &&
        !DateTime.now().isBefore(_nextScheduledWallpaperAt)) {
      unawaited(_schedulePollCallback());
    }
  }

  /// Absolute directory used for `wp_*.jpg`, prefetch files, and temp downloads.
  Future<String> wallpaperCacheDirectoryPath() async {
    final d = await _wallpaperDir();
    return d.path;
  }

  Future<void> start() async {
    await _settingsRepository.load();
    await _ensureDirs();
    await _restorePersistedWallpaper();
    _running = true;
    notifyListeners();
    final pf = await advanceFromNetwork(reason: 'Старт: сразу новая картинка');
    if (pf) unawaited(_prefetchWorker());
    _armTimer();
  }

  void _armTimer() {
    _timer?.cancel();
    if (!_running) return;
    final sec = _settingsRepository.settings.intervalSeconds.clamp(60, 604800);
    _nextScheduledWallpaperAt = DateTime.now().add(Duration(seconds: sec));
    _timer = Timer.periodic(_schedulePollInterval, (_) {
      unawaited(_schedulePollCallback());
    });
  }

  Future<void> _schedulePollCallback() async {
    if (!_running) return;
    if (_scheduledWallpaperTick) return;
    if (DateTime.now().isBefore(_nextScheduledWallpaperAt)) return;
    _scheduledWallpaperTick = true;
    try {
      final pf = await advanceFromNetwork(reason: 'По расписанию');
      if (pf) unawaited(_prefetchWorker());
    } finally {
      _scheduledWallpaperTick = false;
    }
    final sec = _settingsRepository.settings.intervalSeconds.clamp(60, 604800);
    _nextScheduledWallpaperAt = DateTime.now().add(Duration(seconds: sec));
  }

  void updateTimerFromSettings() {
    _armTimer();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _running = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feed.close();
    super.dispose();
  }

  static const int _maxRssPages = 15;

  /// Walks Reddit `rel="next"` pages (and `limit=100` on first URL) so one
  /// refresh sees more than a single RSS chunk (~25–100 posts).
  Future<List<WallpaperCandidate>> _gatherFeedCandidates(
    AppSettings s, {
    bool logPageCount = false,
  }) async {
    final merged = <WallpaperCandidate>[];
    final seen = <String>{};
    var pageUrl = FeedClient.rssUrlWithLimit(s.rssUrl);
    final timeout = Duration(seconds: s.httpTimeoutSeconds);
    var pages = 0;
    for (var i = 0; i < _maxRssPages; i++) {
      pages++;
      final xml = await _feed.fetchRssXml(
        rssUrl: pageUrl,
        proxyFirst: s.proxyFirst,
        timeout: timeout,
      );
      if (xml == null || xml.isEmpty) break;
      List<WallpaperCandidate> batch;
      try {
        batch = _feed.parseCandidates(xml);
      } catch (_) {
        break;
      }
      for (final c in batch) {
        if (seen.add(c.url)) merged.add(c);
      }
      final next = _feed.parseNextFeedUrl(xml);
      if (next == null || next.isEmpty) break;
      final n = next.trim();
      if (n == pageUrl) break;
      pageUrl = n;
    }
    FeedClient.sortWallpaperCandidates(merged);
    if (logPageCount && pages > 1) {
      _append(
        'RSS: просмотрено $pages страниц ленты, уникальных ссылок на картинки: ${merged.length}.',
      );
    }
    return merged;
  }

  /// Next wallpaper: use prefetch file if valid, otherwise download.
  Future<void> nextWallpaperQuick() async {
    var prefetchLater = false;
    await _lock.synchronized(() async {
      if (!await _wifiOk()) {
        notifyListeners();
        return;
      }
      final dir = await _wallpaperDir();
      final legacyImg = File(p.join(dir.path, '_prefetch_next.jpg'));
      final legacyMeta = File(p.join(dir.path, '_prefetch_meta.txt'));
      if (legacyImg.existsSync()) {
        if (await _tryConsumePrefetchFile(dir, legacyImg, legacyMeta)) {
          prefetchLater = settings.prefetchNext;
          return;
        }
      }
      final cap = settings.prefetchSlots.clamp(1, 8);
      for (var slot = 0; slot < cap; slot++) {
        final img = File(p.join(dir.path, '_prefetch_$slot.jpg'));
        final meta = File(p.join(dir.path, '_prefetch_$slot.meta'));
        if (!img.existsSync()) continue;
        if (await _tryConsumePrefetchFile(dir, img, meta)) {
          prefetchLater = settings.prefetchNext;
          return;
        }
      }
    });
    if (prefetchLater) {
      unawaited(_prefetchWorker());
      return;
    }
    final pf = await advanceFromNetwork(reason: 'Быстрая смена (без prefetch)');
    if (pf) unawaited(_prefetchWorker());
  }

  Future<bool> _tryConsumePrefetchFile(
    Directory dir,
    File prefetch,
    File meta,
  ) async {
    if (!await _validateFile(prefetch)) {
      await _safeDelete(prefetch);
      await _safeDelete(meta);
      return false;
    }
    final dest = File(
      p.join(dir.path, 'wp_${DateTime.now().millisecondsSinceEpoch}.jpg'),
    );
    await prefetch.rename(dest.path);
    final ok = await _apply.apply(dest, settings: settings);
    if (!ok) {
      await _safeDelete(dest);
      await _safeDelete(meta);
      return false;
    }
    var hash = '';
    String? title;
    if (meta.existsSync()) {
      final raw = (await meta.readAsString()).trim();
      if (raw.isNotEmpty) {
        final i = raw.indexOf('\n');
        if (i < 0) {
          hash = raw;
        } else {
          hash = raw.substring(0, i).trim();
          final rest = raw.substring(i + 1).trim();
          title = rest.isEmpty ? null : rest;
        }
      }
      await _safeDelete(meta);
    }
    if (hash.isNotEmpty) {
      await _registerUsed(hash, settings.maxUsedHashEntries);
    }
    await _rememberAppliedWallpaper(dest.path);
    await _rotateCache(dir);
    if (title != null && title.isNotEmpty) {
      _append('Обои: $title');
    } else {
      _append('Обои: (из запаса)');
    }
    _append('Быстрая смена из запаса (prefetch).');
    notifyListeners();
    return true;
  }

  /// Returns whether prefetch should run after this call completes.
  Future<bool> advanceFromNetwork({required String reason}) async {
    var prefetchAfter = false;
    await _lock.synchronized(() async {
      _append('— $reason');
      if (!await _wifiOk()) {
        notifyListeners();
        return;
      }
      final s = settings;
      List<WallpaperCandidate> list;
      try {
        list = await _gatherFeedCandidates(s, logPageCount: true);
      } catch (e, st) {
        _append('Ошибка загрузки RSS: $e');
        debugPrint('$st');
        notifyListeners();
        return;
      }
      if (list.isEmpty) {
        _append('В ленте нет изображений (или RSS не отдал записей).');
        notifyListeners();
        return;
      }

      final used = await _loadUsedHashes();
      final dir = await _wallpaperDir();

      for (final c in list) {
        final h = imageIdentityHash(c.url);
        if (s.skipUsedHashes && used.contains(h)) continue;
        if (!titleOrientationMatches(c.title, s.orientation)) continue;

        final tmp = File(
          p.join(
            dir.path,
            '_tmp_${DateTime.now().microsecondsSinceEpoch}.part',
          ),
        );
        final okDl = await _download(c.url, tmp, s.httpTimeoutSeconds);
        if (!okDl) {
          await _safeDelete(tmp);
          continue;
        }

        if (!await _validateFile(tmp)) {
          await _safeDelete(tmp);
          continue;
        }

        final dest = File(
          p.join(dir.path, 'wp_${DateTime.now().millisecondsSinceEpoch}.jpg'),
        );
        await tmp.rename(dest.path);

        final applied = await _apply.apply(dest, settings: s);
        if (!applied) {
          _append('Не удалось применить обои (права ОС / тип сессии).');
          await _safeDelete(dest);
          continue;
        }

        await _registerUsed(h, s.maxUsedHashEntries);
        await _rememberAppliedWallpaper(dest.path);
        await _rotateCache(dir);
        _append('Обои: ${c.title}');
        notifyListeners();

        prefetchAfter = s.prefetchNext;
        return;
      }
      _append(
        'Сейчас нет кадра, который проходит ваши настройки (фильтры, история «не повторять», минимум ${s.minWidth}×${s.minHeight}, ориентация). '
        'Проверьте параметры в настройках, при необходимости ослабьте фильтры или очистите историю.',
      );
      notifyListeners();
    });
    return prefetchAfter;
  }

  Future<void> _prefetchWorker() async {
    if (!await _wifiOk()) return;
    final s = settings;
    final n = s.prefetchSlots.clamp(1, 8);
    final dir = await _wallpaperDir();
    for (var slot = n; slot < 8; slot++) {
      await _safeDelete(File(p.join(dir.path, '_prefetch_$slot.jpg')));
      await _safeDelete(File(p.join(dir.path, '_prefetch_$slot.meta')));
    }
    for (var slot = 0; slot < n; slot++) {
      final img = File(p.join(dir.path, '_prefetch_$slot.jpg'));
      final meta = File(p.join(dir.path, '_prefetch_$slot.meta'));
      if (img.existsSync() && await _validateFile(img)) continue;
      await _safeDelete(img);
      await _safeDelete(meta);
      List<WallpaperCandidate> list;
      try {
        list = await _gatherFeedCandidates(s);
      } catch (_) {
        return;
      }
      if (list.isEmpty) return;
      final used = await _loadUsedHashes();
      var placed = false;
      for (final c in list) {
        final h = imageIdentityHash(c.url);
        if (s.skipUsedHashes && used.contains(h)) continue;
        if (!titleOrientationMatches(c.title, s.orientation)) continue;
        final tmp = File(
          p.join(
            dir.path,
            '_tmp_prefetch_${slot}_${DateTime.now().microsecondsSinceEpoch}.part',
          ),
        );
        final okDl = await _download(c.url, tmp, s.httpTimeoutSeconds);
        if (!okDl) {
          await _safeDelete(tmp);
          continue;
        }
        if (!await _validateFile(tmp)) {
          await _safeDelete(tmp);
          continue;
        }
        await _lock.synchronized(() async {
          if (img.existsSync()) {
            await _safeDelete(tmp);
            return;
          }
          await tmp.rename(img.path);
          await meta.writeAsString('$h\n${c.title}', flush: true);
        });
        _append('Запасная картинка загружена: ${c.title}');
        notifyListeners();
        placed = true;
        break;
      }
      if (!placed) return;
    }
  }

  Future<bool> _download(String url, File dest, int timeoutSec) async {
    final headers = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (EarthPornWallpaper/1.0; by eturnercus) AppleWebKit/537.36',
    };
    final timeout = Duration(seconds: timeoutSec);
    final candidates = redditImageDownloadCandidates(url);
    final preferred = await ImageFetchPrefs.loadPreferred();
    final channelOrder = ImageFetchPrefs.ordered(preferred);

    Future<bool> tryOnce(
      String u,
      String channelRu, {
      bool announceOk = false,
    }) async {
      final client = http.Client();
      try {
        final r = await client
            .get(Uri.parse(u), headers: headers)
            .timeout(timeout);
        if (r.statusCode >= 200 &&
            r.statusCode < 300 &&
            r.bodyBytes.isNotEmpty) {
          await dest.writeAsBytes(r.bodyBytes, flush: true);
          if (announceOk) {
            _append('Скачивание через $channelRu.');
          }
          return true;
        }
        _append('Скачивание ($channelRu): HTTP ${r.statusCode}.');
        return false;
      } catch (e) {
        _append('Скачивание ($channelRu): $e');
        return false;
      } finally {
        client.close();
      }
    }

    for (final channel in channelOrder) {
      if (channel == ImageFetchChannel.direct) {
        for (final c in candidates) {
          if (await tryOnce(c, 'прямой канал')) {
            await ImageFetchPrefs.savePreferred(ImageFetchChannel.direct);
            return true;
          }
        }
      } else if (channel == ImageFetchChannel.allOrigins) {
        for (final c in candidates) {
          if (await tryOnce(
            FeedClient.allOriginsRawUrl(c),
            'AllOrigins',
            announceOk: true,
          )) {
            await ImageFetchPrefs.savePreferred(ImageFetchChannel.allOrigins);
            return true;
          }
        }
      } else {
        for (final c in candidates) {
          if (await tryOnce(
            FeedClient.corsProxyIoUrl(c),
            'corsproxy.io',
            announceOk: true,
          )) {
            await ImageFetchPrefs.savePreferred(ImageFetchChannel.corsProxy);
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<bool> _validateFile(File f) async {
    final s = settings;
    late Size size;
    try {
      size = ImageSizeGetter.getSizeResult(FileInput(f)).size;
    } catch (e) {
      _append('Не картинка или битый файл: $e');
      return false;
    }
    var w = size.width;
    var h = size.height;
    if (size.needRotate) {
      final t = w;
      w = h;
      h = t;
    }
    if (w < s.minWidth || h < s.minHeight) {
      _append('Мало пикселей: ${w}x$h (мин ${s.minWidth}×${s.minHeight})');
      return false;
    }
    switch (s.orientation) {
      case WallpaperOrientation.landscape:
        if (h > w) {
          _append('Режим «ландшафт»: кадр вертикальный ($w×$h), пропуск.');
          return false;
        }
        break;
      case WallpaperOrientation.portrait:
        if (w > h) {
          _append('Режим «портрет»: кадр горизонтальный ($w×$h), пропуск.');
          return false;
        }
        break;
      case WallpaperOrientation.any:
        break;
    }
    return true;
  }

  String _expandUserPath(String raw) {
    var t = raw.trim();
    if (t.isEmpty) return '';
    if (t == '~') {
      return Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
    }
    if (t.startsWith('~/') || t.startsWith('~\\')) {
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      if (home.isEmpty) return t;
      return p.join(home, t.substring(2));
    }
    return t;
  }

  Future<Directory> _wallpaperDir() async {
    final configured = _expandUserPath(settings.wallpaperStoragePath);
    if (configured.isNotEmpty) {
      try {
        final d = Directory(configured);
        if (!await d.exists()) {
          await d.create(recursive: true);
        }
        return d;
      } catch (e) {
        _append(
          'Каталог из настроек недоступен ($configured): $e. Используется каталог приложения.',
        );
      }
    }
    final base = await getApplicationSupportDirectory();
    final d = Directory(p.join(base.path, 'wallpapers'));
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  Future<void> _ensureDirs() async {
    await _wallpaperDir();
  }

  Future<void> _rotateCache(Directory dir) async {
    final max = settings.maxCachedFiles.clamp(1, 50);
    final files =
        dir.listSync().whereType<File>().where((f) {
          final n = p.basename(f.path);
          return n.startsWith('wp_') && n.endsWith('.jpg');
        }).toList()..sort(
          (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
        );

    while (files.length > max) {
      final oldest = files.removeAt(0);
      try {
        await oldest.delete();
        _append('Удалён старый кэш: ${p.basename(oldest.path)}');
      } catch (_) {}
    }
  }

  Future<Set<String>> _loadUsedHashes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('used_image_hashes_json');
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _registerUsed(String hash, int maxEntries) async {
    final prefs = await SharedPreferences.getInstance();
    var list = <String>[];
    final raw = prefs.getString('used_image_hashes_json');
    if (raw != null && raw.isNotEmpty) {
      try {
        list = (jsonDecode(raw) as List).cast<String>();
      } catch (_) {}
    }
    if (!list.contains(hash)) list.add(hash);
    while (list.length > maxEntries) {
      list.removeAt(0);
    }
    await prefs.setString('used_image_hashes_json', jsonEncode(list));
  }

  Future<void> _safeDelete(File? f) async {
    if (f == null || !f.existsSync()) return;
    try {
      await f.delete();
    } catch (_) {}
  }

  /// After a successful [advanceFromNetwork], prefetch the next image in background.
  Future<void> triggerPrefetch() => _prefetchWorker();
}
