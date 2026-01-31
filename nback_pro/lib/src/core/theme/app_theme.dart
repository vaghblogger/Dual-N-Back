import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme definitions for Dual N-Back Pro.
/// 3 Dark themes (0-2), 3 Light themes (3-5).
class AppTheme {
  AppTheme._();

  static const int themeCount = 6;

  static ThemeData getTheme(int id) {
    switch (id) {
      case 0:
        return _darkBw;
      case 1:
        return _darkNavy;
      case 2:
        return _darkForest;
      case 3:
        return _lightPaper;
      case 4:
        return _lightSand;
      case 5:
        return _lightSage;
      default:
        return _darkBw;
    }
  }

  static TextTheme _nunitoTextTheme(TextTheme base, Color color) {
    final nunito = GoogleFonts.nunitoTextTheme(base);
    return TextTheme(
      bodyLarge: nunito.bodyLarge?.copyWith(color: color),
      bodyMedium: nunito.bodyMedium?.copyWith(color: color),
      bodySmall: nunito.bodySmall?.copyWith(color: color),
      titleLarge: nunito.titleLarge?.copyWith(color: color),
      titleMedium: nunito.titleMedium?.copyWith(color: color),
      titleSmall: nunito.titleSmall?.copyWith(color: color),
    );
  }

  // Theme 0: Dark BW (Default)
  static final ThemeData _darkBw = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFFFFFFFF),
      surface: const Color(0xFF1E1E1E),
      onSurface: const Color(0xFFE0E0E0),
      onPrimary: const Color(0xFF121212),
    ),
    textTheme: _nunitoTextTheme(ThemeData.dark().textTheme, const Color(0xFFE0E0E0)),
  );

  // Theme 1: Dark Navy
  static final ThemeData _darkNavy = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A1929),
    cardColor: const Color(0xFF132F4C),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF90CAF9),
      surface: const Color(0xFF132F4C),
      onSurface: const Color(0xFFE3F2FD),
      onPrimary: const Color(0xFF0A1929),
    ),
    textTheme: _nunitoTextTheme(ThemeData.dark().textTheme, const Color(0xFFE3F2FD)),
  );

  // Theme 2: Dark Forest
  static final ThemeData _darkForest = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1B261B),
    cardColor: const Color(0xFF2C3E2C),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFFA5D6A7),
      surface: const Color(0xFF2C3E2C),
      onSurface: const Color(0xFFE8F5E9),
      onPrimary: const Color(0xFF1B261B),
    ),
    textTheme: _nunitoTextTheme(ThemeData.dark().textTheme, const Color(0xFFE8F5E9)),
  );

  // Theme 3: Light Paper
  static final ThemeData _lightPaper = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    cardColor: const Color(0xFFFFFFFF),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF616161),
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF212121),
      onPrimary: const Color(0xFFFFFFFF),
    ),
    textTheme: _nunitoTextTheme(ThemeData.light().textTheme, const Color(0xFF212121)),
  );

  // Theme 4: Light Sand
  static final ThemeData _lightSand = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFDFCF0),
    cardColor: const Color(0xFFFFFBE6),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF795548),
      surface: const Color(0xFFFFFBE6),
      onSurface: const Color(0xFF3E2723),
      onPrimary: const Color(0xFFFFFFFF),
    ),
    textTheme: _nunitoTextTheme(ThemeData.light().textTheme, const Color(0xFF3E2723)),
  );

  // Theme 5: Light Sage
  static final ThemeData _lightSage = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFEFF5E9),
    cardColor: const Color(0xFFFFFFFF),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF558B2F),
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF1B5E20),
      onPrimary: const Color(0xFFFFFFFF),
    ),
    textTheme: _nunitoTextTheme(ThemeData.light().textTheme, const Color(0xFF1B5E20)),
  );

  /// High contrast theme for accessibility (Section 9.3).
  static ThemeData getHighContrastTheme() {
    final base = ThemeData.dark().textTheme;
    final nunito = GoogleFonts.nunitoTextTheme(base);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      cardColor: const Color(0xFF1A1A1A),
      colorScheme: ColorScheme.dark(
        primary: Colors.yellow,
        surface: const Color(0xFF1A1A1A),
        onSurface: Colors.white,
        onPrimary: Colors.black,
      ),
      textTheme: TextTheme(
        bodyLarge: nunito.bodyLarge?.copyWith(color: Colors.white, fontSize: 18),
        bodyMedium: nunito.bodyMedium?.copyWith(color: Colors.white, fontSize: 16),
        bodySmall: nunito.bodySmall?.copyWith(color: Colors.white, fontSize: 14),
        titleLarge: nunito.titleLarge?.copyWith(color: Colors.white, fontSize: 22),
        titleMedium: nunito.titleMedium?.copyWith(color: Colors.white, fontSize: 20),
        titleSmall: nunito.titleSmall?.copyWith(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
