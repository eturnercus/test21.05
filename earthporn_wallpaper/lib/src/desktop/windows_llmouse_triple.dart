import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';

import 'desktop_next_port.dart';

/// Low-level mouse hook: three primary clicks within [windowMs] → loopback NEXT.
class WindowsLlMouseTriple {
  WindowsLlMouseTriple._();

  static NativeCallable<HOOKPROC>? _callable;
  static int _hook = 0;
  static int _seq = 0;
  static int _firstMs = 0;
  static const int _windowMs = 650;

  /// Dart representation of [HOOKPROC] uses plain [int] parameters (see `DartRepresentationOf`).
  static int _hookProc(int nCode, int wParam, int lParam) {
    if (nCode >= 0 && wParam == WM_LBUTTONDOWN) {
      _registerClick();
    }
    return CallNextHookEx(_hook, nCode, wParam, lParam);
  }

  static void _registerClick() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_seq == 0 || now - _firstMs > _windowMs) {
      _firstMs = now;
      _seq = 1;
      return;
    }
    _seq++;
    if (_seq >= 3) {
      _seq = 0;
      DesktopNextPort.pingPrimaryInMicrotask();
    }
  }

  static bool _running = false;

  static void start() {
    if (_running) return;
    try {
      // WH_MOUSE_LL runs on the thread that installed the hook (same as Flutter UI).
      // `listener` callbacks must return void; we must return CallNextHookEx to the OS.
      _callable = NativeCallable<HOOKPROC>.isolateLocal(
        _hookProc,
        exceptionalReturn: 0,
      );
      _hook = SetWindowsHookEx(
        WH_MOUSE_LL,
        _callable!.nativeFunction,
        0,
        0,
      );
      if (_hook == 0) {
        debugPrint('WindowsLlMouseTriple: SetWindowsHookEx failed');
        _callable?.close();
        _callable = null;
        return;
      }
      _running = true;
    } catch (e, st) {
      debugPrint('WindowsLlMouseTriple.start: $e\n$st');
      _callable?.close();
      _callable = null;
      _hook = 0;
    }
  }

  static void stop() {
    if (!_running) return;
    if (_hook != 0) {
      UnhookWindowsHookEx(_hook);
      _hook = 0;
    }
    _callable?.close();
    _callable = null;
    _running = false;
    _seq = 0;
    _firstMs = 0;
  }
}
