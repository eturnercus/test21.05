import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/settings_repository.dart';
import 'app_keys.dart';
import 'app_locale_text.dart';

/// Semi-transparent guide on the main shell with arrows. Dismiss state in SharedPreferences.
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
            color: Colors.black.withValues(alpha: 0.52),
            child: InkWell(
              onTap: _dismiss,
              splashColor: Colors.white24,
              highlightColor: Colors.white10,
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 48,
          bottom: 96,
          child: LayoutBuilder(
            builder: (context, c) {
              final h = c.maxHeight.clamp(280.0, 560.0);
              return Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 520, maxHeight: h),
                  child: Material(
                    color: scheme.surface.withValues(alpha: 0.78),
                    elevation: 12,
                    shadowColor: Colors.black54,
                    borderRadius: BorderRadius.circular(26),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.waving_hand_rounded,
                                color: scheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  t(
                                    context,
                                    ru: 'Как пользоваться',
                                    en: 'Quick guide',
                                  ),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _GuideArrowBlock(
                                  icon: Icons.touch_app_rounded,
                                  arrowDown: true,
                                  text: t(
                                    context,
                                    ru:
                                        'Главная: кнопки «Следующий кадр» и «Тянуть из сети» — основной способ смены. При нажатии есть лёгкая вибрация и индикатор загрузки.',
                                    en:
                                        'Home: “Next” and “Pull from network” are the main actions. You get light haptics and a small spinner while work runs.',
                                  ),
                                ),
                                if (defaultTargetPlatform ==
                                    TargetPlatform.android) ...[
                                  const SizedBox(height: 14),
                                  _GuideArrowBlock(
                                    icon: Icons.wallpaper_rounded,
                                    arrowDown: false,
                                    text: t(
                                      context,
                                      ru:
                                          'Рабочий стол Android: в настройках системы выберите живые обои «EarthPorn Wallpaper». Там работают наклон (акселерометр), сдвиг при листании экранов лаунчера и три быстрых тапа по пустому месту на обоях — следующий кадр (если включено в настройках приложения).',
                                      en:
                                          'Android home: set “EarthPorn Wallpaper” as the live wallpaper. Tilt, launcher page scroll, and three quick taps on empty wallpaper request the next image (when enabled in app settings).',
                                    ),
                                  ),
                                ],
                                if (isDesktop) ...[
                                  const SizedBox(height: 14),
                                  _GuideArrowBlock(
                                    icon: Icons.notifications_active_outlined,
                                    arrowDown: true,
                                    text: t(
                                      context,
                                      ru:
                                          'В трее (рядом с часами) — иконка приложения: меню «следующий кадр», подкачка, настройки.',
                                      en:
                                          'System tray — app icon menu for next wallpaper, prefetch, and settings.',
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  initiallyExpanded: false,
                                  title: Text(
                                    t(context, ru: 'Подробнее', en: 'More details'),
                                    style: Theme.of(context).textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  children: [
                                    SizedBox(
                                      height: 280,
                                      child: Scrollbar(
                                        thumbVisibility: true,
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                            bottom: 8,
                                          ),
                                          child: SelectableText(
                                            _detailsBody(context, isDesktop, isEn),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(height: 1.45),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          child: Row(
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
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 72,
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 44,
            color: Colors.white.withValues(alpha: 0.85),
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
          '• Android: static wallpaper is still applied for the lock screen / compatibility; live wallpaper shows the same image on the home screen with optional motion and triple-tap. Some launchers may not forward all touch events to wallpapers.\n',
        )
        ..writeln(
          '• Optional background notification keeps the process alive so the interval timer matches desktop; turn it off in Settings if you prefer.\n',
        )
        ..writeln(
          '• Triple-tap strip at the bottom exists on Windows/Linux only. On Android, use live wallpaper triple-tap on the home screen.\n',
        )
        ..writeln(
          '• Global hotkey on Windows may need administrator policies in rare cases — not required for wallpapers.\n',
        );
      if (isDesktop) {
        buf.writeln(
          '• Tray: enable “show tray icon” and “click opens menu”. On Linux Wayland you may need libayatana-appindicator.\n',
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
          '• Windows “span all monitors” builds one wide JPEG via PowerShell; if it fails, disable the option.\n',
        )
        ..write(
          'Reopen this sheet from Settings → “Show welcome tips again”.',
        );
      return buf.toString();
    }
    final buf = StringBuffer()
      ..writeln(
        'Приложение тянет публичную RSS-ленту Reddit (без логина), скачивает картинки, фильтрует по размеру и ориентации и ставит обои.\n',
      )
      ..writeln(
        '• Android: обычные обои по-прежнему ставятся через систему (экран блокировки и совместимость); живые обои EarthPorn показывают тот же файл на домашнем экране с движением и тройным тапом. У части лаунчеров касания до обоев доходят не идеально.\n',
      )
      ..writeln(
        '• Фоновое уведомление (опция) держит процесс, чтобы интервал смены работал как на ПК; можно отключить в настройках.\n',
      )
      ..writeln(
        '• Серая полоска с тройным нажатием внизу — только Windows/Linux. На Android используйте три тапа по обоям на рабочем столе (живые обои).\n',
      )
      ..writeln(
        '• Глобальное сочетание клавиш на Windows в редких случаях упирается в политики — к обоям это не относится.\n',
      );
    if (isDesktop) {
      buf.writeln(
        '• Трей: включите «иконка в трее» и «клик — меню». На Linux Wayland может понадобиться libayatana-appindicator.\n',
      );
    }
    buf
      ..writeln(
        '• Если новые обои редко появляются — фильтры, RSS, история «не повторять» в настройках.\n',
      )
      ..writeln(
        '• Второй запуск на ПК сразу закрывается — остаётся один экземпляр.\n',
      )
      ..writeln(
        '• Режим Windows «на все мониторы» собирает один JPEG; при ошибке выключите опцию.\n',
      )
      ..write(
        'Снова открыть: настройки → «Показать приветствие снова».',
      );
    return buf.toString();
  }
}

class _GuideArrowBlock extends StatelessWidget {
  const _GuideArrowBlock({
    required this.icon,
    required this.text,
    required this.arrowDown,
  });

  final IconData icon;
  final String text;
  final bool arrowDown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(icon, color: scheme.primary, size: 26),
                if (arrowDown) ...[
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 22,
                    color: scheme.secondary,
                  ),
                ] else
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 22,
                    color: scheme.secondary,
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
