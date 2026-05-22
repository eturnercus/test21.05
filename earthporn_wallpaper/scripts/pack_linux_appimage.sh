#!/usr/bin/env bash
# Build a single-file AppImage from `flutter build linux --release` output.
# In CI (no FUSE), uses APPIMAGE_EXTRACT_AND_RUN=1 for appimagetool.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
if [[ ! -x "$BUNDLE/earthporn_wallpaper" ]]; then
  echo "Missing Linux release bundle. Run: flutter build linux --release"
  exit 1
fi

RAW_VER=$(grep '^version:' pubspec.yaml | head -1 | awk '{print $2}')
BASE_VER="${RAW_VER%%+*}"
OUT_NAME="EarthPorn-Wallpaper-${BASE_VER}-x86_64.AppImage"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

APPDIR="$WORKDIR/AppDir"
mkdir -p "$APPDIR/usr/share/earthporn_wallpaper"
cp -a "$BUNDLE/"* "$APPDIR/usr/share/earthporn_wallpaper/"

cp "$ROOT/assets/app_icon.png" "$APPDIR/earthporn_wallpaper.png"
cp "$ROOT/assets/app_icon.png" "$APPDIR/.DirIcon"

cat >"$APPDIR/earthporn_wallpaper.desktop" <<EOF
[Desktop Entry]
Name=EarthPorn Wallpaper
Comment=Wallpapers from Reddit (public RSS)
Exec=earthporn_wallpaper %u
Icon=earthporn_wallpaper
Type=Application
Categories=Graphics;GNOME;GTK;
StartupWMClass=earthporn_wallpaper
Terminal=false
EOF

cat >"$APPDIR/AppRun" <<'EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=$(dirname "$SELF")
cd "$HERE/usr/share/earthporn_wallpaper" || exit 1
exec ./earthporn_wallpaper "$@"
EOF
chmod +x "$APPDIR/AppRun"

cd "$WORKDIR"
AIT="$WORKDIR/appimagetool-x86_64.AppImage"
wget -q -O "$AIT" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x "$AIT"

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH=x86_64
"$AIT" "$APPDIR"

# appimagetool names output from the .desktop file (e.g. earthporn_wallpaper-x86_64.AppImage)
shopt -s nullglob
BUILT=(earthporn_wallpaper*.AppImage EarthPorn*.AppImage)
if [[ ${#BUILT[@]} -eq 0 ]]; then
  echo "appimagetool produced no .AppImage in $(pwd)"
  ls -la
  exit 1
fi
SRC="${BUILT[0]}"
mv "$SRC" "$ROOT/$OUT_NAME"
echo "Created $ROOT/$OUT_NAME"
