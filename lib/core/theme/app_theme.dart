import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color buddyTeal = Color(0xFF00A884);
  static const Color buddyGreen = Color(0xFF005C4B);
  static const Color buddyGreenLight = Color(0xFF008069);
  static const Color darkBg = Color(0xFF111B21);
  static const Color surfaceColor = Color(0xFF202C33);
  static const Color chatBg = Color(0xFF0B141A);
  static const Color bubbleGrey = Color(0xFFE9EDEF);
  static const Color bubbleBlue = Color(0xFF00A3FF);

  static ThemeData get buddyTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: buddyTeal,
        secondary: buddyGreen,
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
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
    );
  }
}
