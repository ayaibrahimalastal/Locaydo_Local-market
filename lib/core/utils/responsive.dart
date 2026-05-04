// lib/core/utils/responsive.dart

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';

class Responsive {
  static double getVerticalSpacing(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.height * percentage;

  static double getHorizontalSpacing(BuildContext context, double percentage) =>
      MediaQuery.of(context).size.width * percentage;

  static double getFontSize(BuildContext context, double baseSize) =>
      FigmaDesignSystem.getResponsiveFontSize(context, baseSize);

  static double getWidth(BuildContext context) =>
      FigmaDesignSystem.getResponsiveWidth(context);

  static EdgeInsets getScreenPadding(BuildContext context) =>
      EdgeInsets.all(FigmaDesignSystem.horizontalPadding);

  static double getTopPadding(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    if (h > 800) return 60;
    if (h > 600) return 40;
    return 20;
  }
}