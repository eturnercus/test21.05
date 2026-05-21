import 'dart:io';

import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

/// Applies a local image as the desktop / device wallpaper per OS.
class WallpaperApplyService {
  Future<bool> apply(File image, {int androidLocation = 1}) async {
    if (Platform.isAndroid) {
      return _android(image, androidLocation);
    }
    if (Platform.isWindows) {
      return _windows(image.path);
    }
    if (Platform.isLinux) {
      return _linux(image.path);
    }
    return false;
  }

  Future<bool> _android(File image, int location) async {
    try {
      final wm = WallpaperManagerPlus();
      await wm.setWallpaper(image, location);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _windows(String path) async {
    // SystemParametersInfo SPI_SETDESKWALLPAPER — reliable without extra deps.
    final psPath = path.replaceAll("'", "''");
    final script = r'''
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
  public static extern bool SystemParametersInfo(uint a, uint b, string c, uint d);
}
"@
[W]::SystemParametersInfo(20, 0, '__PATH__', 3)
'''.replaceAll('__PATH__', psPath);
    final r = await Process.run(
      'powershell.exe',
      ['-NoProfile', '-NonInteractive', '-Command', script],
      runInShell: false,
    );
    return r.exitCode == 0;
  }

  Future<bool> _linux(String path) async {
    final de = _detectDe();
    Future<bool> run(List<String> cmd) async {
      try {
        final r = await Process.run(cmd.first, cmd.sublist(1));
        return r.exitCode == 0;
      } catch (_) {
        return false;
      }
    }

    final uri = Uri.file(path, windows: false).toString();

    switch (de) {
      case _De.gnome:
        if (await run([
          'gsettings',
          'set',
          'org.gnome.desktop.background',
          'picture-uri',
          uri,
        ])) {
          await run([
            'gsettings',
            'set',
            'org.gnome.desktop.background',
            'picture-uri-dark',
            uri,
          ]);
          return true;
        }
        break;
      case _De.cinnamon:
        if (await run([
          'gsettings',
          'set',
          'org.cinnamon.desktop.background',
          'picture-uri',
          uri,
        ])) {
          return true;
        }
        break;
      case _De.mate:
        if (await run([
          'gsettings',
          'set',
          'org.mate.background',
          'picture-filename',
          path,
        ])) {
          return true;
        }
        break;
      case _De.kde:
        if (await run(['plasma-apply-wallpaperimage', path])) {
          return true;
        }
        final esc = path.replaceAll("'", r"'\''");
        final js = '''
var desktops = desktops();
for (var i = 0; i < desktops.length; i++) {
  var d = desktops[i];
  d.wallpaperPlugin = "org.kde.image";
  d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  d.writeConfig("Image", "file://$esc");
}
''';
        if (await run([
          'qdbus',
          'org.kde.plasmashell',
          '/PlasmaShell',
          'org.kde.PlasmaShell.evaluateScript',
          js,
        ])) {
          return true;
        }
        break;
      case _De.xfce:
        try {
          final r = await Process.run('xfconf-query', [
            '-c',
            'xfce4-desktop',
            '-l',
          ]);
          if (r.exitCode == 0) {
            for (final line in (r.stdout as String).split('\n')) {
              if (line.contains('/last-image') && line.contains('workspace')) {
                await Process.run('xfconf-query', [
                  '-c',
                  'xfce4-desktop',
                  '-p',
                  line,
                  '-s',
                  path,
                ]);
              }
            }
            return true;
          }
        } catch (_) {}
        break;
      case _De.unknown:
        break;
    }

    return await run(['feh', '--bg-fill', path]);
  }

  _De _detectDe() {
    final cur =
        (Platform.environment['XDG_CURRENT_DESKTOP'] ?? '').toLowerCase();
    if (cur.contains('gnome') || cur.contains('unity')) return _De.gnome;
    if (cur.contains('kde')) return _De.kde;
    if (cur.contains('xfce')) return _De.xfce;
    if (cur.contains('cinnamon')) return _De.cinnamon;
    if (cur.contains('mate')) return _De.mate;
    try {
      final r = Process.runSync('ps', ['aux']);
      final out = (r.stdout as String?) ?? '';
      if (out.contains('gnome-session')) return _De.gnome;
      if (out.contains('plasmashell') || out.contains('kwin')) return _De.kde;
      if (out.contains('xfce4-session')) return _De.xfce;
    } catch (_) {}
    return _De.unknown;
  }
}

enum _De { gnome, kde, xfce, cinnamon, mate, unknown }
