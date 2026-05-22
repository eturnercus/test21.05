import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/settings_repository.dart';
import 'app_keys.dart';
import 'app_locale_text.dart';

/// Semi-transparent guide on the main shell. Dismiss state in SharedPreferences.
class MainHelpOverlay extends StatefulWidget {
  const MainHelpOverlay({super.key});

  @override
  State<MainHelpOverlay> createState() => _MainHelpOverlayState();
}

class _MainHelpOverlayState extends State<MainHelpOverlay> {
  bool? _show;
  SettingsRepository? _repo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = context.read<SettingsRepository>();
    if (!identical(_repo, r)) {
      _repo?.removeListener(_onRepo);
      _repo = r..addListener(_onRepo);
    }
  }

  @override
  void dispose() {
    _repo?.removeListener(_onRepo);
    super.dispose();
  }

  void _onRepo() {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final dismissed =
        p.getBool(kMainHelpOverlayDismissedKey) ??
        p.getBool('main_help_overlay_v1_dismissed') ??
        false;
    if (mounted) setState(() => _show = !dismissed);
  }

  Future<void> _dismiss() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(kMainHelpOverlayDismissedKey, true);
    if (mounted) setState(() => _show = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_show != true) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final isDesktop = defaultTargetPlatform != TargetPlatform.android;
    final isEn = localeIsEn(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Material(
            color: Colors.black.withValues(alpha: 0.42),
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: _dismiss,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
            child: Material(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.96),
              elevation: 10,
              shadowColor: Colors.black45,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/tray.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.waving_hand_rounded, color: scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t(
                              context,
                              ru: 'Добро пожаловать!',
                              en: 'Welcome!',
                            ),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ArrowRow(
                      icon: Icons.swipe_down_alt_rounded,
                      text: t(
                        context,
                        ru:
                            'Внизу окна — узкая нейтральная зона: три быстрых нажатия по ней переключают кадр '
                            '(если приложение уже успешно поставило текущие обои).',
                        en:
                            'Narrow zone at the bottom of this window: three quick taps there switch the wallpaper '
                            '(only after this app has successfully applied your current image).',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ArrowRow(
                      icon: Icons.auto_awesome,
                      text: t(
                        context,
                        ru: 'Крупные кнопки «Следующий кадр» и «Тянуть из сети» — всегда под рукой.',
                        en: 'Use the big “Next” and “Pull from network” buttons anytime.',
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(height: 8),
                      _ArrowRow(
                        icon: Icons.notifications_active_outlined,
                        text: t(
                          context,
                          ru:
                              'В трее (рядом с часами) — иконка приложения: меню для смены обоев и настроек.',
                          en:
                              'System tray (near the clock) — app icon with a menu for next wallpaper and settings.',
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    ExpansionTile(
                      initiallyExpanded: false,
                      title: Text(
                        t(context, ru: 'Подробнее', en: 'More details'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(
                        8,
                        0,
                        8,
                        8,
                      ),
                      children: [
                        Text(
                          _detailsBody(context, isDesktop, isEn),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.42,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _dismiss,
                          child: Text(
                            t(context, ru: 'Закрыть', en: 'Close'),
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _dismiss,
                          child: Text(
                            t(context, ru: 'Понятно', en: 'Got it'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _detailsBody(BuildContext context, bool isDesktop, bool isEn) {
    if (isEn) {
      final buf = StringBuffer()
        ..writeln(
          'The app loads a public Reddit RSS feed (no login), downloads images, filters by size/orientation, and sets wallpapers.\n',
        )
        ..writeln(
        '• Triple-tap works only on the bottom strip inside this app window (not on the bare desktop). '
        'If “only after our apply” is enabled in settings, wait until the first successful wallpaper from the app.\n',
        )
        ..writeln(
          '• Global hotkey on Windows may need administrator policies in rare cases — not required for wallpapers or the strip.\n',
        );
      if (isDesktop) {
        buf.writeln(
          '• Tray (Windows/Linux): enable “show tray icon” and “click opens menu”. '
          'If the menu does not appear, try right-click or install libayatana-appindicator on Linux (Wayland).\n',
        );
      }
      buf
        ..writeln(
          '• If new wallpapers rarely appear, review filters, RSS URL, and “no repeats” history in Settings.\n',
        )
        ..writeln(
          '• Second desktop launch exits immediately — only one instance stays open.\n',
        )
        ..writeln(
          '• Android parallax toggles only move the preview inside this app; the system home wallpaper stays static unless you use a live wallpaper engine (not included).\n',
        )
        ..writeln(
          '• Windows “span all monitors” builds one wide JPEG for the virtual screen via PowerShell; if it fails, disable the option.\n',
        )
        ..write(
          'You can reopen this sheet from Settings → “Show welcome tips again”.',
        );
      return buf.toString();
    }
    final buf = StringBuffer()
      ..writeln(
        'Приложение тянет публичную RSS-ленту Reddit (без логина), скачивает картинки, фильтрует по размеру и ориентации и ставит обои.\n',
      )
      ..writeln(
        '• Тройное нажатие срабатывает только по нижней полоске внутри окна приложения — не по «голому» рабочему столу. '
        'Если в настройках включено «только после применения приложением», дождитесь первой успешной установки обоев.\n',
      )
      ..writeln(
        '• Глобальное сочетание клавиш на Windows в редких случаях упирается в политики безопасности — к обоям и полоске это не относится.\n',
      );
    if (isDesktop) {
      buf.writeln(
        '• Трей (Windows/Linux): включите «иконка в трее» и «клик — меню». '
        'Если меню не всплывает — ПКМ по иконке или пакет libayatana-appindicator (Wayland).\n',
      );
    }
    buf
      ..writeln(
        '• Если новые обои появляются редко, загляните в настройки: фильтры, адрес RSS и история «не повторять».\n',
      )
      ..writeln(
        '• Второй запуск на ПК сразу закрывается — остаётся только первый экземпляр.\n',
      )
      ..writeln(
        '• Параллакс на Android двигает только превью внутри приложения; системные обои на домашнем экране остаются статичными (живые обои — отдельная история).\n',
      )
      ..writeln(
        '• Режим Windows «на все мониторы» собирает один широкий JPEG под виртуальный экран через PowerShell; при ошибке выключите опцию.\n',
      )
      ..write(
        'Эту подсказку снова можно открыть в настройках: «Показать приветствие снова».',
      );
    return buf.toString();
  }
}

class _ArrowRow extends StatelessWidget {
  const _ArrowRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: scheme.primary.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(width: 6),
        Icon(icon, size: 20, color: scheme.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
