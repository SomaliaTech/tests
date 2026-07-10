import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2ED573);
  static const Color unselectedColor = Color(0xFF999999);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFEEEEEE);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
