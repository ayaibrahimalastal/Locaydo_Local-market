// lib/core/theme/app_text_styles.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'figma_design_system.dart';

class AppTextStyles {
  static const String fontFamily = 'Dubai';

  static double _fs(BuildContext ctx, double s) =>
      FigmaDesignSystem.getResponsiveFontSize(ctx, s);

  static TextStyle displayLarge(BuildContext ctx) => TextStyle(
        fontFamily: fontFamily, fontSize: _fs(ctx, 28),
        fontWeight: FontWeight.bold, color: AppColors.textPrimary);

  static TextStyle displayMedium(BuildContext ctx) => TextStyle(
        fontFamily: fontFamily, fontSize: _fs(ctx, 20),
        fontWeight: FontWeight.bold, color: AppColors.textPrimary);

  static TextStyle displaySmall(BuildContext ctx) => TextStyle(
        fontFamily: fontFamily, fontSize: _fs(ctx, 18),
        fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle bodyLarge(BuildContext ctx) => TextStyle(
        fontFamily: fontFamily, fontSize: _fs(ctx, 16),
        fontWeight: FontWeight.w500, color: AppColors.textPrimary);

  static TextStyle bodyMedium(BuildContext ctx) => TextStyle(
        fontFamily: fontFamily, fontSize: _fs(ctx, 14),
        fontWeight: FontWeight.normal, color: AppColors.textPrimary);

  static TextStyle bodySmall(BuildContext ctx) => TextStyle(
        fontFamily: fontFamily, fontSize: _fs(ctx, 12),
        fontWeight: FontWeight.normal, color: AppColors.textSecondary);

  static TextStyle buttonText(BuildContext ctx) => TextStyle(
        fontFamily: fontFamily, fontSize: _fs(ctx, 16),
        fontWeight: FontWeight.bold, color: Colors.white);

  static TextStyle errorText(BuildContext ctx) => TextStyle(
        fontFamily: fontFamily, fontSize: _fs(ctx, 11),
        fontWeight: FontWeight.w500, color: AppColors.errorFields);

  static TextStyle hintText(BuildContext ctx) => TextStyle(
        fontFamily: fontFamily, fontSize: _fs(ctx, 14),
        fontWeight: FontWeight.normal, color: AppColors.textPlaceholder);
}