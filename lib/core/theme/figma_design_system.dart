// lib/core/theme/figma_design_system.dart
// ⚠️ لا تعدّل هذا الملف — هو مصدر التصميم الوحيد من Figma

import 'package:flutter/material.dart';

class FigmaDesignSystem {
  static const double baseWidth                  = 343.0;
  static const double fieldHeight                = 48.0;
  static const double buttonHeight               = 48.0;
  static const double gapBetweenFields           = 16.0;
  static const double horizontalPadding          = 16.0;
  static const double fieldInnerPaddingHorizontal = 12.0;
  static const double fieldInnerPaddingVertical   = 8.0;
  static const double borderRadius               = 8.0;

  static double getResponsiveWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w > 500 ? 500 : w;
  }

  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final w = MediaQuery.of(context).size.width;
    if (w > 600) return baseSize * 1.2;
    if (w > 400) return baseSize * 1.1;
    return baseSize;
  }

  static double getVerticalSpacing(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.height * percentage;

  static double getTopPadding(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    if (h > 800) return 60;
    if (h > 600) return 40;
    return 20;
  }
}