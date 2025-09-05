// theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ألوان لايت
  static const Color orangeLight = Color(0xFFFF9800); // برتقالي هادئ
  static const Color beigeLight = Color(0xFFF5F5DC);  // بيج هادئ

  // ألوان دارك
  static const Color orangeDark = Color(0xFFFF6F00); // برتقالي غامق
  static const Color blackDark = Color(0xFF121212);  // أسود غامق
  static const Color greyDark = Color(0xFF1E1E1E);   // رمادي غامق للحقول

  // ثيم لايت
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: beigeLight,
    primaryColor: orangeLight,
    colorScheme: ColorScheme.fromSeed(
      seedColor: orangeLight,
      primary: orangeLight,
      secondary: beigeLight,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: orangeLight,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: orangeLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: orangeLight, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.black87),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: orangeLight,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: orangeLight,
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
  );

  // ثيم دارك
  static ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: blackDark,
    primaryColor: orangeDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: orangeDark,
      primary: orangeDark,
      secondary: greyDark,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: blackDark,
      foregroundColor: orangeDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: orangeDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: greyDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: orangeDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: orangeDark, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: orangeDark,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: orangeDark,
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
