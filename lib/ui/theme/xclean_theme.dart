import 'package:flutter/material.dart';

class XCleanTheme {
  // OLED / Deep Slate Backgrounds
  static const Color background = Color(0xFF0D0F12);
  static const Color cardBg = Color(0xFF161920);
  static const Color cardSubtle = Color(0xFF1F232B);
  static const Color border = Color(0xFF262A34);

  // WHOOP & Revolut Accent Colors
  static const Color emerald = Color(0xFF00E676); // High Score / Optimal (85-100)
  static const Color cyan = Color(0xFF00E5FF);    // Secondary Accent / Bluetooth
  static const Color amber = Color(0xFFFFB300);   // Moderate Score / Warning (65-84)
  static const Color coral = Color(0xFFFF5252);   // Low Score / Critical (<65)
  static const Color textMuted = Color(0xFF8E95A5);
  static const Color textLight = Color(0xFFFFFFFF);

  static Color getScoreColor(int score) {
    if (score >= 85) return emerald;
    if (score >= 65) return amber;
    return coral;
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: cyan,
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        secondary: emerald,
        surface: cardBg,
      ),
      cardTheme: const CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
      ),
      useMaterial3: true,
    );
  }
}
