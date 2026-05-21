import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../desktop/desktop_integration.dart';
import '../services/settings_repository.dart';
import '../services/wallpaper_engine.dart';
import 'app_keys.dart';
import 'home_page.dart';
import 'settings_page.dart';
import 'theme.dart';

class EarthpornApp extends StatefulWidget {
  const EarthpornApp({
    super.key,
    required this.engine,
    required this.settings,
  });

  final WallpaperEngine engine;
  final SettingsRepository settings;

  @override
  State<EarthpornApp> createState() => _EarthpornAppState();
}

class _EarthpornAppState extends State<EarthpornApp> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_started) return;
      _started = true;
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
        await bootstrapDesktop(
          widget.engine,
          widget.settings,
          earthpornNavigatorKey,
        );
      }
      await widget.engine.start();
    });
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
      child: MaterialApp(
        navigatorKey: earthpornNavigatorKey,
        debugShowCheckedModeBanner: false,
        title: appTitle(),
        theme: buildEarthpornTheme(),
        initialRoute: '/',
        routes: {
          '/': (_) => const HomePage(),
          '/settings': (_) => const SettingsPage(),
        },
      ),
    );
  }
}
