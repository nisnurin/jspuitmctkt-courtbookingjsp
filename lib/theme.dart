import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config.dart';

/// Design tokens. Orange accent + Poppins follow the AFA reference design,
/// re-skinned as a dark, futuristic "sports HUD".
class C {
  static const bg = Color(0xFF07080C);
  static const surface = Color(0xFF0E1016);
  static const surface2 = Color(0xFF161925);
  static const border = Color(0xFF262B3B);
  static const orange = Color(0xFFFF5A0A);
  static const cyan = Color(0xFF22D3EE);
  static const text = Color(0xFFF4F5F8);
  static const muted = Color(0xFFA3AABB);
  static const success = Color(0xFF34D399);
  static const danger = Color(0xFFF87171);
  static const onAccent = Color(0xFF0B0B0F);
}

extension ColorX on Color {
  Color o(double opacity) => withAlpha((opacity * 255).round().clamp(0, 255));
}

/// Each court has its own colour AND icon, so colour is never the only cue.
Color courtColor(String court) =>
    court == AppConfig.courtKolej ? C.orange : C.cyan;

IconData courtIcon(String court) =>
    court == AppConfig.courtKolej ? Icons.apartment_rounded : Icons.school_rounded;

ThemeData buildTheme({bool light = false}) {
  final base = ThemeData(
    brightness: light ? Brightness.light : Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: light ? const Color(0xFFF5F6FA) : C.bg,
    colorScheme: light ? const ColorScheme.light(
      primary: C.orange, onPrimary: Colors.white, secondary: Color(0xFF087F8C),
      surface: Colors.white, onSurface: Color(0xFF1A1D27), error: Color(0xFFB42318),
    ) : const ColorScheme.dark(
      primary: C.orange,
      onPrimary: C.onAccent,
      secondary: C.cyan,
      surface: C.surface,
      onSurface: C.text,
      error: C.danger,
    ),
  );
  final text = GoogleFonts.poppinsTextTheme(base.textTheme)
      .apply(
        bodyColor: light ? const Color(0xFF1A1D27) : C.text,
        displayColor: light ? const Color(0xFF1A1D27) : C.text,
      );

  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    textTheme: text,
    primaryTextTheme: text,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: C.muted),
      hintStyle: TextStyle(color: C.muted.o(0.7)),
      prefixIconColor: C.muted,
      border: b(C.border),
      enabledBorder: b(C.border),
      focusedBorder: b(C.orange, 2),
      errorBorder: b(C.danger),
      focusedErrorBorder: b(C.danger, 2),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.surface2,
      contentTextStyle: GoogleFonts.poppins(color: C.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerColor: C.border,
  );
}
