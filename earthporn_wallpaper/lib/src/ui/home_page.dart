import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/feed_client.dart';
import '../services/settings_repository.dart';
import '../services/wallpaper_engine.dart';
import 'app_locale_text.dart';
import 'theme.dart';
import 'triple_empty_wallpaper_area.dart';
import 'wallpaper_hero_card.dart';

Future<void> _openSubreddit(BuildContext context, String rssUrl) async {
  final u = FeedClient.browseUriFromRss(rssUrl);
  try {
    final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось открыть браузер (нет подходящего приложения).',
          ),
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text('Не удалось открыть браузер: $e')));
  }
}

String _intervalHuman(int seconds) {
  if (seconds >= 3600 && seconds % 3600 == 0) {
    return '${seconds ~/ 3600} ч';
  }
  if (seconds % 60 == 0) {
    return '${seconds ~/ 60} мин';
  }
  return '$seconds с';
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _nextBusy = false;
  bool _pullBusy = false;

  Future<void> _runNext(BuildContext context) async {
    if (_nextBusy) return;
    final eng = context.read<WallpaperEngine>();
    setState(() => _nextBusy = true);
    try {
      await eng.nextWallpaperQuick();
    } finally {
      if (mounted) setState(() => _nextBusy = false);
    }
  }

  Future<void> _runPull(BuildContext context) async {
    if (_pullBusy) return;
    final eng = context.read<WallpaperEngine>();
    final reason = t(context, ru: 'Вручную', en: 'Manual');
    setState(() => _pullBusy = true);
    try {
      final pf = await eng.advanceFromNetwork(reason: reason);
      if (pf) unawaited(eng.triggerPrefetch());
    } finally {
      if (mounted) setState(() => _pullBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(appTitle())),
      body: Consumer2<WallpaperEngine, SettingsRepository>(
        builder: (context, engine, repo, _) {
          final s = repo.settings;
          final showTripleStrip =
              !kIsWeb &&
              Platform.isAndroid == false &&
              s.windowTripleClickNext &&
              engine.isTripleStripActive();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 88, 16, 8),
                child: WallpaperHeroCard(
                  imagePath: engine.currentWallpaperPath,
                  settings: s,
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 100, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            t(
                              context,
                              ru: 'Красивые обои с Reddit',
                              en: 'Wallpapers from Reddit',
                            ),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.secondary,
                                ),
                          ).animate().fadeIn().slideX(
                            begin: -0.02,
                            curve: Curves.easeOut,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t(
                              context,
                              ru:
                                  'Публичная RSS-лента, без аккаунта. Качество и размер можно настроить.',
                              en:
                                  'Public RSS feed, no account. Tune quality and size in Settings.',
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ).animate().fadeIn(delay: 80.ms),
                          const SizedBox(height: 10),
                          Text(
                            !kIsWeb && Platform.isAndroid
                                ? t(
                                    context,
                                    ru:
                                        'На рабочем столе: установите живые обои EarthPorn — там же параллакс, сдвиг при листании экранов и три быстрых тапа по свободному месту на обоях для следующего кадра (см. настройки). '
                                        'Здесь превью статичное; кнопки ниже всегда меняют обои.',
                                    en:
                                        'On the home screen: set EarthPorn live wallpaper for parallax, launcher-page shift, and three quick taps on empty wallpaper for next (see Settings). '
                                        'Preview here is static; the buttons always change wallpapers.',
                                  )
                                : t(
                                    context,
                                    ru:
                                        'Внизу — серая полоска: три быстрых щелчка по ней — следующий кадр (после успешной установки обоев этим приложением). '
                                        'В трее — меню. Кнопки выше — всегда.',
                                    en:
                                        'Gray strip at the bottom: three quick clicks — next wallpaper (after a successful apply from this app). '
                                        'Tray menu on desktop. Buttons above always work.',
                                  ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.65,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 28),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.standard,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: _nextBusy
                                    ? null
                                    : () => unawaited(_runNext(context)),
                                icon: _nextBusy
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: scheme.onPrimary,
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome),
                                label: Text(
                                  t(
                                    context,
                                    ru: 'Следующий кадр',
                                    en: 'Next wallpaper',
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.standard,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: _pullBusy
                                    ? null
                                    : () => unawaited(_runPull(context)),
                                icon: _pullBusy
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: scheme.primary,
                                        ),
                                      )
                                    : const Icon(Icons.cloud_sync_rounded),
                                label: Text(
                                  t(
                                    context,
                                    ru: 'Тянуть из сети',
                                    en: 'Pull from network',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Consumer2<WallpaperEngine, SettingsRepository>(
                            builder: (context, eng, rep, _) {
                              final showLog = rep.settings.showEngineLogPanel;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 18,
                                    sigmaY: 18,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.06,
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(
                                        color: scheme.outline.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Статус',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          eng.isRunning
                                              ? 'Активно · интервал ${_intervalHuman(eng.settings.intervalSeconds)} (по умолчанию 30 мин)'
                                              : 'Остановлено',
                                        ),
                                        if (eng.currentWallpaperPath !=
                                            null) ...[
                                          const SizedBox(height: 8),
                                          Tooltip(
                                            message: eng.currentWallpaperPath!,
                                            child: GestureDetector(
                                              onLongPress: () async {
                                                final p =
                                                    eng.currentWallpaperPath!;
                                                await Clipboard.setData(
                                                  ClipboardData(text: p),
                                                );
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.maybeOf(
                                                  context,
                                                )?.showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Путь скопирован (долгое нажатие)',
                                                    ),
                                                    duration: Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                eng.currentWallpaperPath!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (showLog) ...[
                                          const SizedBox(height: 12),
                                          Text(
                                            'Журнал',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                          ),
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            height: 88,
                                            width: double.infinity,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: scheme
                                                    .surfaceContainerHighest
                                                    .withValues(alpha: 0.45),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 8,
                                                    ),
                                                child: Scrollbar(
                                                  thumbVisibility: true,
                                                  child: SingleChildScrollView(
                                                    child: SelectableText(
                                                      eng.logText.isEmpty
                                                          ? 'Журнал появится после первой загрузки.'
                                                          : eng.logText,
                                                      style: TextStyle(
                                                        fontFamily: 'monospace',
                                                        fontSize: 10,
                                                        height: 1.25,
                                                        color: scheme.onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 120.ms);
                            },
                          ),
                          const SizedBox(height: 24),
                          Consumer<SettingsRepository>(
                            builder: (context, rep, _) {
                              return TextButton.icon(
                                onPressed: () => unawaited(
                                  _openSubreddit(context, rep.settings.rssUrl),
                                ),
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: const Text('Открыть сабреддит'),
                              );
                            },
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              TripleEmptyWallpaperArea(
                enabled: showTripleStrip,
                windowMs: s.tripleClickWindowMs,
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
