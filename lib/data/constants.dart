import 'package:flutter/material.dart';

class AppColors {
  // Background color
  static const Color backgroundColor = Colors.white;
  // Text color
  static const Color textColor = Color(0xFF252525);
  // Primary color
  static const Color primaryColor = Color(0xFFF05632);
  // Secondary color
  static const Color secondaryColor = Color.fromARGB(255, 97, 97, 97);
}

class TextStyles {
  static const title = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 18,
    color: AppColors.textColor,
  );

  static const text = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: AppColors.textColor,
  );
}
