// theme_provider.dart
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool isDark = false;

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }

  final Color orangeLight = const Color(0xFFFF9800);
  final Color beigeLight = const Color(0xFFFFF5E1);
  final Color orangeDark = const Color(0xFFB85C00);

  ThemeData get lightTheme => ThemeData(
        scaffoldBackgroundColor: beigeLight,
        primaryColor: orangeLight,
        appBarTheme: AppBarTheme(
          backgroundColor: orangeLight,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: orangeLight,
          brightness: Brightness.light,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: orangeLight,
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        useMaterial3: true,
      );

  ThemeData get darkTheme => ThemeData(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: orangeDark,
        appBarTheme: AppBarTheme(
          backgroundColor: orangeDark,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: orangeDark,
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: orangeDark,
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        useMaterial3: true,
      );
}