import 'package:flutter/material.dart';

/// App background gradient colors
const kBgTop = Color(0xFF0F172A);
const kBgBottom = Color(0xFF1E293B);

ThemeData buildDarkDialogTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    dialogTheme: const DialogThemeData(
      backgroundColor: kBgTop,
      surfaceTintColor: kBgTop,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white54),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    ),
    checkboxTheme: const CheckboxThemeData(
      side: BorderSide(color: Colors.white70),
      checkColor: WidgetStatePropertyAll(kBgTop),
      fillColor: WidgetStatePropertyAll(Colors.white),
    ),
  );
}

InputDecoration darkField(String label) => InputDecoration(labelText: label);
