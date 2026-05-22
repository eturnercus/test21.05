<div align="center">

# EarthPorn Wallpaper

**Обои из публичной ленты Reddit — Android, Linux, Windows**

[![Flutter](https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter)](https://flutter.dev/)
[![GitHub release](https://img.shields.io/github/v/release/eturnercus/test21.05?logo=github)](https://github.com/eturnercus/test21.05/releases/latest)

[r/EarthPorn](https://www.reddit.com/r/EarthPorn/) · [RSS по умолчанию](https://www.reddit.com/r/EarthPorn/.rss)

</div>

Документация для репозитория ведётся **только в `README.md` в корне**.

---

## О проекте

Кроссплатформенное приложение на **Flutter**: читает **RSS** выбранного сабреддита, загружает изображения, применяет **фильтры** (разрешение, ориентация, NSFW, история показов), кэширует файлы и выставляет **обои** через API системы. **Вход в Reddit не требуется.**

Исходный код приложения находится в каталоге **`earthporn_wallpaper/`** — все команды сборки выполняются из него.

---

## Установка из GitHub Releases

Стабильные сборки: **[github.com/eturnercus/test21.05/releases/latest](https://github.com/eturnercus/test21.05/releases/latest)**  
Имена файлов в каждом релизе фиксированы (их подставляет CI):

| Файл | Платформа |
|------|-----------|
| `EarthPorn-Wallpaper-Linux-x64.tar.gz` | Linux x64 (портативный `bundle/`) |
| `EarthPorn-Wallpaper-Windows-x64.zip` | Windows x64 |
| `EarthPorn-Wallpaper-Android-debug.apk` | Android (debug APK) |

Прямые ссылки «последний релиз» (удобно для скриптов):

- Linux: `https://github.com/eturnercus/test21.05/releases/latest/download/EarthPorn-Wallpaper-Linux-x64.tar.gz`
- Windows: `https://github.com/eturnercus/test21.05/releases/latest/download/EarthPorn-Wallpaper-Windows-x64.zip`
- Android: `https://github.com/eturnercus/test21.05/releases/latest/download/EarthPorn-Wallpaper-Android-debug.apk`

### Linux (Ubuntu / Debian) — одним блоком в консоль

Скопируйте целиком (зависимости для **GTK-трея и хоткея** + скачивание последнего релиза + запуск):

```bash
sudo apt-get update && sudo apt-get install -y curl ca-certificates \
  libgtk-3-0 libayatana-appindicator3-1 libkeybinder-3.0-0
REL="https://github.com/eturnercus/test21.05/releases/latest/download"
curl -fsSL "$REL/EarthPorn-Wallpaper-Linux-x64.tar.gz" -o /tmp/earthporn-linux.tar.gz
tar -xzf /tmp/earthporn-linux.tar.gz -C /tmp
chmod +x /tmp/bundle/earthporn_wallpaper
exec /tmp/bundle/earthporn_wallpaper
```

При желании перенесите `/tmp/bundle` в постоянное место (например `~/Apps/EarthPorn-Wallpaper`) и запускайте `bundle/earthporn_wallpaper` оттуда.

### Windows (PowerShell)

```powershell
$base = "https://github.com/eturnercus/test21.05/releases/latest/download"
$zip  = "$env:TEMP\EarthPorn-Wallpaper-Windows-x64.zip"
Invoke-WebRequest -Uri "$base/EarthPorn-Wallpaper-Windows-x64.zip" -OutFile $zip
$dest = "$env:LOCALAPPDATA\EarthPorn-Wallpaper"
Expand-Archive -Path $zip -DestinationPath $dest -Force
Start-Process "$dest\earthporn_wallpaper.exe"
```

### Android

Скачайте APK по ссылке выше и откройте файл на устройстве (**разрешите установку из неизвестных источников** при запросе) или через `adb`:

```bash
adb install -r EarthPorn-Wallpaper-Android-debug.apk
```

---

## Разработка (из исходников)

Если нужен запуск из репозитория с Flutter SDK:

```bash
git clone https://github.com/eturnercus/test21.05.git
cd test21.05/earthporn_wallpaper
flutter pub get
flutter run
```

Сборки вручную: `flutter build apk`, `flutter build linux`, `flutter build windows`.

---

## Релизы и CI

- Workflow **`.github/workflows/earthporn-artifacts.yml`** собирает три артефакта на push/PR; при пуше **git-тега** вида `v1.2.3` тот же workflow **публикует GitHub Release** и прикрепляет переименованные файлы (`EarthPorn-Wallpaper-*`).
- Создать релиз вручную: поднимите версию в `earthporn_wallpaper/pubspec.yaml`, закоммитьте, затем  
  `git tag v1.2.3 && git push origin v1.2.3`  
  (тег должен совпадать с политикой версий в приложении, чтобы проверка обновлений в клиенте корректно сравнивала с GitHub).

В приложении есть опция **«Проверять обновления на GitHub»** (по умолчанию включена; отключается в настройках): запрос к публичному API `releases/latest` не чаще чем раз в 8 часов.

---

## Возможности

| Область | Кратко |
|--------|--------|
| **Лента** | RSS, резервные каналы загрузки, предзагрузка следующего кадра |
| **Фильтры** | Минимальное разрешение, ориентация, скрытие NSFW, опция «не повторять» |
| **Интервал** | По умолчанию смена **каждые 30 минут** (настраивается) |
| **Android** | Выбор экрана (дом / блокировка / оба), опция загрузки только по Wi‑Fi |
| **Windows / Linux** | Трей с меню, сворачивание при закрытии окна, глобальная горячая клавиша, один активный процесс на машине |
| **Справка** | Подсказка на главном экране; повторный показ из настроек |

---

## Жест и трей (десктоп)

Три быстрых нажатия по **нижней серой полоске** в окне приложения (главная и настройки) переключают кадр — область специально вынесена под жест. На **Windows / Linux** действия доступны также из **трея** и через **сочетание клавиш** (настраивается).

Для стабильной работы трея на Linux часто нужны пакеты индикатора и среда, поддерживающая **StatusNotifier** / AppIndicator (см. [зависимости для сборки](#linux-зависимости-для-сборки) — часть пакетов совпадает с runtime).

---

## Если долго не появляются новые обои

Проверьте по порядку:

- сеть и таймауты в настройках;
- режим **«только Wi‑Fi»** на Android;
- **URL RSS** и фильтры (минимальное разрешение, ориентация);
- опцию **«не повторять»** и при необходимости очистку истории в настройках.

Настройки фильтров и адрес RSS определяют, какие изображения попадут в ротацию обоев.

---

## Linux: зависимости для сборки

Пример для Debian / Ubuntu (набор может отличаться в зависимости от дистрибутива):

```bash
sudo apt-get update
sudo apt-get install -y curl git unzip xz-utils zip clang cmake ninja-build \
  pkg-config libgtk-3-dev liblzma-dev \
  libayatana-appindicator3-dev libkeybinder-3.0-dev
```

---

## Структура репозитория

| Путь | Назначение |
|------|------------|
| **`earthporn_wallpaper/`** | Полный Flutter-проект: `lib/`, `android/`, `linux/`, `windows/`, тесты |
| **`earthporn_wallpaper/lib/main.dart`** | Точка входа |
| **`earthporn_wallpaper/lib/src/services/`** | Лента, загрузка, движок обоев |
| **`earthporn_wallpaper/lib/src/desktop/`** | Интеграция окна, трея, автозапуска |
| **`.github/workflows/`** | CI и публикация релизов по тегу `v*` |

---

## Лицензия и вклад

Укажите лицензию при публикации форка. Issues и pull requests приветствуются.
