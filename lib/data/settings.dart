import 'package:flutter/material.dart';
import 'package:image_editor_plus/data/constants.dart';

class Settings {
  // `Colors`
  final Color backgroundColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;
  // `Styles`
  final TextStyle titleStyle;
  final TextStyle normalStyle;
  // `Icons actions App bar`
  final IconData iconBack;
  final IconData iconSave;
  final IconData iconUndo;
  final IconData iconRedo;
  // `Icons bottom navigation bar`
  final IconData iconRotateLeft;
  final IconData iconRotateRight;
  final IconData iconFilter;
  final IconData iconCrop;
  final IconData iconFlip;
  // Icon Layers
  final IconData iconLayers;
  final IconData iconPortrait;
  final IconData iconLandscape;

  const Settings({
    this.backgroundColor = AppColors.backgroundColor,
    this.primaryColor = AppColors.primaryColor,
    this.secondaryColor = AppColors.secondaryColor,
    this.textColor = AppColors.textColor,
    this.titleStyle = TextStyles.title,
    this.normalStyle = TextStyles.text,
    this.iconBack = Icons.close_rounded,
    this.iconSave = Icons.check_rounded,
    this.iconFilter = Icons.photo_filter_rounded,
    this.iconCrop = Icons.crop,
    this.iconFlip = Icons.flip,
    this.iconRotateLeft = Icons.rotate_left,
    this.iconRotateRight = Icons.rotate_right,
    this.iconUndo = Icons.undo,
    this.iconRedo = Icons.redo,
    this.iconLayers = Icons.layers,
    this.iconLandscape = Icons.landscape,
    this.iconPortrait = Icons.portrait,
  });
}
