import 'package:flutter/material.dart';

const accent = Color(0xFFE8A93A);
const accent2 = Color(0xFF3FA796);
const dangerColor = Color(0xFFD9634A);
const okColor = Color(0xFF4CAF7D);

ThemeData buildTheme(bool dark) {
  final bg = dark ? const Color(0xFF0F1419) : const Color(0xFFF7F5F0);
  final panel = dark ? const Color(0xFF171D26) : const Color(0xFFFFFFFF);
  final panel2 = dark ? const Color(0xFF1E2733) : const Color(0xFFF0EDE6);
  final text = dark ? const Color(0xFFE8ECEF) : const Color(0xFF232019);
  final sub = dark ? const Color(0xFF8B98A5) : const Color(0xFF6E675A);
  final line = dark ? const Color(0xFF2A3441) : const Color(0xFFE1DCD1);

  return ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bg,
    primaryColor: accent,
    colorScheme: ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: accent,
      onPrimary: const Color(0xFF1A1408),
      secondary: accent2,
      onSecondary: Colors.white,
      error: dangerColor,
      onError: Colors.white,
      surface: panel,
      onSurface: text,
    ),
    cardColor: panel,
    dividerColor: line,
    fontFamily: 'Roboto',
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: text),
      bodyMedium: TextStyle(color: text),
      bodySmall: TextStyle(color: sub),
      titleLarge: TextStyle(color: text, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: text, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: panel2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: TextStyle(color: sub, fontSize: 12.5),
    ),
    appBarTheme: AppBarTheme(backgroundColor: bg, foregroundColor: text, elevation: 0),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: const Color(0xFF1A1408),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: panel,
      selectedItemColor: accent,
      unselectedItemColor: sub,
      type: BottomNavigationBarType.fixed,
    ),
    extensions: [AppColors(bg: bg, panel: panel, panel2: panel2, text: text, sub: sub, line: line)],
  );
}

/// Extra semantic colors not covered by ColorScheme, mirrors the web app's
/// CSS variable tokens so both versions stay visually consistent.
class AppColors extends ThemeExtension<AppColors> {
  final Color bg, panel, panel2, text, sub, line;
  AppColors({required this.bg, required this.panel, required this.panel2, required this.text, required this.sub, required this.line});

  @override
  AppColors copyWith({Color? bg, Color? panel, Color? panel2, Color? text, Color? sub, Color? line}) => AppColors(
        bg: bg ?? this.bg,
        panel: panel ?? this.panel,
        panel2: panel2 ?? this.panel2,
        text: text ?? this.text,
        sub: sub ?? this.sub,
        line: line ?? this.line,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) => this;
}
