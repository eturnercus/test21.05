import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDismissedKey = 'main_help_overlay_v1_dismissed';

/// Semi-transparent first-run guide on the main shell (all platforms).
class MainHelpOverlay extends StatefulWidget {
  const MainHelpOverlay({super.key});

  @override
  State<MainHelpOverlay> createState() => _MainHelpOverlayState();
}

class _MainHelpOverlayState extends State<MainHelpOverlay> {
  bool? _show;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final dismissed = p.getBool(_kDismissedKey) ?? false;
    if (mounted) setState(() => _show = !dismissed);
  }

  Future<void> _dismiss() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDismissedKey, true);
    if (mounted) setState(() => _show = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_show != true) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final isDesktop = defaultTargetPlatform != TargetPlatform.android;

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Material(
            color: Colors.black.withValues(alpha: 0.48),
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: _dismiss,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
            child: Material(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.97),
              elevation: 12,
              shadowColor: Colors.black54,
              borderRadius: BorderRadius.circular(26),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: scheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Как пользоваться EarthPorn Wallpaper',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          child: Text(
                            _bodyText(isDesktop),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  height: 1.45,
                                  color: scheme.onSurface,
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _dismiss,
                          child: const Text('Закрыть'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _dismiss,
                          child: const Text('Понятно'),
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

  String _bodyText(bool isDesktop) {
    final buf = StringBuffer()
      ..writeln(
        'Кратко: приложение тянет публичную RSS-ленту Reddit (без логина), '
        'скачивает картинки, фильтрует по размеру и ориентации и ставит обои. '
        'Создатель — eturnercus.\n',
      )
      ..writeln(
        '• Смена кадра: кнопки на главной, таймер, запас (prefetch), горячие клавиши в настройках.\n'
        '• Три нажатия ЛКМ (или три тапа на телефоне) только по серой полоске внизу экрана — следующий кадр. '
        'Жест не требует прав администратора. Если на Windows не срабатывает глобальное сочетание клавиш, '
        'на отдельных политиках безопасности помогает запуск от имени администратора — это касается только горячей клавиши, не обоев и не полоски.\n',
      );

    if (isDesktop) {
      buf.writeln(
        '• Трей (Windows / Linux): включите «Показывать иконку в трее» и «Клик по иконке в трее: меню». '
        'По клику открывается меню: следующий кадр, подкачать запас, настройки, выход. '
        'Если меню не появляется, попробуйте правый клик по иконке или обновите интеграцию индикатора в среде рабочего стола (Wayland / пакет libayatana-appindicator).\n',
      );
    }

    buf
      ..writeln(
        '• Лента «бесконечна» на сайте Reddit, но по RSS за один раз приходит только верхняя порция постов. '
        'Приложение автоматически переходит по ссылке «следующая страница» (до 15 страниц) и подмешивает больше постов, '
        'пока не найдёт подходящий кадр или не закончатся страницы. Если всё равно «нет подходящих» — '
        'ослабьте минимальное разрешение, выберите ориентацию «любая», очистите историю «не повторять» или смените подреддит.\n',
      )
      ..writeln(
        '• Второй запуск приложения на компьютере: откроется только первый экземпляр (дубликаты закрываются сразу).\n',
      )
      ..write(
        'Нажмите «Понятно» или затемнённый фон, чтобы скрыть это окно. Его можно снова показать, удалив ключ '
        '$_kDismissedKey в данных приложения (для опытных пользователей).',
      );

    return buf.toString();
  }
}
