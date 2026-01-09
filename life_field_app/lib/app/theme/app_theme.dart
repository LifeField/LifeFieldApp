import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const primaryGreen = Color(0xFF2ECC71);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 25, 211, 118)).copyWith(
      primary: const Color.fromARGB(255, 25, 211, 118),
      secondary: const Color.fromARGB(255, 25, 211, 118),
    ),
  );

  return base.copyWith(
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
        side: const BorderSide(color: Color.fromARGB(255, 25, 211, 118)),
        foregroundColor: const Color.fromARGB(255, 25, 211, 118),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    ),
  );
}
