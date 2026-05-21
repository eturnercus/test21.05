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
  })  : _settingsRepository = settingsRepository,
        _feed = feedClient ?? FeedClient(httpClient: httpClient),
        _apply = applyService ?? WallpaperApplyService();

  final SettingsRepository _settingsRepository;
  final FeedClient _feed;
  final WallpaperApplyService _apply;
  final Lock _lock = Lock();

  Timer? _timer;
  String _log = '';
  String? _currentWallpaperPath;
  bool _running = false;

  String get logText => _log;
  String? get currentWallpaperPath => _currentWallpaperPath;
  bool get isRunning => _running;

  AppSettings get settings => _settingsRepository.settings;

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

  Future<void> start() async {
    await _settingsRepository.load();
    await _ensureDirs();
    _running = true;
    notifyListeners();
    final pf = await advanceFromNetwork(reason: 'Старт: сразу новая картинка');
    if (pf) unawaited(_prefetchWorker());
    _armTimer();
  }

  void _armTimer() {
    _timer?.cancel();
    final sec = _settingsRepository.settings.intervalSeconds.clamp(60, 604800);
    _timer = Timer.periodic(Duration(seconds: sec), (_) {
      unawaited(_scheduledTick());
    });
  }

  Future<void> _scheduledTick() async {
    final pf = await advanceFromNetwork(reason: 'По расписанию');
    if (pf) unawaited(_prefetchWorker());
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

  /// Next wallpaper: use prefetch file if valid, otherwise download.
  Future<void> nextWallpaperQuick() async {
    var prefetchLater = false;
    await _lock.synchronized(() async {
      if (!await _wifiOk()) {
        notifyListeners();
        return;
      }
      final dir = await _wallpaperDir();
      final prefetch = File(p.join(dir.path, '_prefetch_next.jpg'));
      final meta = File(p.join(dir.path, '_prefetch_meta.txt'));
      if (prefetch.existsSync()) {
        if (await _validateFile(prefetch)) {
          final dest = File(p.join(dir.path, 'wp_${DateTime.now().millisecondsSinceEpoch}.jpg'));
          await prefetch.rename(dest.path);
          final ok = await _apply.apply(
            dest,
            androidLocation: settings.androidWallpaperLocation,
          );
          if (ok) {
            _currentWallpaperPath = dest.path;
            if (meta.existsSync()) {
              final h = (await meta.readAsString()).trim();
              if (h.isNotEmpty) {
                await _registerUsed(h, settings.maxUsedHashEntries);
              }
              await _safeDelete(meta);
            }
            await _rotateCache(dir);
            _append('Быстрая смена из запаса (prefetch).');
            notifyListeners();
            prefetchLater = settings.prefetchNext;
            return;
          }
          await _safeDelete(dest);
        }
        await _safeDelete(prefetch);
        await _safeDelete(meta);
      }
    });
    if (prefetchLater) {
      unawaited(_prefetchWorker());
      return;
    }
    final pf = await advanceFromNetwork(reason: 'Быстрая смена (без prefetch)');
    if (pf) unawaited(_prefetchWorker());
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
      final xml = await _feed.fetchRssXml(
        rssUrl: s.rssUrl,
        proxyFirst: s.proxyFirst,
        timeout: Duration(seconds: s.httpTimeoutSeconds),
      );
      if (xml == null || xml.isEmpty) {
        _append('RSS недоступен (проверьте интернет).');
        notifyListeners();
        return;
      }
      List<WallpaperCandidate> list;
      try {
        list = _feed.parseCandidates(xml);
      } catch (e) {
        _append('Ошибка разбора RSS: $e');
        notifyListeners();
        return;
      }
      if (list.isEmpty) {
        _append('В ленте нет изображений.');
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
            p.join(dir.path, '_tmp_${DateTime.now().microsecondsSinceEpoch}.part'));
        final okDl = await _download(c.url, tmp, s.httpTimeoutSeconds);
        if (!okDl) {
          await _safeDelete(tmp);
          continue;
        }

        if (!await _validateFile(tmp)) {
          await _safeDelete(tmp);
          continue;
        }

        final dest = File(p.join(dir.path, 'wp_${DateTime.now().millisecondsSinceEpoch}.jpg'));
        await tmp.rename(dest.path);

        final applied = await _apply.apply(
          dest,
          androidLocation: s.androidWallpaperLocation,
        );
        if (!applied) {
          _append('Не удалось применить обои (права ОС / тип сессии).');
          await _safeDelete(dest);
          continue;
        }

        await _registerUsed(h, s.maxUsedHashEntries);
        _currentWallpaperPath = dest.path;
        await _rotateCache(dir);
        _append('Обои: ${c.title}');
        notifyListeners();

        prefetchAfter = s.prefetchNext;
        return;
      }
      _append('Нет подходящих новых изображений (фильтры / история).');
      notifyListeners();
    });
    return prefetchAfter;
  }

  Future<void> _prefetchWorker() async {
    await _lock.synchronized(() async {
      if (!await _wifiOk()) return;
      final s = settings;
      final xml = await _feed.fetchRssXml(
        rssUrl: s.rssUrl,
        proxyFirst: s.proxyFirst,
        timeout: Duration(seconds: s.httpTimeoutSeconds),
      );
      if (xml == null) return;
      List<WallpaperCandidate> list;
      try {
        list = _feed.parseCandidates(xml);
      } catch (_) {
        return;
      }
      final used = await _loadUsedHashes();
      final dir = await _wallpaperDir();
      final prefetch = File(p.join(dir.path, '_prefetch_next.jpg'));
      final meta = File(p.join(dir.path, '_prefetch_meta.txt'));
      await _safeDelete(prefetch);
      await _safeDelete(meta);

      for (final c in list) {
        final h = imageIdentityHash(c.url);
        if (s.skipUsedHashes && used.contains(h)) continue;
        if (!titleOrientationMatches(c.title, s.orientation)) continue;
        final okDl = await _download(c.url, prefetch, s.httpTimeoutSeconds);
        if (!okDl) {
          await _safeDelete(prefetch);
          continue;
        }
        if (!await _validateFile(prefetch)) {
          await _safeDelete(prefetch);
          continue;
        }
        await meta.writeAsString(h, flush: true);
        _append('Запасная картинка загружена.');
        notifyListeners();
        return;
      }
    });
  }

  Future<bool> _download(String url, File dest, int timeoutSec) async {
    final headers = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (EarthPornWallpaper/1.0; by eturnercus) AppleWebKit/537.36',
    };
    final timeout = Duration(seconds: timeoutSec);
    final candidates = redditImageDownloadCandidates(url);

    Future<bool> tryOnce(String u, String channelRu, {bool announceOk = false}) async {
      final client = http.Client();
      try {
        final r = await client.get(Uri.parse(u), headers: headers).timeout(timeout);
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

    for (final c in candidates) {
      if (await tryOnce(c, 'прямой канал')) return true;
    }
    for (final c in candidates) {
      if (await tryOnce(
            FeedClient.allOriginsRawUrl(c),
            'AllOrigins',
            announceOk: true,
          )) {
        return true;
      }
    }
    for (final c in candidates) {
      if (await tryOnce(
            FeedClient.corsProxyIoUrl(c),
            'corsproxy.io',
            announceOk: true,
          )) {
        return true;
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

  Future<Directory> _wallpaperDir() async {
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
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) {
          final n = p.basename(f.path);
          return n.startsWith('wp_') && n.endsWith('.jpg');
        })
        .toList()
      ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

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
