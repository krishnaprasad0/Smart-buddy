import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color neonPurple = Color(0xFF9D50BB);
  static const Color neonBlue = Color(0xFF6E48AA);
  static const Color neonCyan = Color(0xFF00D2FF);
  static const Color darkBg = Color(0xFF0F0C29);
  static const Color surfaceColor = Color(0xFF1B1B3A);

  static ThemeData get neonTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPurple,
        surface: surfaceColor,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            headlineLarge: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
            bodyLarge: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: neonPurple.withOpacity(0.3)),
        ),
      ),
    );
  }
}
