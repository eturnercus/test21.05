# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

EarthPorn Wallpaper is a cross-platform Flutter desktop/mobile app that fetches nature images from the Reddit r/EarthPorn RSS feed and sets them as wallpapers. The app code lives in `earthporn_wallpaper/`. See `earthporn_wallpaper/README.md` for full details.

### Prerequisites

- **Flutter SDK** (stable channel, Dart >= 3.12) installed at `/opt/flutter` and on `PATH`
- **Linux build dependencies**: `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libayatana-appindicator3-dev libkeybinder-3.0-dev libstdc++-14-dev`

### Common commands

All commands run from `earthporn_wallpaper/`:

| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Lint | `flutter analyze` |
| Test | `flutter test` |
| Build (Linux debug) | `flutter build linux --debug` |
| Run (Linux desktop) | `flutter run -d linux` |

### Non-obvious gotchas

- **libstdc++ symlink**: Clang 18 selects GCC 14 but Ubuntu 24.04 doesn't put `libstdc++.so` in the linker search path by default. If the build fails with `cannot find -lstdc++`, run: `sudo ln -sf /usr/lib/gcc/x86_64-linux-gnu/14/libstdc++.so /usr/lib/x86_64-linux-gnu/libstdc++.so`
- **libstdc++-14-dev**: Must be installed for `type_traits` and other C++ standard library headers; clang 18 auto-selects GCC 14 include paths.
- **Tray manager plugin error**: When running in a headless or minimal desktop environment, the app logs `MissingPluginException(No implementation found for method setToolTip on channel tray_manager)`. This is non-fatal; the app continues to work.
- **OpenGL frame warnings**: GTK OpenGL size mismatch warnings (`Timed out waiting for OpenGL frame of size ...`) are cosmetic and can be ignored.
- **DISPLAY environment variable**: Must be set (e.g., `export DISPLAY=:1`) before running the app on Linux desktop.
- The app requires internet access to fetch the Reddit RSS feed (`reddit.com/r/EarthPorn/.rss`) and images from Reddit CDN.
