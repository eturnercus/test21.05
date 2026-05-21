import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../desktop/desktop_integration.dart';
import '../models/app_settings.dart';
import '../models/wallpaper_orientation.dart';
import '../services/settings_repository.dart';
import '../services/wallpaper_engine.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _rss;
  late TextEditingController _interval;
  late TextEditingController _maxCache;
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

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsRepository>().settings;
    _rss = TextEditingController(text: s.rssUrl);
    _interval = TextEditingController(text: '${s.intervalSeconds}');
    _maxCache = TextEditingController(text: '${s.maxCachedFiles}');
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
    if (s.hotkeyKey == LogicalKeyboardKey.keyN) {
      _hotPreset = 'n';
    } else if (s.hotkeyKey == LogicalKeyboardKey.keyE) {
      _hotPreset = 'e';
    } else {
      _hotPreset = 'w';
    }
  }

  @override
  void dispose() {
    _rss.dispose();
    _interval.dispose();
    _maxCache.dispose();
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
    final next = repo.settings.copyWith(
      rssUrl: _rss.text.trim(),
      proxyFirst: _proxyFirst,
      intervalSeconds: int.tryParse(_interval.text) ?? 90,
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
      filterNsfw: _nsfw,
      skipUsedHashes: _skipUsed,
      maxUsedHashEntries: int.tryParse(_hashCap.text) ?? 4000,
      httpTimeoutSeconds: int.tryParse(_httpTimeout.text) ?? 35,
      tripleClickWindowMs: int.tryParse(_tripleMs.text) ?? 650,
      androidWallpaperLocation: _androidLoc.clamp(1, 3),
    );
    await repo.save(next);
    await engine.reloadSettings();
    engine.updateTimerFromSettings();
    if (!mounted) return;
    await refreshDesktopChrome(context);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сохранено')),
      );
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
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Создатель: ${AppSettings.creator}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _rss,
            decoration: const InputDecoration(
              labelText: 'URL RSS-ленты',
              border: OutlineInputBorder(),
            ),
          ),
          SwitchListTile(
            title: const Text('Сначала AllOrigins, потом прямой запрос'),
            value: _proxyFirst,
            onChanged: (v) => setState(() => _proxyFirst = v),
          ),
          TextField(
            controller: _interval,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Интервал смены (секунды, ≥30)',
              border: OutlineInputBorder(),
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
            title: const Text('Не повторять уже показанные (по ID Reddit)'),
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
          Text('Рабочий стол', style: Theme.of(context).textTheme.titleMedium),
          SwitchListTile(
            title: const Text('Предзагрузка следующей картинки (запас)'),
            value: _prefetch,
            onChanged: (v) => setState(() => _prefetch = v),
          ),
          SwitchListTile(
            title: const Text('Закрытие окна в трей (Windows / Linux)'),
            value: _minTray,
            onChanged: (v) => setState(() => _minTray = v),
          ),
          SwitchListTile(
            title: const Text('Запуск скрыто в трее'),
            value: _startTray,
            onChanged: (v) => setState(() => _startTray = v),
          ),
          SwitchListTile(
            title: const Text('Показывать иконку в трее'),
            value: _showTray,
            onChanged: (v) => setState(() => _showTray = v),
          ),
          SwitchListTile(
            title: const Text('Три нажатия по иконке трея — следующая'),
            value: _trayTriple,
            onChanged: (v) => setState(() => _trayTriple = v),
          ),
          SwitchListTile(
            title: const Text('Три тапа по главному окну — следующая'),
            value: _winTriple,
            onChanged: (v) => setState(() => _winTriple = v),
          ),
          TextField(
            controller: _tripleMs,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Окно для «тройного» жеста (мс)',
              border: OutlineInputBorder(),
            ),
          ),
          SwitchListTile(
            title: const Text('Глобальное сочетание клавиш'),
            value: _hotOn,
            onChanged: (v) => setState(() => _hotOn = v),
          ),
          DropdownButtonFormField<String>(
            value: _hotPreset,
            decoration: const InputDecoration(
              labelText: 'Сочетание (модификаторы: Alt+Shift)',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'w', child: Text('Alt + Shift + W')),
              DropdownMenuItem(value: 'n', child: Text('Alt + Shift + N')),
              DropdownMenuItem(value: 'e', child: Text('Alt + Shift + E')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _hotPreset = v);
            },
          ),
          TextField(
            controller: _httpTimeout,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Таймаут HTTP (сек)',
              border: OutlineInputBorder(),
            ),
          ),
          const Divider(height: 32),
          Text('Android', style: Theme.of(context).textTheme.titleMedium),
          DropdownButtonFormField<int>(
            value: _androidLoc.clamp(1, 3),
            decoration: const InputDecoration(
              labelText: 'Куда ставить обои',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Домашний экран')),
              DropdownMenuItem(value: 2, child: Text('Экран блокировки')),
              DropdownMenuItem(value: 3, child: Text('Оба')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _androidLoc = v);
            },
          ),
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
    );
  }
}
