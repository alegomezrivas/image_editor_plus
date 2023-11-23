import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundLighter = Colors.white;
  static const Color textColor = Color(0xFF252525);
  static const Color accent = Color(0xFFFF10AA);
  static const Color mediumAccent = Color(0xFF9E1F63);
  static const Color mediaColor = Colors.pink;
  static const Color mediaAccentColor = Color.fromARGB(255, 97, 97, 97);
  static const Color textIconPostColor = Color.fromRGBO(37, 37, 37, 1.0);
}

class TextStyles {
  static const titlePost = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 19,
    color: AppColors.textIconPostColor,
  );
}

class AppIcons {
  static const String icon = 'assets/icon.png';
}
