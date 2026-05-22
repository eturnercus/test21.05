import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Loopback TCP used by a secondary instance or the Windows mouse hook to ask
/// the primary instance for the next wallpaper (no second UI).
class DesktopNextPort {
  DesktopNextPort._();

  static const int kPort = 48193;
  static const String kToken = 'NEXT_WALLPAPER\n';

  /// Fire-and-forget: primary's [ServerSocket] listener handles this.
  static void pingPrimaryInMicrotask() {
    scheduleMicrotask(() async {
      try {
        final s = await Socket.connect(
          InternetAddress.loopbackIPv4,
          kPort,
          timeout: const Duration(milliseconds: 900),
        );
        try {
          s.write(kToken);
          await s.flush();
        } finally {
          await s.close();
        }
      } catch (_) {}
    });
  }

  /// Binds [kPort]; returns null if another instance already holds it.
  static Future<ServerSocket?> tryBindPrimary() async {
    if (kIsWeb) return null;
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return null;
    }
    try {
      return await ServerSocket.bind(InternetAddress.loopbackIPv4, kPort);
    } on SocketException {
      return null;
    }
  }

  /// If the singleton port is busy, optionally signal the running instance and exit.
  static Future<void> secondaryInstanceMaybeSignalAndExit() async {
    if (kIsWeb) return;
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    try {
      await ServerSocket.bind(InternetAddress.loopbackIPv4, kPort);
      return;
    } on SocketException {
      // Another instance holds the port.
    }
    final wantsNext = Platform.executableArguments.contains('--earthporn-next');
    if (wantsNext) {
      pingPrimaryInMicrotask();
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    exit(0);
  }

  static void listenForNextCommands(ServerSocket server, void Function() onNext) {
    server.listen(
      (Socket client) {
        final buf = StringBuffer();
        client.listen(
          (List<int> data) {
            buf.write(utf8.decode(data));
            final s = buf.toString();
            if (s.contains('NEXT')) {
              buf.clear();
              onNext();
            }
          },
          onError: (_) {},
          onDone: () {},
        );
      },
      onError: (e) => debugPrint('DesktopNextPort server: $e'),
    );
  }
}
