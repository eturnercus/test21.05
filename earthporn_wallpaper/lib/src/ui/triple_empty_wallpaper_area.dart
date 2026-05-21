import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Three primary clicks (LMB / touch) in an empty strip — next wallpaper.
class TripleEmptyWallpaperArea extends StatefulWidget {
  const TripleEmptyWallpaperArea({
    super.key,
    required this.enabled,
    required this.windowMs,
    required this.onTriple,
    this.minHeight = 168,
  });

  final bool enabled;
  final int windowMs;
  final VoidCallback onTriple;
  final double minHeight;

  @override
  State<TripleEmptyWallpaperArea> createState() =>
      _TripleEmptyWallpaperAreaState();
}

class _TripleEmptyWallpaperAreaState extends State<TripleEmptyWallpaperArea> {
  int _seq = 0;
  DateTime? _first;

  bool _isPrimary(PointerDownEvent e) {
    if (e.kind == PointerDeviceKind.mouse) {
      return e.buttons == kPrimaryMouseButton;
    }
    if (e.kind == PointerDeviceKind.touch) {
      return true;
    }
    if (e.kind == PointerDeviceKind.stylus) {
      return e.buttons == kPrimaryStylusButton;
    }
    return false;
  }

  void _onPointerDown(PointerDownEvent e) {
    if (!widget.enabled || !_isPrimary(e)) return;
    final now = DateTime.now();
    final win = Duration(milliseconds: widget.windowMs.clamp(200, 5000));
    if (_first == null || now.difference(_first!) > win) {
      _first = now;
      _seq = 1;
      return;
    }
    _seq++;
    if (_seq >= 3) {
      _seq = 0;
      _first = null;
      widget.onTriple();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      child: SizedBox(
        width: double.infinity,
        height: widget.minHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainer.withValues(alpha: 0.12),
            border: Border(
              top: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
            ),
          ),
          child: Center(
            child: Text(
              Platform.isAndroid
                  ? 'Три тапа по пустой полоске — следующий кадр'
                  : 'Три нажатия ЛКМ по пустой полоске — следующий кадр',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
