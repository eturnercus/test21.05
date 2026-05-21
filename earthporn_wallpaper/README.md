# EarthPorn Wallpaper

Кроссплатформенное приложение (**Android**, **Linux**, **Windows**): тянет публичную RSS-ленту [r/EarthPorn](https://www.reddit.com/r/EarthPorn/.rss) (без OAuth), по возможности через прокси AllOrigins, скачивает изображения, фильтрует по размеру и ориентации, ведёт историю без повторов, держит не больше N файлов в кэше и ставит обои средствами ОС.

**Создатель: eturnercus**

## Возможности

- Старт с **немедленной** сменой обоев, далее по таймеру (по умолчанию 90 с ≈ 1:30).
- **Запас (prefetch)** следующей картинки для быстрой смены.
- **Три быстрых нажатия ЛКМ по иконке в трее** (Windows/Linux) или **три тапа по главному окну** — следующая картинка.
- Глобальное сочетание **Alt+Shift+W** (или N/E в настройках).
- Много настроек: RSS, прокси, интервал, кэш, минимальное разрешение, ориентация (горизонтально / вертикально / любая), трей, горячие клавиши, Android-цель обоев.

## Сборка

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

Для смены обоев: в GNOME/KDE/XFCE/Cinnamon/MATE приложение вызывает `gsettings`, `plasma-apply-wallpaperimage`, `xfconf-query` и т.д.; запасной вариант — `feh --bg-fill`, на Windows — `SystemParametersInfo` через PowerShell.

### AppImage

После `flutter build linux --release` готовый бинарь лежит в  
`build/linux/x64/release/bundle/`. Упаковать в AppImage можно с [linuxdeploy](https://github.com/linuxdeploy/linuxdeploy) + [appimagetool](https://github.com/AppImage/AppImageKit). Черновой сценарий: `earthporn_wallpaper/scripts/build_appimage.sh` (проверьте пути к linuxdeploy и appimagetool на своей машине).

## Структура

- `lib/` — UI и сервисы (RSS, кэш, обои, трей/окно на десктопе).
- `assets/tray.png` — иконка трея (в бандле Flutter).

## Лицензия

Проект в репозитории пользователя — уточните лицензию при необходимости.
