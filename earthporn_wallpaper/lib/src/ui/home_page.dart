import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../services/feed_client.dart';
import '../services/settings_repository.dart';
import '../services/wallpaper_engine.dart';
import 'theme.dart';

Future<void> _openSubreddit(BuildContext context, String rssUrl) async {
  final u = FeedClient.browseUriFromRss(rssUrl);
  try {
    final ok = await launchUrl(
      u,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть браузер (нет подходящего приложения).'),
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('Не удалось открыть браузер: $e')),
    );
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
  int _tapSeq = 0;
  DateTime? _firstTap;

  void _tripleTapWindow() {
    final engine = context.read<WallpaperEngine>();
    final s = engine.settings;
    if (!s.windowTripleClickNext) return;
    final now = DateTime.now();
    if (_firstTap == null ||
        now.difference(_firstTap!) >
            Duration(milliseconds: s.tripleClickWindowMs)) {
      _firstTap = now;
      _tapSeq = 1;
      return;
    }
    _tapSeq++;
    if (_tapSeq >= 3) {
      _tapSeq = 0;
      _firstTap = null;
      unawaited(engine.nextWallpaperQuick());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(appTitle()),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _tripleTapWindow,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Пейзажи с Reddit',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.secondary,
                        ),
                  ).animate().fadeIn().slideX(begin: -0.02, curve: Curves.easeOut),
                  const SizedBox(height: 8),
                  Text(
                    'RSS без OAuth · AllOrigins + прямой канал · ${AppSettings.creator}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ).animate().fadeIn(delay: 80.ms),
                  if (Platform.isWindows || Platform.isLinux) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Три нажатия по иконке в трее или три тапа здесь — следующий кадр.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          unawaited(context
                              .read<WallpaperEngine>()
                              .nextWallpaperQuick());
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Следующий кадр'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final engine = context.read<WallpaperEngine>();
                          final pf = await engine.advanceFromNetwork(
                            reason: 'Вручную',
                          );
                          if (pf) unawaited(engine.triggerPrefetch());
                        },
                        icon: const Icon(Icons.cloud_sync_rounded),
                        label: const Text('Тянуть из сети'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Consumer2<WallpaperEngine, SettingsRepository>(
                    builder: (context, engine, repo, _) {
                      final showLog = repo.settings.showEngineLogPanel;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Статус',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  engine.isRunning
                                      ? 'Активно · интервал ${_intervalHuman(engine.settings.intervalSeconds)} (по умолчанию 30 мин)'
                                      : 'Остановлено',
                                ),
                                if (engine.currentWallpaperPath != null) ...[
                                  const SizedBox(height: 8),
                                  Tooltip(
                                    message: engine.currentWallpaperPath!,
                                    child: GestureDetector(
                                      onLongPress: () async {
                                        final p = engine.currentWallpaperPath!;
                                        await Clipboard.setData(
                                          ClipboardData(text: p),
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.maybeOf(context)
                                            ?.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Путь скопирован (долгое нажатие)',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        engine.currentWallpaperPath!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ],
                                if (showLog) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Журнал',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 88,
                                    width: double.infinity,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                            alpha: 0.35),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        child: Scrollbar(
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            child: SelectableText(
                                              engine.logText.isEmpty
                                                  ? 'Журнал появится после первой загрузки.'
                                                  : engine.logText,
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 10,
                                                height: 1.25,
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
                    builder: (context, repo, _) {
                      return TextButton.icon(
                        onPressed: () => unawaited(
                          _openSubreddit(context, repo.settings.rssUrl),
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
    );
  }
}
