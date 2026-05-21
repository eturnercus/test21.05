import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../services/wallpaper_engine.dart';
import 'theme.dart';

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
        actions: [
          IconButton(
            tooltip: 'Настройки',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _tripleTapWindow,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF04150F),
                scheme.surface.withValues(alpha: 0.9),
                const Color(0xFF0B2E1F),
              ],
            ),
          ),
          child: SafeArea(
            child: Consumer<WallpaperEngine>(
              builder: (context, engine, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 88, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Живые обои с r/EarthPorn',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.secondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Только интернет. RSS + резервный прокси AllOrigins. Автор: ${AppSettings.creator}.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (Platform.isWindows || Platform.isLinux) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Три быстрых нажатия по иконке в трее или три тапа по этому экрану — следующая картинка (если включено в настройках).',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              unawaited(engine.nextWallpaperQuick());
                            },
                            icon: const Icon(Icons.image_rounded),
                            label: const Text('Следующие обои'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final pf = await engine.advanceFromNetwork(
                                reason: 'Вручную из приложения',
                              );
                              if (pf) {
                                unawaited(engine.triggerPrefetch());
                              }
                            },
                            icon: const Icon(Icons.cloud_download_rounded),
                            label: const Text('Обновить из сети'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Статус',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                engine.isRunning
                                    ? 'Служба активна · интервал ${engine.settings.intervalSeconds} с'
                                    : 'Остановлено',
                              ),
                              if (engine.currentWallpaperPath != null) ...[
                                const SizedBox(height: 8),
                                SelectableText(
                                  'Файл: ${engine.currentWallpaperPath}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Text(
                                'Журнал',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(maxHeight: 280),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SingleChildScrollView(
                                  child: SelectableText(
                                    engine.logText.isEmpty
                                        ? 'Пока пусто — подождите первую загрузку.'
                                        : engine.logText,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () async {
                          final u = Uri.parse(
                            'https://www.reddit.com/r/EarthPorn/',
                          );
                          if (await canLaunchUrl(u)) {
                            await launchUrl(
                              u,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Открыть r/EarthPorn в браузере'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
