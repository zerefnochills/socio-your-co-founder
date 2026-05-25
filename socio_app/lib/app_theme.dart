import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Socio Design System — v2.0
/// Aesthetic: Warm editorial luxury. Think Notion meets Linear meets a premium journal.
/// NOT another purple-gradient AI app.
class SocioTheme {
  SocioTheme._();

  // ── Palette ──────────────────────────────────────────────────────────────────
  static const Color forestGreen   = Color(0xFF0B3A22);
  static const Color forestGreenLt = Color(0xFF1A5C38);

  static const Color inkBlack      = Color(0xFF0D0D0D);
  static const Color inkDeep       = Color(0xFF1A1A2E);

  static const Color creamBg       = Color(0xFFF7F4EB);
  static const Color creamCard     = Color(0xFFFBF9F3);
  static const Color creamBorder   = Color(0xFFE8E3D5);

  static const Color slateText     = Color(0xFF0F172A);
  static const Color mutedText     = Color(0xFF64748B);
  static const Color placeholderText = Color(0xFFAFB8C4);

  static const Color violet        = Color(0xFF6D28D9);
  static const Color violetLight   = Color(0xFF8B5CF6);
  static const Color violetSurface = Color(0xFFF0EBFF);

  static const Color amber         = Color(0xFFF59E0B);
  static const Color rose          = Color(0xFFE11D48);
  static const Color emeraldAccent = Color(0xFF10B981);

  // Persona colours
  static const Color skepticColor   = Color(0xFFDC2626); // red-600
  static const Color hustlerColor   = Color(0xFFF59E0B); // amber-400
  static const Color strategistColor = Color(0xFF2563EB); // blue-600

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
    BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> get shadowGreen => [
    BoxShadow(color: forestGreen.withOpacity(0.20), blurRadius: 16, offset: const Offset(0, 6)),
    BoxShadow(color: forestGreen.withOpacity(0.08), blurRadius: 32, offset: const Offset(0, 16)),
  ];

  static List<BoxShadow> get shadowViolet => [
    BoxShadow(color: violet.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
    BoxShadow(color: violet.withOpacity(0.10), blurRadius: 32, offset: const Offset(0, 16)),
  ];

  // ── Border Radii ─────────────────────────────────────────────────────────
  static const BorderRadius radiusSm  = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd  = BorderRadius.all(Radius.circular(14));
  static const BorderRadius radiusLg  = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusXl  = BorderRadius.all(Radius.circular(28));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(999));

  // ── Typography ───────────────────────────────────────────────────────────
  // Display font: Outfit — expressive, contemporary, personality
  // Body font: DM Sans — warm, very readable at small sizes
  static TextTheme get textTheme => TextTheme(
    // Hero display
    displayLarge: GoogleFonts.outfit(
      fontSize: 40, fontWeight: FontWeight.w700,
      color: slateText, letterSpacing: -1.2, height: 1.05,
    ),
    displayMedium: GoogleFonts.outfit(
      fontSize: 32, fontWeight: FontWeight.w700,
      color: slateText, letterSpacing: -0.8, height: 1.1,
    ),
    displaySmall: GoogleFonts.outfit(
      fontSize: 26, fontWeight: FontWeight.w600,
      color: slateText, letterSpacing: -0.5, height: 1.15,
    ),
    // Headings
    headlineLarge: GoogleFonts.outfit(
      fontSize: 22, fontWeight: FontWeight.w600,
      color: slateText, letterSpacing: -0.3,
    ),
    headlineMedium: GoogleFonts.outfit(
      fontSize: 18, fontWeight: FontWeight.w600,
      color: slateText, letterSpacing: -0.2,
    ),
    headlineSmall: GoogleFonts.outfit(
      fontSize: 16, fontWeight: FontWeight.w600,
      color: slateText,
    ),
    // Body
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 16, fontWeight: FontWeight.w400,
      color: slateText, height: 1.6,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 14, fontWeight: FontWeight.w400,
      color: slateText, height: 1.55,
    ),
    bodySmall: GoogleFonts.dmSans(
      fontSize: 12, fontWeight: FontWeight.w400,
      color: mutedText, height: 1.5,
    ),
    // Labels
    labelLarge: GoogleFonts.dmSans(
      fontSize: 14, fontWeight: FontWeight.w600,
      color: slateText, letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.dmSans(
      fontSize: 12, fontWeight: FontWeight.w600,
      color: mutedText, letterSpacing: 0.3,
    ),
    labelSmall: GoogleFonts.dmSans(
      fontSize: 10, fontWeight: FontWeight.w700,
      color: mutedText, letterSpacing: 0.8,
    ),
  );

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: creamBg,
    colorScheme: ColorScheme.light(
      primary: forestGreen,
      onPrimary: Colors.white,
      primaryContainer: violetSurface,
      secondary: violet,
      onSecondary: Colors.white,
      surface: creamCard,
      onSurface: slateText,
      outline: creamBorder,
      error: rose,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: creamBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: slateText, letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: slateText),
    ),
    cardTheme: CardThemeData(
      color: creamCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radiusMd,
        side: const BorderSide(color: creamBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: creamCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: const BorderSide(color: creamBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: const BorderSide(color: creamBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: const BorderSide(color: forestGreen, width: 1.5),
      ),
      hintStyle: GoogleFonts.dmSans(color: placeholderText, fontSize: 14),
      labelStyle: GoogleFonts.dmSans(color: mutedText, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: radiusMd),
        textStyle: GoogleFonts.outfit(
          fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: slateText,
        side: const BorderSide(color: creamBorder, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: const RoundedRectangleBorder(borderRadius: radiusMd),
        textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: creamCard,
      side: const BorderSide(color: creamBorder),
      labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: slateText),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: const RoundedRectangleBorder(borderRadius: radiusFull),
    ),
    dividerTheme: const DividerThemeData(
      color: creamBorder, thickness: 1, space: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: creamCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: inkDeep,
      contentTextStyle: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
      shape: const RoundedRectangleBorder(borderRadius: radiusMd),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ── Reusable decorators ────────────────────────────────────────────────────

/// Warm cream card with subtle border shadow
BoxDecoration socioCardDecoration({
  Color? color,
  BorderRadius? borderRadius,
  bool elevated = false,
}) =>
    BoxDecoration(
      color: color ?? SocioTheme.creamCard,
      borderRadius: borderRadius ?? SocioTheme.radiusMd,
      border: Border.all(color: SocioTheme.creamBorder, width: 1),
      boxShadow: elevated ? SocioTheme.shadowSm : null,
    );

/// Forest green gradient for primary CTAs / banners
BoxDecoration socioGreenDecoration({BorderRadius? borderRadius}) =>
    BoxDecoration(
      gradient: const LinearGradient(
        colors: [SocioTheme.forestGreen, SocioTheme.forestGreenLt],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: borderRadius ?? SocioTheme.radiusMd,
      boxShadow: SocioTheme.shadowGreen,
    );
