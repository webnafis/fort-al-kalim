import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fort Al-Kalim dark theme
/// Color palette inspired by ancient Arabic architecture:
///   - Deep navy/slate backgrounds
///   - Warm gold accents (the "light of knowledge")
///   - Red war tones for the enemy fort
///   - Blue alliance tones for the player's fort
class AppTheme {
  AppTheme._();

  // ── Brand Colors ──────────────────────────────────────────────
  static const Color backgroundDark  = Color(0xFF0D1117); // Deep night
  static const Color surfaceDark     = Color(0xFF161B22); // Card surface
  static const Color surfaceElevated = Color(0xFF21262D); // Elevated surface

  static const Color gold            = Color(0xFFD4AF37); // Ancient gold
  static const Color goldLight       = Color(0xFFFFD700); // Bright gold
  static const Color goldDim         = Color(0xFF8B7332); // Dim gold

  static const Color redFort         = Color(0xFFE53E3E); // Enemy (red)
  static const Color redFortDim      = Color(0xFF742A2A); // Enemy dim
  static const Color blueFort        = Color(0xFF3182CE); // Player (blue)
  static const Color blueFortDim     = Color(0xFF2A4A6B); // Player dim

  static const Color success         = Color(0xFF38A169); // Correct answer
  static const Color error           = Color(0xFFE53E3E); // Wrong answer
  static const Color locked          = Color(0xFF4A5568); // Locked word

  static const Color textPrimary     = Color(0xFFE6EDF3); // Main text
  static const Color textSecondary   = Color(0xFF8B949E); // Secondary text
  static const Color textMuted       = Color(0xFF484F58); // Muted text

  static const Color borderColor     = Color(0xFF30363D); // Subtle border

  // ── Section Colors (attack types) ────────────────────────────
  static const Color sectionSee      = Color(0xFF805AD5); // Purple - See
  static const Color sectionListen   = Color(0xFF2B6CB0); // Blue   - Listen
  static const Color sectionWrite    = Color(0xFF276749); // Green  - Write
  static const Color sectionSpeak    = Color(0xFFC05621); // Orange - Speak

  // ── Dark Theme ────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary:    gold,
        secondary:  blueFort,
        error:      redFort,
        surface:    surfaceDark,
        onPrimary:  backgroundDark,
        onSecondary: textPrimary,
        onSurface:  textPrimary,
        onError:    textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: const TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary,
          ),
          headlineMedium: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary,
          ),
          titleLarge: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
          ),
          titleMedium: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16, color: textPrimary,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14, color: textSecondary,
          ),
          labelLarge: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: backgroundDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: const BorderSide(color: gold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
