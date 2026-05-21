import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';

ThemeData buildEarthpornTheme({
  Color? seedColor,
  bool reduceMotion = false,
  bool denseUi = false,
}) {
  final seed = seedColor ?? const Color(0xFF1B4332);
  final base = ThemeData(
    useMaterial3: true,
    visualDensity: denseUi ? VisualDensity.compact : VisualDensity.standard,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      primary: const Color(0xFF52B788),
      secondary: const Color(0xFFB7E4C7),
      surface: const Color(0xFF0A1610),
      tertiary: const Color(0xFF95D5B2),
    ),
  );
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF020806),
    splashFactory:
        reduceMotion ? NoSplash.splashFactory : InkSparkle.splashFactory,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: const Color(0xFFE8F5E9),
      displayColor: const Color(0xFFE8F5E9),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFD8F3DC),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: denseUi ? 64 : 72,
      backgroundColor: const Color(0xFF0D1F17).withValues(alpha: 0.88),
      indicatorColor: seed.withValues(alpha: 0.35),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF0F2419).withValues(alpha: 0.72),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme:
        DividerThemeData(color: Colors.white.withValues(alpha: 0.08)),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

String appTitle() => 'EarthPorn Wallpaper · ${AppSettings.creator}';
