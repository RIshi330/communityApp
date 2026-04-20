// theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static const lavender = Color(0xFF7C83FD);
  static const softLavender = Color(0xFFF1F2FF);
  static const border = Color(0xFFE6E6F0);
  static const muted = Color(0xFF6B7280);

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(seedColor: lavender),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: lavender),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    ),
  );
}
