import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Palette ───────────────────────────────────────────────────────────
const kBgDark      = Color(0xFF0A0E1A);
const kBgCard      = Color(0xFF111827);
const kBgCardAlt   = Color(0xFF1A2235);
const kAccentCyan  = Color(0xFF00D4FF);
const kAccentGreen = Color(0xFF00E676);
const kAccentRed   = Color(0xFFFF4757);
const kAccentAmber = Color(0xFFFFB300);
const kTextPrimary = Color(0xFFE8EAF0);
const kTextSecond  = Color(0xFF8A97B0);
const kBorderColor = Color(0xFF1E2D45);

// ─── Risk Colors ─────────────────────────────────────────────────────────────
Color riskColor(String level) {
  switch (level.toLowerCase()) {
    case 'high':      return kAccentRed;
    case 'medium':    return kAccentAmber;
    case 'low':
    default:          return kAccentGreen;
  }
}

IconData riskIcon(String level) {
  switch (level.toLowerCase()) {
    case 'high':   return Icons.dangerous_rounded;
    case 'medium': return Icons.warning_amber_rounded;
    case 'low':
    default:       return Icons.verified_user_rounded;
  }
}

// ─── Theme ───────────────────────────────────────────────────────────────────
ThemeData buildTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: kBgDark,
    colorScheme: const ColorScheme.dark(
      primary:   kAccentCyan,
      secondary: kAccentGreen,
      surface:   kBgCard,
      error:     kAccentRed,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.orbitron(
        fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary,
        letterSpacing: 1.2,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 20, fontWeight: FontWeight.w600, color: kTextPrimary,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 13, color: kTextSecond,
      ),
      labelSmall: GoogleFonts.spaceGrotesk(
        fontSize: 11, color: kTextSecond, letterSpacing: 0.8,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kBgDark,
      elevation: 0,
      titleTextStyle: GoogleFonts.orbitron(
        fontSize: 16, fontWeight: FontWeight.w700,
        color: kAccentCyan, letterSpacing: 1.5,
      ),
      iconTheme: const IconThemeData(color: kAccentCyan),
    ),
    cardTheme: CardThemeData(
      color: kBgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorderColor, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBgCardAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kAccentCyan, width: 1.5),
      ),
      hintStyle: GoogleFonts.spaceGrotesk(color: kTextSecond, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}