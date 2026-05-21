# EarthPorn Wallpaper

Кроссплатформенное приложение (**Android**, **Linux**, **Windows**): тянет публичную RSS-ленту [r/EarthPorn](https://www.reddit.com/r/EarthPorn/.rss) (без OAuth), по возможности через прокси AllOrigins, скачивает изображения, фильтрует по размеру и ориентации, ведёт историю без повторов, держит не больше N файлов в кэше и ставит обои средствами ОС.

**Создатель: eturnercus**

## Возможности

- Старт с **немедленной** сменой обоев, далее по таймеру (**по умолчанию 30 минут = 1800 с**, как в исходном Python-скрипте с `CHECK_INTERVAL = 1800`).
- **Android:** при первой установке — мастер выбора **статических** или **живых** обоев (открывается системный выбор живых обоев). Для телефона по умолчанию фильтр **вертикальных** кадров (портрет) и порог пикселей 1080×1920.
- **Запас (prefetch)** следующей картинки для быстрой смены.
- **Три быстрых нажатия ЛКМ по иконке в трее** (Windows/Linux) или **три тапа по главному экрану** — следующая картинка.
- Глобальное сочетание **Alt+Shift+W** (или N/E в настройках).
- Расширенные настройки: RSS, прокси, интервал (пресеты), кэш, разрешение, ориентация, **только Wi‑Fi** на Android, **автозапуск** на десктопе, акцент темы, reduce motion, плотность UI, трей, горячие клавиши, цель обоев на Android.

## Сборки в GitHub Actions

В репозитории workflow `.github/workflows/earthporn-artifacts.yml` собирает **три независимых артефакта** (каждый job с `continue-on-error: true`):

| Артефакт | Содержимое |
|----------|------------|
| `earthporn-android-debug-apk` | `flutter build apk --debug` (подпись **debug** из стандартного keystore Gradle) |
| `earthporn-linux-portable-tar-gz` | `flutter build linux --release` → архив каталога `bundle` (без установки, распаковать и запустить `earthporn_wallpaper`) |
| `earthporn-windows-portable-zip` | `flutter build windows --release` → zip каталога `Release` |

AppImage можно собрать локально из Linux bundle (см. `scripts/build_appimage.sh`).

## Локальная сборка

Требуется [Flutter](https://flutter.dev/) (stable), для Linux ещё GTK и типичный набор для `flutter build linux` (CMake, Ninja, clang++).

```bash
cd earthporn_wallpaper
flutter pub get
flutter run   # или flutter build apk / windows / linux
```

### Debian / Ubuntu — зависимости для **разработки** Linux desktop

Пример (имена пакетов могут отличаться по версии дистрибутива):

```bash
sudo apt-get update
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa \
  clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev \
  libstdc++-12-dev
```

Для **трея** на GTK обычно нужен индикатор (один из вариантов):

```bash
sudo apt-get install -y libayatana-appindicator3-dev
# или: libappindicator3-dev
```

Для **глобальных горячих клавиш** (пакет `hotkey_manager` на X11) нужен keybinder 3:

```bash
sudo apt-get install -y libkeybinder-3.0-dev
```

Для смены обоев: в GNOME/KDE/XFCE/Cinnamon/MATE приложение вызывает `gsettings`, `plasma-apply-wallpaperimage`, `xfconf-query` и т.д.; запасной вариант — `feh --bg-fill`, на Windows — `SystemParametersInfo` через PowerShell.

### AppImage

После `flutter build linux --release` готовый бинарь лежит в  
`build/linux/x64/release/bundle/`. Упаковать в AppImage можно с [linuxdeploy](https://github.com/linuxdeploy/linuxdeploy) + [appimagetool](https://github.com/AppImage/AppImageKit). Черновой сценарий: `earthporn_wallpaper/scripts/build_appimage.sh` (проверьте пути к linuxdeploy и appimagetool на своей машине).

## Структура

- `lib/` — UI и сервисы (RSS, кэш, обои, трей/окно на десктопе).
- `assets/tray.png` — иконка трея (в бандле Flutter).

## Лицензия

Проект в репозитории пользователя — уточните лицензию при необходимости.
