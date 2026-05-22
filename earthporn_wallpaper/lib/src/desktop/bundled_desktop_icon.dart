import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Absolute path to a bundled PNG for [tray_manager] / [window_manager] on
/// Windows and Linux (relative `assets/...` often fails outside `flutter run`).
Future<String> resolveBundledPngPath(String assetKey) async {
  assert(assetKey.endsWith('.png'), assetKey);
  try {
    final exe = File(Platform.resolvedExecutable);
    final exeDir = exe.parent.path;
    final candidates = <String>[
      p.join(exeDir, 'data', 'flutter_assets', assetKey),
      p.normalize(p.join(exeDir, '..', 'data', 'flutter_assets', assetKey)),
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
  } catch (_) {}
  final data = await rootBundle.load(assetKey);
  final tmp = await getTemporaryDirectory();
  final out = File(p.join(tmp.path, 'earthporn_${p.basename(assetKey)}'));
  await out.writeAsBytes(data.buffer.asUint8List(), flush: true);
  return out.path;
}
