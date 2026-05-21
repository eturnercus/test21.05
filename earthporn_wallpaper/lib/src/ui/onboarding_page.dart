import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../platform/android_wallpaper_intent.dart';

/// First-launch experience (Android): static vs live wallpaper path.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _step = 0;

  Future<void> _finish({required bool openLiveChooser}) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('onboarding_v2_done', true);
      if (openLiveChooser && Platform.isAndroid) {
        try {
          await AndroidWallpaperIntent.openLiveWallpaperFlow();
        } catch (_) {
          // Chooser may be unavailable on some OEM builds; onboarding still completes.
        }
      }
    } finally {
      if (mounted) widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF03140C),
              scheme.surface,
              const Color(0xFF0B3D28),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'EarthPorn',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.secondary,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.08, curve: Curves.easeOutCubic),
                Text(
                  'Обои из Reddit · ${AppSettings.creator}',
                  style: Theme.of(context).textTheme.titleMedium,
                ).animate().fadeIn(delay: 120.ms),
                const Spacer(),
                if (_step == 0) ...[
                  Text(
                    'Выберите, как хотите использовать приложение. Статические обои меняются автоматически по расписанию (по умолчанию каждые 30 минут). Живые обои открывают системный выбор Android.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ).animate().fadeIn(),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('Далее'),
                  ),
                ] else ...[
                  Text(
                    'Тип обоев',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _ChoiceTile(
                    title: 'Статические обои',
                    subtitle: 'Автоматическая смена из r/EarthPorn (рекомендуется)',
                    icon: Icons.image_outlined,
                    onTap: () => _finish(openLiveChooser: false),
                  ),
                  const SizedBox(height: 12),
                  _ChoiceTile(
                    title: 'Живые обои',
                    subtitle: 'Откроется экран выбора живых обоев Android',
                    icon: Icons.motion_photos_on_outlined,
                    onTap: () => _finish(openLiveChooser: true),
                  ),
                  TextButton(
                    onPressed: () => _finish(openLiveChooser: false),
                    child: const Text('Пропустить'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.98, 0.98));
  }
}
