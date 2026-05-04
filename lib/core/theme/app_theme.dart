// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'figma_design_system.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'Dubai',
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary1,
        secondary: AppColors.primary2,
        surface: Colors.white,
        error: AppColors.errorFields,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.primary1),
        titleTextStyle: TextStyle(
          fontFamily: 'Dubai',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary1,
          foregroundColor: Colors.white,
          minimumSize:
              const Size(double.infinity, FigmaDesignSystem.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(FigmaDesignSystem.borderRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FigmaDesignSystem.fieldInnerPaddingHorizontal,
          vertical: FigmaDesignSystem.fieldInnerPaddingVertical,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(FigmaDesignSystem.borderRadius),
          borderSide: const BorderSide(color: AppColors.stroke, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(FigmaDesignSystem.borderRadius),
          borderSide: const BorderSide(color: AppColors.stroke, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(FigmaDesignSystem.borderRadius),
          borderSide:
              const BorderSide(color: AppColors.primary1, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(FigmaDesignSystem.borderRadius),
          borderSide: const BorderSide(color: AppColors.errorFields, width: 0.5),
        ),
      ),
    );
  }
}