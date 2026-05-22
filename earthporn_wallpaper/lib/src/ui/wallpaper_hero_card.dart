import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/app_settings.dart';

/// In-app preview image (static on Android; motion is handled by the live wallpaper engine).
class WallpaperHeroCard extends StatefulWidget {
  const WallpaperHeroCard({
    super.key,
    required this.imagePath,
    required this.settings,
  });

  final String? imagePath;
  final AppSettings settings;

  @override
  State<WallpaperHeroCard> createState() => _WallpaperHeroCardState();
}

class _WallpaperHeroCardState extends State<WallpaperHeroCard> {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _vx = 0;
  double _vy = 0;
  final PageController _pageController = PageController();
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPage);
  }

  void _onPage() {
    final p = _pageController.page;
    if (p == null) return;
    if ((p - _page).abs() < 0.001) return;
    setState(() => _page = p);
  }

  @override
  void didUpdateWidget(covariant WallpaperHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.androidGyroParallaxEnabled !=
            widget.settings.androidGyroParallaxEnabled ||
        oldWidget.settings.reduceMotion != widget.settings.reduceMotion) {
      _syncAccel();
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _pageController.removeListener(_onPage);
    _pageController.dispose();
    super.dispose();
  }

  void _syncAccel() {
    _accelSub?.cancel();
    _accelSub = null;
    // Gyro / pager preview moved to Android live wallpaper; in-app preview stays static.
    final isAndroidDevice = !kIsWeb && Platform.isAndroid;
    final use = !isAndroidDevice &&
        defaultTargetPlatform == TargetPlatform.android &&
        widget.settings.androidGyroParallaxEnabled &&
        !widget.settings.reduceMotion;
    if (!use) return;
    _accelSub = accelerometerEventStream().listen((AccelerometerEvent e) {
      final a = widget.settings.androidGyroSmoothing.clamp(0.05, 0.55);
      _vx = _vx * (1 - a) + e.x * a;
      _vy = _vy * (1 - a) + e.y * a;
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAccel();
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.imagePath;
    final scheme = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final maxG = widget.settings.androidGyroMaxOffsetDp.clamp(4, 48);
    final gx = (widget.settings.androidGyroInvertX ? -1 : 1) * (-_vx * 2.2);
    final gy = (widget.settings.androidGyroInvertY ? -1 : 1) * (_vy * 2.2);
    final gyroDx = isAndroid ? 0.0 : (gx.clamp(-maxG, maxG) * (dpr / 2.6));
    final gyroDy = isAndroid ? 0.0 : (gy.clamp(-maxG, maxG) * (dpr / 2.6));

    final pagerOn = !isAndroid &&
        defaultTargetPlatform == TargetPlatform.android &&
        widget.settings.androidPagerParallaxEnabled &&
        !widget.settings.reduceMotion;
    final nPages = widget.settings.androidPagerVirtualPages.clamp(3, 9);
    final strength =
        widget.settings.androidPagerStrengthDp.clamp(4.0, 80.0) * (dpr / 2);
    final center = (nPages - 1) / 2.0;
    final smoothPager = pagerOn ? (_page - center) * strength : 0.0;

    final scale = !isAndroid &&
            defaultTargetPlatform == TargetPlatform.android &&
            widget.settings.androidGyroParallaxEnabled &&
            !widget.settings.reduceMotion
        ? widget.settings.androidGyroParallaxScale.clamp(1.0, 1.22)
        : 1.0;

    final imageLayer = path != null && File(path).existsSync()
        ? Transform.translate(
            offset: Offset(gyroDx + smoothPager, gyroDy),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
                errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          )
        : Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: scheme.onSurface.withValues(alpha: 0.35),
            ),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
          ),
          child: pagerOn
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(child: imageLayer),
                    Positioned.fill(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: nPages,
                        itemBuilder: (_, i) => const SizedBox.expand(),
                      ),
                    ),
                  ],
                )
              : imageLayer,
        ),
      ),
    );
  }
}
