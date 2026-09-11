import 'package:flutter/material.dart';

/// Central theme so screens use Theme.of(context) instead of inline styles
/// (AGENT.md §7).
class AppTheme {
  const AppTheme._();

  static const Color seedColor = Color(0xFF3F51B5);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      );
}
