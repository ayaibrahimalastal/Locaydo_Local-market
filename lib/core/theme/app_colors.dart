// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryDark  = Color(0xFF084CDD);
  static const Color primaryLight = Color(0xFF2673FF);
  static const Color primary1     = Color(0xFF084CDD);
  static const Color primary2     = Color(0xFF2673FF);
  static const Color welcomeBackground = Color(0xFFF5F9FF);  

  static const Color primaryText    = Color(0xFF101010);
  static const Color textPrimary    = Color(0xFF101010);
  static const Color secondaryText  = Color(0xFF373737);
  static const Color textSecondary  = Color(0xFF373737);
  static const Color textPlaceholder = Color(0xFF969696);

  static const Color iconDefault    = Color(0xFF161616);
  static const Color iconforeground = Color(0xFF101010);
  static const Color iconDisabled   = Color(0xFFBDBDBD);

  static const Color stroke  = Color(0xFFCFCFCF);
  static const Color errorFields   = Color(0xFFD32F2F);
  static const Color errorSnackBar = Color(0xFF4E4E4F);
  static const Color success = Color(0xFF4E4E4F);
  static const Color warning = Color(0xFFFFA726);
  static const Color star    = Color(0xFFFFCB03);

  static const Color backgroundLight = Color(0xFFF5F9FF);
  static const Color backgroundWhite = Colors.white;
  static const Color cardBackground  = Color(0xFFF8FAFD);
  static const Color white           = Color(0xFFFFFFFF);

  static const Color disabledBackground = Color(0xFFF5F5F5);
  static const Color disabledBorder     = Color(0xFFE0E0E0);

  static const List<Color> primaryGradient = [primary1, primary2];
  static const LinearGradient primaryGradientLinear = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primaryLight],
  );

  static const Color backgroundGray = Color(0xFFF3F4F6);
  static const Color linkBlue       = Color(0xFF3B82F6);
}