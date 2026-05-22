import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../desktop/desktop_integration.dart';
import '../models/app_settings.dart';
import '../platform/android_wallpaper_bridge.dart';
import '../services/github_update_check.dart';
import '../services/settings_repository.dart';
import '../services/wallpaper_engine.dart';
import 'app_keys.dart';
import 'home_page.dart';
import 'main_help_overlay.dart';
import 'onboarding_page.dart';
import 'settings_page.dart';
import 'theme.dart';
import 'app_locale_text.dart';

Locale? _localeForSettings(int code) {
  if (code == AppSettings.uiLanguageRu) return const Locale('ru');
  if (code == AppSettings.uiLanguageEn) return const Locale('en');
  return null;
}

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
            locale: _localeForSettings(s.uiLanguageCode),
            supportedLocales: const [
              Locale('ru'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navCtx = earthpornNavigatorKey.currentContext;
      if (navCtx == null) return;
      unawaited(
        GithubUpdateCheck.runIfEligible(
          context: navCtx,
          settingsRepo: Provider.of<SettingsRepository>(navCtx, listen: false),
        ),
      );
      unawaited(_consumeAndroidLaunchAction(navCtx));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final navCtx = earthpornNavigatorKey.currentContext;
      if (navCtx != null) {
        unawaited(_consumeAndroidLaunchAction(navCtx));
      }
    }
  }

  Future<void> _consumeAndroidLaunchAction(BuildContext navCtx) async {
    if (kIsWeb || !Platform.isAndroid) return;
    final eng = Provider.of<WallpaperEngine>(navCtx, listen: false);
    final action = await AndroidWallpaperBridge.getPendingLaunchAction();
    if (action == null || !mounted) return;
    await AndroidWallpaperBridge.clearPendingLaunchAction();
    if (action == 'next_wallpaper') {
      await eng.nextWallpaperQuick();
      if (mounted) {
        await AndroidWallpaperBridge.moveTaskToBack();
      }
    }
  }

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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.landscape_outlined),
            selectedIcon: const Icon(Icons.landscape),
            label: t(context, ru: 'Обои', en: 'Wallpapers'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune),
            label: t(context, ru: 'Настройки', en: 'Settings'),
          ),
        ],
      ),
    );
  }
}
