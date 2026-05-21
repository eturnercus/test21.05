import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';

ThemeData buildEarthpornTheme() {
  const seed = Color(0xFF1B4332);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      primary: const Color(0xFF40916C),
      secondary: const Color(0xFF95D5B2),
      surface: const Color(0xFF0D1F17),
    ),
  );
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF05110C),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: const Color(0xFFE8F5E9),
      displayColor: const Color(0xFFE8F5E9),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: const Color(0xFF0D1F17).withValues(alpha: 0.92),
      elevation: 0,
      titleTextStyle: GoogleFonts.sora(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFD8F3DC),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF12261C).withValues(alpha: 0.95),
      elevation: 6,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.08)),
  );
}

String appTitle() => 'EarthPorn Wallpaper · ${AppSettings.creator}';
