import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Reds
  static const Color primaryRed = Color(0xFFED5656);
  static const Color carnelian = Color(0xFFB31B1B);
  static const Color accentRed = Color(0xFFE95755);
  static const Color activeRed = Color(0xFFEC5555);
  static const Color lightRed = Color(0xFFFF8080);

  // MaterialColor for ThemeData
  static const MaterialColor primaryRedSwatch = MaterialColor(
    0xFFED5656,
    <int, Color>{
      50: primaryRed,
      100: primaryRed,
      200: primaryRed,
      300: primaryRed,
      400: primaryRed,
      500: primaryRed,
      600: primaryRed,
      700: primaryRed,
      800: primaryRed,
      900: primaryRed,
    },
  );

  // Secondary
  static const Color purple = Color(0xFF835A7C);
  static const Color gold = Color(0xFFC17E19);
  static const Color yellow = Color(0xFFFFC737);
  static const Color orange = Color(0xFFFFAA5B);
  static const Color green = Color(0xFF58B171);
  static const Color greenDark = Color(0xFF31B346);

  // Backgrounds
  static const Color warmWhite = Color(0xFFFFF8F1);
  static const Color cream = Color(0xFFF9EDDA);
  static const Color quizBackground = Color(0xFFF9F5F1);
  static const Color pageGrayBackground = Color(0xFFDBE2E7);
  static const Color skyBlue = Color(0xFFB3EBF6);

  // Grays & Text
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color mediumText = Color(0xFF474747);
  static const Color grayText = Color(0xFF6E6E6E);
  static const Color mediumGray = Color(0xFFA4A4A4);
  static const Color lightGray = Color(0xFFF1F1F1);
  static const Color lightGrayBorder = Color(0xFFE5E5E5);

  // Special
  static const Color leaderboardGoldBorder = Color(0xFFFBDDAF);
  static const Color fadedRed = Color(0xFFF08988);
  static const Color lightRedBackground = Color(0xFFF3C6C6);
}
