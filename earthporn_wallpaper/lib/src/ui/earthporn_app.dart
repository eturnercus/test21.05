import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../desktop/desktop_integration.dart';
import '../services/settings_repository.dart';
import '../services/wallpaper_engine.dart';
import 'app_keys.dart';
import 'home_page.dart';
import 'main_help_overlay.dart';
import 'onboarding_page.dart';
import 'settings_page.dart';
import 'theme.dart';

class EarthpornApp extends StatefulWidget {
  const EarthpornApp({super.key, required this.engine, required this.settings});

  final WallpaperEngine engine;
  final SettingsRepository settings;

  @override
  State<EarthpornApp> createState() => _EarthpornAppState();
}

class _EarthpornAppState extends State<EarthpornApp> {
  bool _started = false;
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _loadOnboarding();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_started) return;
      _started = true;
      try {
        if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
          await bootstrapDesktop(
            widget.engine,
            widget.settings,
            earthpornNavigatorKey,
          );
        }
        await widget.engine.start();
      } catch (e, st) {
        debugPrint('Earthporn startup error: $e');
        debugPrint('$st');
      }
    });
  }

  Future<void> _loadOnboarding() async {
    final p = await SharedPreferences.getInstance();
    final done = p.getBool('onboarding_v2_done') ?? false;
    if (mounted) setState(() => _onboardingDone = done);
  }

  @override
  void dispose() {
    widget.engine.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.settings),
        ChangeNotifierProvider.value(value: widget.engine),
      ],
      child: ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) {
          final s = widget.settings.settings;
          return MaterialApp(
            navigatorKey: earthpornNavigatorKey,
            debugShowCheckedModeBanner: false,
            title: appTitle(),
            theme: buildEarthpornTheme(
              seedColor: Color(s.accentColorValue),
              reduceMotion: s.reduceMotion,
              denseUi: s.denseUi,
            ),
            routes: {'/settings': (_) => const SettingsPage()},
            home: _buildHome(),
          );
        },
      ),
    );
  }

  Widget _buildHome() {
    if (_onboardingDone == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_onboardingDone! && !kIsWeb && Platform.isAndroid) {
      return OnboardingPage(
        onFinished: () {
          setState(() => _onboardingDone = true);
        },
      );
    }
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.surface.withValues(alpha: 0.55),
                    scheme.surfaceContainerLowest,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IndexedStack(
              index: _index,
              children: const [HomePage(), SettingsPage()],
            ),
          ),
          const Positioned.fill(child: MainHelpOverlay()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.landscape_outlined),
            selectedIcon: Icon(Icons.landscape),
            label: 'Обои',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
