import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../desktop/autostart_service.dart';
import '../desktop/desktop_integration.dart';
import '../models/app_settings.dart';
import '../models/wallpaper_orientation.dart';
import '../services/github_update_check.dart';
import '../services/settings_repository.dart';
import '../services/wallpaper_engine.dart';
import 'app_locale_text.dart';
import 'triple_empty_wallpaper_area.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _rss;
  late TextEditingController _interval;
  late TextEditingController _maxCache;
  late TextEditingController _prefetchSlots;
  late TextEditingController _wallpaperStorage;
  late TextEditingController _minW;
  late TextEditingController _minH;
  late TextEditingController _hashCap;
  late TextEditingController _httpTimeout;
  late TextEditingController _tripleMs;

  String _hotPreset = 'w';
  WallpaperOrientation _orientation = WallpaperOrientation.landscape;
  bool _proxyFirst = true;
  bool _minTray = true;
  bool _startTray = false;
  bool _showTray = true;
  bool _trayTriple = true;
  bool _winTriple = true;
  bool _hotOn = true;
  bool _prefetch = true;
  bool _nsfw = true;
  bool _skipUsed = true;
  int _androidLoc = 1;
  bool _runAtStartup = false;
  bool _onlyWifi = false;
  bool _reduceMotion = false;
  bool _denseUi = false;
  bool _showLog = true;
  int _accent = 0xFF1B4332;

  int _uiLanguageCode = AppSettings.uiLanguageSystem;
  bool _tripleTapOnlyIfAppliedByApp = true;
  bool _checkGithubUpdates = true;

  bool _androidGyroParallaxEnabled = false;
  double _androidGyroParallaxScale = 1.08;
  double _androidGyroMaxOffsetDp = 16;
  double _androidGyroSmoothing = 0.18;
  bool _androidGyroInvertX = false;
  bool _androidGyroInvertY = false;
  bool _androidPagerParallaxEnabled = false;
  int _androidPagerVirtualPages = 5;
  double _androidPagerStrengthDp = 22;
  double _androidPagerSmoothing = 0.22;

  bool _windowsSpanAllMonitors = false;
  int _windowsSpanFitMode = AppSettings.windowsSpanFitFill;
  double _windowsSpanBezelPx = 0;
  int _windowsSpanJpegQuality = 90;

  String? _resolvedCacheDir;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsRepository>().settings;
    _rss = TextEditingController(text: s.rssUrl);
    _interval = TextEditingController(
      text: '${(s.intervalSeconds / 60).round().clamp(1, 10080)}',
    );
    _maxCache = TextEditingController(text: '${s.maxCachedFiles}');
    _prefetchSlots = TextEditingController(text: '${s.prefetchSlots}');
    _wallpaperStorage = TextEditingController(text: s.wallpaperStoragePath);
    _minW = TextEditingController(text: '${s.minWidth}');
    _minH = TextEditingController(text: '${s.minHeight}');
    _hashCap = TextEditingController(text: '${s.maxUsedHashEntries}');
    _httpTimeout = TextEditingController(text: '${s.httpTimeoutSeconds}');
    _tripleMs = TextEditingController(text: '${s.tripleClickWindowMs}');
    _orientation = s.orientation;
    _proxyFirst = s.proxyFirst;
    _minTray = s.minimizeToTrayOnClose;
    _startTray = s.startHiddenInTray;
    _showTray = s.showTrayIcon;
    _trayTriple = s.trayTripleClickNext;
    _winTriple = s.windowTripleClickNext;
    _hotOn = s.hotkeyEnabled;
    _prefetch = s.prefetchNext;
    _nsfw = s.filterNsfw;
    _skipUsed = s.skipUsedHashes;
    _androidLoc = s.androidWallpaperLocation;
    _runAtStartup = s.runAtStartup;
    _onlyWifi = s.onlyWifiDownloads;
    _reduceMotion = s.reduceMotion;
    _denseUi = s.denseUi;
    _showLog = s.showEngineLogPanel;
    _accent = s.accentColorValue;
    _uiLanguageCode = s.uiLanguageCode;
    _tripleTapOnlyIfAppliedByApp = s.tripleTapOnlyIfAppliedByApp;
    _checkGithubUpdates = s.checkGithubUpdates;
    _androidGyroParallaxEnabled = s.androidGyroParallaxEnabled;
    _androidGyroParallaxScale = s.androidGyroParallaxScale;
    _androidGyroMaxOffsetDp = s.androidGyroMaxOffsetDp;
    _androidGyroSmoothing = s.androidGyroSmoothing;
    _androidGyroInvertX = s.androidGyroInvertX;
    _androidGyroInvertY = s.androidGyroInvertY;
    _androidPagerParallaxEnabled = s.androidPagerParallaxEnabled;
    _androidPagerVirtualPages = s.androidPagerVirtualPages;
    _androidPagerStrengthDp = s.androidPagerStrengthDp;
    _androidPagerSmoothing = s.androidPagerSmoothing;
    _windowsSpanAllMonitors = s.windowsSpanAllMonitors;
    _windowsSpanFitMode = s.windowsSpanFitMode;
    _windowsSpanBezelPx = s.windowsSpanBezelPx;
    _windowsSpanJpegQuality = s.windowsSpanJpegQuality;
    if (s.hotkeyKey == LogicalKeyboardKey.keyN) {
      _hotPreset = 'n';
    } else if (s.hotkeyKey == LogicalKeyboardKey.keyE) {
      _hotPreset = 'e';
    } else {
      _hotPreset = 'w';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refreshResolvedCachePath());
    });
  }

  Future<void> _refreshResolvedCachePath() async {
    final eng = context.read<WallpaperEngine>();
    final path = await eng.wallpaperCacheDirectoryPath();
    if (mounted) setState(() => _resolvedCacheDir = path);
  }

  @override
  void dispose() {
    _rss.dispose();
    _interval.dispose();
    _maxCache.dispose();
    _prefetchSlots.dispose();
    _wallpaperStorage.dispose();
    _minW.dispose();
    _minH.dispose();
    _hashCap.dispose();
    _httpTimeout.dispose();
    _tripleMs.dispose();
    super.dispose();
  }

  LogicalKeyboardKey _keyFromPreset() {
    return switch (_hotPreset) {
      'n' => LogicalKeyboardKey.keyN,
      'e' => LogicalKeyboardKey.keyE,
      _ => LogicalKeyboardKey.keyW,
    };
  }

  Future<void> _save() async {
    final repo = context.read<SettingsRepository>();
    final engine = context.read<WallpaperEngine>();
    final minutes =
        int.tryParse(_interval.text.trim()) ??
        (AppSettings.defaultIntervalSeconds ~/ 60);
    final intervalSeconds = (minutes * 60).clamp(60, 604800);
    final next = repo.settings.copyWith(
      rssUrl: _rss.text.trim(),
      proxyFirst: _proxyFirst,
      intervalSeconds: intervalSeconds,
      maxCachedFiles: int.tryParse(_maxCache.text) ?? 10,
      minWidth: int.tryParse(_minW.text) ?? 1920,
      minHeight: int.tryParse(_minH.text) ?? 1080,
      orientation: _orientation,
      minimizeToTrayOnClose: _minTray,
      startHiddenInTray: _startTray,
      showTrayIcon: _showTray,
      trayTripleClickNext: _trayTriple,
      windowTripleClickNext: _winTriple,
      hotkeyEnabled: _hotOn,
      hotkeyKey: _keyFromPreset(),
      hotkeyModifiers: const [HotKeyModifier.alt, HotKeyModifier.shift],
      prefetchNext: _prefetch,
      prefetchSlots: (int.tryParse(_prefetchSlots.text.trim()) ?? 1).clamp(1, 8),
      wallpaperStoragePath: _wallpaperStorage.text.trim(),
      filterNsfw: _nsfw,
      skipUsedHashes: _skipUsed,
      maxUsedHashEntries: int.tryParse(_hashCap.text) ?? 4000,
      httpTimeoutSeconds: int.tryParse(_httpTimeout.text) ?? 35,
      tripleClickWindowMs: int.tryParse(_tripleMs.text) ?? 650,
      androidWallpaperLocation: _androidLoc.clamp(1, 3),
      runAtStartup: _runAtStartup,
      onlyWifiDownloads: _onlyWifi,
      reduceMotion: _reduceMotion,
      denseUi: _denseUi,
      showEngineLogPanel: _showLog,
      accentColorValue: _accent,
      uiLanguageCode: _uiLanguageCode,
      tripleTapOnlyIfAppliedByApp: _tripleTapOnlyIfAppliedByApp,
      androidGyroParallaxEnabled: _androidGyroParallaxEnabled,
      androidGyroParallaxScale: _androidGyroParallaxScale,
      androidGyroMaxOffsetDp: _androidGyroMaxOffsetDp,
      androidGyroSmoothing: _androidGyroSmoothing,
      androidGyroInvertX: _androidGyroInvertX,
      androidGyroInvertY: _androidGyroInvertY,
      androidPagerParallaxEnabled: _androidPagerParallaxEnabled,
      androidPagerVirtualPages: _androidPagerVirtualPages,
      androidPagerStrengthDp: _androidPagerStrengthDp,
      androidPagerSmoothing: _androidPagerSmoothing,
      windowsSpanAllMonitors: _windowsSpanAllMonitors,
      windowsSpanFitMode: _windowsSpanFitMode,
      windowsSpanBezelPx: _windowsSpanBezelPx,
      windowsSpanJpegQuality: _windowsSpanJpegQuality,
      checkGithubUpdates: _checkGithubUpdates,
    );
    await repo.save(next);
    await engine.reloadSettings();
    engine.updateTimerFromSettings();
    await AutostartService.apply(next);
    if (!mounted) return;
    await refreshDesktopChrome(context);
    if (!mounted) return;
    await _refreshResolvedCachePath();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Сохранено')));
  }

  Future<void> _clearHistory() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('used_image_hashes_json');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('История использованных снимков очищена')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: Consumer2<WallpaperEngine, SettingsRepository>(
        builder: (context, engine, repo, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  children: [
                    Text(
                      t(context, ru: 'Общее', en: 'General'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _uiLanguageCode,
                      decoration: InputDecoration(
                        labelText: t(
                          context,
                          ru: 'Язык интерфейса',
                          en: 'Interface language',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: AppSettings.uiLanguageSystem,
                          child: Text(
                            t(context, ru: 'Как в системе', en: 'System'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: AppSettings.uiLanguageRu,
                          child: const Text('Русский'),
                        ),
                        DropdownMenuItem(
                          value: AppSettings.uiLanguageEn,
                          child: const Text('English'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _uiLanguageCode = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await context
                            .read<SettingsRepository>()
                            .requestShowMainHelpAgain();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              t(
                                context,
                                ru:
                                    'Закройте настройки и вернитесь на главную — появится подсказка.',
                                en:
                                    'Go back to Home to see the welcome sheet.',
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.help_outline),
                      label: Text(
                        t(
                          context,
                          ru: 'Показать приветствие снова',
                          en: 'Show welcome tips again',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(
                        t(
                          context,
                          ru:
                              'Тройной жест только после успешных обоев от приложения',
                          en: 'Triple-tap strip only after this app applied a wallpaper',
                        ),
                      ),
                      subtitle: Text(
                        t(
                          context,
                          ru:
                              'Пока приложение ни разу не поставило картинку, полоска не переключает кадр.',
                          en:
                              'Until the first successful apply, the strip does not advance.',
                        ),
                        softWrap: true,
                      ),
                      value: _tripleTapOnlyIfAppliedByApp,
                      onChanged: (v) =>
                          setState(() => _tripleTapOnlyIfAppliedByApp = v),
                    ),
                    SwitchListTile(
                      title: Text(
                        t(
                          context,
                          ru: 'Проверять обновления на GitHub',
                          en: 'Check for updates on GitHub',
                        ),
                      ),
                      subtitle: Text(
                        t(
                          context,
                          ru:
                              'Не чаще раза в 8 часов. Запрос только к api.github.com (публичный releases/latest).',
                          en:
                              'At most once every 8 hours. Calls public api.github.com/releases/latest only.',
                        ),
                        softWrap: true,
                      ),
                      value: _checkGithubUpdates,
                      onChanged: (v) => setState(() => _checkGithubUpdates = v),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => unawaited(
                          GithubUpdateCheck.runIfEligible(
                            context: context,
                            settingsRepo: context.read<SettingsRepository>(),
                            force: true,
                          ),
                        ),
                        child: Text(
                          t(
                            context,
                            ru: 'Проверить обновления сейчас',
                            en: 'Check for updates now',
                          ),
                        ),
                      ),
                    ),
                    Text(
                      t(
                        context,
                        ru:
                            'Автор проекта — ${AppSettings.creator} (в «О приложении»).',
                        en: 'Author — ${AppSettings.creator} (in About).',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _rss,
                      decoration: const InputDecoration(
                        labelText: 'URL RSS-ленты',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Сначала AllOrigins, потом прямой запрос',
                      ),
                      value: _proxyFirst,
                      onChanged: (v) => setState(() => _proxyFirst = v),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: Text(
                            t(
                              context,
                              ru: '30 мин · по умолчанию',
                              en: '30 min · default',
                            ),
                          ),
                          onPressed: () => setState(
                            () => _interval.text =
                                '${AppSettings.defaultIntervalSeconds ~/ 60}',
                          ),
                        ),
                        ActionChip(
                          label: Text(
                            t(context, ru: '60 мин', en: '60 min'),
                          ),
                          onPressed: () =>
                              setState(() => _interval.text = '60'),
                        ),
                        ActionChip(
                          label: Text(
                            t(context, ru: '90 мин', en: '90 min'),
                          ),
                          onPressed: () =>
                              setState(() => _interval.text = '90'),
                        ),
                        ActionChip(
                          label: Text(
                            t(context, ru: '6 ч', en: '6 h'),
                          ),
                          onPressed: () =>
                              setState(() => _interval.text = '360'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _interval,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t(
                          context,
                          ru:
                              'Интервал смены обоев (минуты, 1–10080). По умолчанию 30',
                          en:
                              'Wallpaper change interval (minutes, 1–10080). Default 30',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _maxCache,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Максимум сохранённых файлов обоев',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minW,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Мин. ширина',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _minH,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Мин. высота',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<WallpaperOrientation>(
                      value: _orientation,
                      decoration: const InputDecoration(
                        labelText: 'Ориентация',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: WallpaperOrientation.landscape,
                          child: Text('Только горизонтальные'),
                        ),
                        DropdownMenuItem(
                          value: WallpaperOrientation.portrait,
                          child: Text('Только вертикальные'),
                        ),
                        DropdownMenuItem(
                          value: WallpaperOrientation.any,
                          child: Text('Любая'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _orientation = v);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Скрывать посты NSFW из RSS'),
                      value: _nsfw,
                      onChanged: (v) => setState(() => _nsfw = v),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Не повторять уже показанные (по ID Reddit)',
                      ),
                      value: _skipUsed,
                      onChanged: (v) => setState(() => _skipUsed = v),
                    ),
                    TextField(
                      controller: _hashCap,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Лимит записей истории хэшей',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _clearHistory,
                      child: const Text('Очистить историю (разрешить повторы)'),
                    ),
                    const Divider(height: 32),
                    Text(
                      'Интерфейс и доступность',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SwitchListTile(
                      title: const Text('Меньше анимаций (reduce motion)'),
                      value: _reduceMotion,
                      onChanged: (v) => setState(() => _reduceMotion = v),
                    ),
                    SwitchListTile(
                      title: const Text('Компактная плотность интерфейса'),
                      value: _denseUi,
                      onChanged: (v) => setState(() => _denseUi = v),
                    ),
                    SwitchListTile(
                      title: const Text('Показывать журнал движка на главной'),
                      value: _showLog,
                      onChanged: (v) => setState(() => _showLog = v),
                    ),
                    Text(
                      'Акцент темы',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final c in const [
                          0xFF1B4332,
                          0xFF023E8A,
                          0xFF6F1D1B,
                          0xFF4C1D95,
                          0xFF14532D,
                          0xFF0D9488,
                        ])
                          FilterChip(
                            label: Text(
                              '●',
                              style: TextStyle(
                                color: Color(c),
                                fontSize: 22,
                                height: 1,
                              ),
                            ),
                            selected: _accent == c,
                            onSelected: (_) => setState(() => _accent = c),
                          ),
                      ],
                    ),
                    if (!kIsWeb && Platform.isAndroid) ...[
                      const Divider(height: 24),
                      SwitchListTile(
                        title: const Text(
                          'Только Wi‑Fi / Ethernet для загрузок',
                        ),
                        subtitle: const Text(
                          'Экономит мобильный трафик; на мобильной сети смена отложится',
                        ),
                        value: _onlyWifi,
                        onChanged: (v) => setState(() => _onlyWifi = v),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _androidLoc.clamp(1, 3),
                        decoration: const InputDecoration(
                          labelText: 'Куда ставить обои (Android)',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('Домашний экран'),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('Экран блокировки'),
                          ),
                          DropdownMenuItem(value: 3, child: Text('Оба')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _androidLoc = v);
                        },
                      ),
                      SwitchListTile(
                        title: Text(
                          t(
                            context,
                            ru: 'Параллакс превью: акселерометр',
                            en: 'Preview parallax: accelerometer',
                          ),
                        ),
                        subtitle: Text(
                          t(
                            context,
                            ru:
                                'Только в окне приложения на главной. Системные обои на домашнем экране не двигаются.',
                            en:
                                'In-app preview on Home only. System home wallpaper stays static.',
                          ),
                          softWrap: true,
                        ),
                        value: _androidGyroParallaxEnabled,
                        onChanged: (v) =>
                            setState(() => _androidGyroParallaxEnabled = v),
                      ),
                      ExpansionTile(
                        title: Text(
                          t(
                            context,
                            ru: 'Хочу ещё настроек! (акселерометр)',
                            en: 'More settings (accelerometer)',
                          ),
                        ),
                        children: [
                          Text(
                            '${t(context, ru: 'Масштаб', en: 'Zoom')}: ${_androidGyroParallaxScale.toStringAsFixed(2)}',
                          ),
                          Slider(
                            value: _androidGyroParallaxScale.clamp(1.0, 1.22),
                            min: 1.0,
                            max: 1.22,
                            divisions: 22,
                            onChanged: (v) =>
                                setState(() => _androidGyroParallaxScale = v),
                          ),
                          Text(
                            '${t(context, ru: 'Макс. сдвиг (dp)', en: 'Max shift (dp)')}: ${_androidGyroMaxOffsetDp.toStringAsFixed(0)}',
                          ),
                          Slider(
                            value: _androidGyroMaxOffsetDp.clamp(4, 48),
                            min: 4,
                            max: 48,
                            divisions: 44,
                            onChanged: (v) =>
                                setState(() => _androidGyroMaxOffsetDp = v),
                          ),
                          Text(
                            '${t(context, ru: 'Плавность', en: 'Smoothing')}: ${_androidGyroSmoothing.toStringAsFixed(2)}',
                          ),
                          Slider(
                            value: _androidGyroSmoothing.clamp(0.05, 0.55),
                            min: 0.05,
                            max: 0.55,
                            divisions: 50,
                            onChanged: (v) =>
                                setState(() => _androidGyroSmoothing = v),
                          ),
                          SwitchListTile(
                            title: Text(
                              t(context, ru: 'Инверсия X', en: 'Invert X'),
                            ),
                            value: _androidGyroInvertX,
                            onChanged: (v) =>
                                setState(() => _androidGyroInvertX = v),
                          ),
                          SwitchListTile(
                            title: Text(
                              t(context, ru: 'Инверсия Y', en: 'Invert Y'),
                            ),
                            value: _androidGyroInvertY,
                            onChanged: (v) =>
                                setState(() => _androidGyroInvertY = v),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        title: Text(
                          t(
                            context,
                            ru: 'Параллакс превью: горизонтальные страницы',
                            en: 'Preview parallax: horizontal pages',
                          ),
                        ),
                        subtitle: Text(
                          t(
                            context,
                            ru:
                                'Имитация «свайпа экранов» внутри превью на главной.',
                            en:
                                'Simulates home-screen page swipe inside the Home preview.',
                          ),
                          softWrap: true,
                        ),
                        value: _androidPagerParallaxEnabled,
                        onChanged: (v) =>
                            setState(() => _androidPagerParallaxEnabled = v),
                      ),
                      ExpansionTile(
                        title: Text(
                          t(
                            context,
                            ru: 'Хочу ещё настроек! (страницы)',
                            en: 'More settings (pages)',
                          ),
                        ),
                        children: [
                          Text(
                            '${t(context, ru: 'Число страниц', en: 'Page count')}: $_androidPagerVirtualPages',
                          ),
                          Slider(
                            value: _androidPagerVirtualPages.toDouble(),
                            min: 3,
                            max: 9,
                            divisions: 6,
                            label: '$_androidPagerVirtualPages',
                            onChanged: (v) => setState(
                              () => _androidPagerVirtualPages = v.round(),
                            ),
                          ),
                          Text(
                            '${t(context, ru: 'Сила (dp)', en: 'Strength (dp)')}: ${_androidPagerStrengthDp.toStringAsFixed(0)}',
                          ),
                          Slider(
                            value: _androidPagerStrengthDp.clamp(4, 80),
                            min: 4,
                            max: 80,
                            divisions: 38,
                            onChanged: (v) =>
                                setState(() => _androidPagerStrengthDp = v),
                          ),
                          Text(
                            '${t(context, ru: 'Сглаживание', en: 'Smoothing')}: ${_androidPagerSmoothing.toStringAsFixed(2)}',
                          ),
                          Slider(
                            value: _androidPagerSmoothing.clamp(0.05, 0.55),
                            min: 0.05,
                            max: 0.55,
                            divisions: 50,
                            onChanged: (v) =>
                                setState(() => _androidPagerSmoothing = v),
                          ),
                        ],
                      ),
                    ],
                    if (!kIsWeb &&
                        (Platform.isWindows ||
                            Platform.isLinux ||
                            Platform.isMacOS)) ...[
                      const Divider(height: 24),
                      SwitchListTile(
                        title: const Text('Автозапуск вместе с системой'),
                        subtitle: const Text(
                          'Портативная регистрация в автозагрузке (Windows / Linux / macOS)',
                        ),
                        value: _runAtStartup,
                        onChanged: (v) => setState(() => _runAtStartup = v),
                      ),
                    ],
                    const Divider(height: 32),
                    Text(
                      t(context, ru: 'Загрузки и запас', en: 'Downloads & cache'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SwitchListTile(
                      title: Text(
                        t(
                          context,
                          ru: 'Предзагрузка следующей картинки (запас)',
                          en: 'Prefetch next image',
                        ),
                      ),
                      value: _prefetch,
                      onChanged: (v) => setState(() => _prefetch = v),
                    ),
                    if (_prefetch) ...[
                      TextField(
                        controller: _prefetchSlots,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: t(
                            context,
                            ru: 'Сколько картинок держать в запасе (1–8)',
                            en: 'How many images to prefetch (1–8)',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _wallpaperStorage,
                      decoration: InputDecoration(
                        labelText: t(
                          context,
                          ru:
                              'Папка для файлов обоев и запаса (пусто = каталог приложения)',
                          en:
                              'Wallpaper & prefetch folder (empty = app default)',
                        ),
                        hintText: '~/Pictures/EarthPornWallpaper',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (_resolvedCacheDir != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: SelectableText(
                          '${t(context, ru: 'Сейчас используется:', en: 'Using folder:')} $_resolvedCacheDir',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (!kIsWeb &&
                        (Platform.isWindows || Platform.isLinux)) ...[
                      const Divider(height: 32),
                      Text(
                        t(context, ru: 'Компьютер', en: 'Computer'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SwitchListTile(
                        title: Text(
                          t(
                            context,
                            ru: 'Закрытие окна в трей (Windows / Linux)',
                            en: 'Close window to tray (Windows / Linux)',
                          ),
                        ),
                        value: _minTray,
                        onChanged: (v) => setState(() => _minTray = v),
                      ),
                      SwitchListTile(
                        title: Text(
                          t(
                            context,
                            ru: 'Запуск скрыто в трее',
                            en: 'Start hidden in tray',
                          ),
                        ),
                        value: _startTray,
                        onChanged: (v) => setState(() => _startTray = v),
                      ),
                      SwitchListTile(
                        title: Text(
                          t(
                            context,
                            ru: 'Показывать иконку в трее',
                            en: 'Show tray icon',
                          ),
                        ),
                        value: _showTray,
                        onChanged: (v) => setState(() => _showTray = v),
                      ),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        title: Text(
                          t(
                            context,
                            ru:
                                'Клик по иконке в трее: меню (след. кадр, выход…)',
                            en: 'Tray icon click opens menu',
                          ),
                          softWrap: true,
                          maxLines: 4,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          t(
                            context,
                            ru:
                                'Если меню не всплывает — попробуйте правый клик по иконке.',
                            en: 'If the menu does not pop up, try right-click.',
                          ),
                          softWrap: true,
                        ),
                        value: _trayTriple,
                        onChanged: (v) => setState(() => _trayTriple = v),
                      ),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        title: Text(
                          t(
                            context,
                            ru:
                                'Три быстрых нажатия по серой полоске внизу — следующий кадр',
                            en: 'Three quick clicks on the gray strip — next',
                          ),
                          softWrap: true,
                          maxLines: 4,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          t(
                            context,
                            ru:
                                'Только полоска под списком на главной и здесь.',
                            en: 'Only the strip under the list on Home and here.',
                          ),
                          softWrap: true,
                        ),
                        value: _winTriple,
                        onChanged: (v) => setState(() => _winTriple = v),
                      ),
                      TextField(
                        controller: _tripleMs,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: t(
                            context,
                            ru: 'Окно для «тройного» жеста (мс)',
                            en: 'Triple-gesture window (ms)',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      SwitchListTile(
                        title: Text(
                          t(
                            context,
                            ru: 'Глобальное сочетание клавиш',
                            en: 'Global hotkey',
                          ),
                        ),
                        value: _hotOn,
                        onChanged: (v) => setState(() => _hotOn = v),
                      ),
                      DropdownButtonFormField<String>(
                        value: _hotPreset,
                        decoration: InputDecoration(
                          labelText: t(
                            context,
                            ru: 'Сочетание (модификаторы: Alt+Shift)',
                            en: 'Shortcut (modifiers: Alt+Shift)',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'w',
                            child: Text('Alt + Shift + W'),
                          ),
                          DropdownMenuItem(
                            value: 'n',
                            child: Text('Alt + Shift + N'),
                          ),
                          DropdownMenuItem(
                            value: 'e',
                            child: Text('Alt + Shift + E'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _hotPreset = v);
                        },
                      ),
                    ],
                    TextField(
                      controller: _httpTimeout,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Таймаут HTTP (сек)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (!kIsWeb && Platform.isWindows) ...[
                      const Divider(height: 32),
                      Text(
                        t(context, ru: 'Windows: все мониторы', en: 'Windows: all monitors'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SwitchListTile(
                        title: Text(
                          t(
                            context,
                            ru:
                                'Одна широкая картинка на весь виртуальный рабочий стол',
                            en: 'One wide image across the virtual desktop',
                          ),
                        ),
                        subtitle: Text(
                          t(
                            context,
                            ru:
                                'PowerShell + System.Drawing. При ошибке отключите и сообщите в issue.',
                            en:
                                'Uses PowerShell + System.Drawing. Turn off if it fails.',
                          ),
                          softWrap: true,
                        ),
                        value: _windowsSpanAllMonitors,
                        onChanged: (v) =>
                            setState(() => _windowsSpanAllMonitors = v),
                      ),
                      ExpansionTile(
                        title: Text(
                          t(
                            context,
                            ru: 'Хочу ещё настроек! (Windows span)',
                            en: 'More settings (Windows span)',
                          ),
                        ),
                        children: [
                          DropdownButtonFormField<int>(
                            value: _windowsSpanFitMode,
                            decoration: InputDecoration(
                              labelText: t(
                                context,
                                ru: 'Вписывание',
                                en: 'Fit mode',
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: AppSettings.windowsSpanFitFill,
                                child: Text(
                                  t(
                                    context,
                                    ru: 'Заполнить (обрезка)',
                                    en: 'Fill (crop)',
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: AppSettings.windowsSpanFitContain,
                                child: Text(
                                  t(
                                    context,
                                    ru: 'Вписать (поля)',
                                    en: 'Contain (letterbox)',
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _windowsSpanFitMode = v);
                              }
                            },
                          ),
                          Text(
                            '${t(context, ru: 'Внутренний отступ «рамки» (px)', en: 'Inner bezel shrink (px)')}: ${_windowsSpanBezelPx.toStringAsFixed(0)}',
                          ),
                          Slider(
                            value: _windowsSpanBezelPx.clamp(0, 120),
                            min: 0,
                            max: 120,
                            divisions: 120,
                            onChanged: (v) =>
                                setState(() => _windowsSpanBezelPx = v),
                          ),
                          Text(
                            '${t(context, ru: 'Качество JPEG', en: 'JPEG quality')}: $_windowsSpanJpegQuality',
                          ),
                          Slider(
                            value: _windowsSpanJpegQuality.toDouble(),
                            min: 60,
                            max: 95,
                            divisions: 35,
                            label: '$_windowsSpanJpegQuality',
                            onChanged: (v) => setState(
                              () => _windowsSpanJpegQuality = v.round(),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _save,
                      child: const Text('Сохранить и применить'),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const SizedBox.shrink();
                        final i = snap.data!;
                        return AboutListTile(
                          icon: const Icon(Icons.info_outline),
                          applicationName: i.appName,
                          applicationVersion: '${i.version}+${i.buildNumber}',
                          applicationLegalese: '© ${AppSettings.creator}',
                          aboutBoxChildren: const [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'EarthPorn Wallpaper загружает публичную RSS-ленту Reddit '
                                'без OAuth. Для устойчивости используется прокси AllOrigins и прямой запасной канал.',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              TripleEmptyWallpaperArea(
                enabled:
                    repo.settings.windowTripleClickNext &&
                        engine.isTripleStripActive(),
                windowMs: repo.settings.tripleClickWindowMs,
                minHeight: 168,
                onTriple: () => unawaited(engine.nextWallpaperQuick()),
              ),
            ],
          );
        },
      ),
    );
  }
}
