#!/usr/bin/env bash
# After `flutter build linux --release`, the relocatable bundle is at:
#   build/linux/x64/release/bundle/
# Use linuxdeploy + appimagetool to wrap that bundle into an AppImage.
# See: https://docs.appimage.org/packaging-guide/overview.html
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
: "${FLUTTER:=flutter}"
"$FLUTTER" build linux --release
echo "Linux bundle ready: $ROOT/build/linux/x64/release/bundle/"
echo "Next: run linuxdeploy with --appdir and point --executable at bundle/earthporn_wallpaper,"
echo "and include the .desktop + icon from the bundle (see Flutter docs / AppImage guide)."
