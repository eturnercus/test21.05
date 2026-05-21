import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

import '../models/app_settings.dart';

/// Applies a local image as the desktop / device wallpaper per OS.
class WallpaperApplyService {
  Future<bool> apply(File image, {required AppSettings settings}) async {
    if (Platform.isAndroid) {
      return _android(image, settings.androidWallpaperLocation);
    }
    if (Platform.isWindows) {
      if (settings.windowsSpanAllMonitors) {
        final span = await _windowsSpanVirtualScreen(image.path, settings);
        if (span) return true;
      }
      return _windowsSingle(image.path);
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

  Future<bool> _windowsSingle(String path) async {
    final psPath = path.replaceAll("'", "''");
    final script =
        r'''
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
  public static extern bool SystemParametersInfo(uint a, uint b, string c, uint d);
}
"@
[W]::SystemParametersInfo(20, 0, '__PATH__', 3)
'''
            .replaceAll('__PATH__', psPath);
    final r = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      script,
    ], runInShell: false);
    return r.exitCode == 0;
  }

  /// One wide JPEG covering [SystemInformation.VirtualScreen], then SPI.
  Future<bool> _windowsSpanVirtualScreen(
    String imagePath,
    AppSettings settings,
  ) async {
    final tmpDir = await Directory.systemTemp.createTemp('earthporn_span_');
    final psPath = p.join(tmpDir.path, 'span_wallpaper.ps1');
    final outPath = p.join(tmpDir.path, 'span_out.jpg');
    final fit = settings.windowsSpanFitMode == AppSettings.windowsSpanFitContain
        ? 'fit'
        : 'fill';
    final quality = settings.windowsSpanJpegQuality.clamp(60, 95);
    final bezel = settings.windowsSpanBezelPx.clamp(0, 120).toInt();

    final script = _windowsSpanScript(
      fit: fit,
      quality: quality,
      bezel: bezel,
    )
        .replaceAll('__SRC__', imagePath.replaceAll("'", "''"))
        .replaceAll('__DST__', outPath.replaceAll("'", "''"));
    await File(psPath).writeAsString(script);

    final r = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      psPath,
    ], runInShell: false);
    final ok = r.exitCode == 0 && File(outPath).existsSync();
    try {
      await tmpDir.delete(recursive: true);
    } catch (_) {}
    return ok;
  }

  /// PowerShell: composite to virtual desktop; SPI at end.
  static String _windowsSpanScript({
    required String fit,
    required int quality,
    required int bezel,
  }) {
    // Non-raw: every PS `$` escaped for Dart (`\$`).
    return '''
\$ErrorActionPreference = 'Stop'
try {
  Add-Type -AssemblyName System.Drawing,System.Windows.Forms
  \$src = '__SRC__'
  \$dst = '__DST__'
  \$fitMode = '__FIT__'
  \$quality = __QUALITY__
  \$bezel = __BEZEL__
  \$img = [System.Drawing.Image]::FromFile(\$src)
  \$vs = [System.Windows.Forms.SystemInformation]::VirtualScreen
  \$W = [int]\$vs.Width
  \$H = [int]\$vs.Height
  if (\$W -le 0 -or \$H -le 0) { throw "Virtual screen size invalid" }
  if (\$bezel -gt 0) {
    \$W = [Math]::Max(1, \$W - 2 * \$bezel)
    \$H = [Math]::Max(1, \$H - 2 * \$bezel)
  }
  \$bmp = New-Object System.Drawing.Bitmap(\$W, \$H)
  \$g = [System.Drawing.Graphics]::FromImage(\$bmp)
  \$g.Clear([System.Drawing.Color]::Black)
  \$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  \$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  \$iw = [double]\$img.Width
  \$ih = [double]\$img.Height
  \$scale = 1.0
  if (\$fitMode -eq 'fill') {
    \$scale = [Math]::Max(\$W / \$iw, \$H / \$ih)
  } else {
    \$scale = [Math]::Min(\$W / \$iw, \$H / \$ih)
  }
  \$nw = \$iw * \$scale
  \$nh = \$ih * \$scale
  \$x = (\$W - \$nw) / 2.0
  \$y = (\$H - \$nh) / 2.0
  \$g.DrawImage(\$img, [System.Drawing.RectangleF]::new(\$x, \$y, \$nw, \$nh))
  \$enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -EQ 'image/jpeg'
  \$ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
  \$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]\$quality)
  \$bmp.Save(\$dst, \$enc, \$ep)
  \$g.Dispose()
  \$bmp.Dispose()
  \$img.Dispose()

  Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
  public static extern bool SystemParametersInfo(uint a, uint b, string c, uint d);
}
"@
  [void][W]::SystemParametersInfo(20, 0, \$dst, 3)
} catch {
  exit 1
}
'''
        .replaceAll('__FIT__', fit)
        .replaceAll('__QUALITY__', quality.toString())
        .replaceAll('__BEZEL__', bezel.toString());
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
        final js =
            '''
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
    final cur = (Platform.environment['XDG_CURRENT_DESKTOP'] ?? '')
        .toLowerCase();
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
