// lib/core/utils/helpers.dart

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';

class Helpers {
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void hideKeyboard(BuildContext context) =>
      FocusScope.of(context).unfocus();

  static String formatPrice(double price) =>
      '${price.toStringAsFixed(2)} ₪';
}