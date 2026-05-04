// lib/core/theme/app_styles.dart

import 'package:flutter/material.dart';
import 'app_text_styles.dart';
import 'app_colors.dart';
import 'figma_design_system.dart';

class AppStyles {
  static ButtonStyle primaryButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: EdgeInsets.symmetric(
          vertical: FigmaDesignSystem.buttonHeight * 0.33),
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(FigmaDesignSystem.borderRadius)),
    );
  }

  static ButtonStyle outlinedButton(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary1,
      side: const BorderSide(color: AppColors.primary1),
      padding: EdgeInsets.symmetric(
          vertical: FigmaDesignSystem.buttonHeight * 0.33),
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(FigmaDesignSystem.borderRadius)),
    );
  }

  static InputDecoration inputDecoration({
    required BuildContext context,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.hintText(context),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
      errorStyle: AppTextStyles.errorText(context),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: FigmaDesignSystem.fieldInnerPaddingHorizontal,
        vertical: FigmaDesignSystem.fieldInnerPaddingVertical,
      ),
    );
  }

  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius:
        BorderRadius.circular(FigmaDesignSystem.borderRadius * 1.5),
    boxShadow: const [
      BoxShadow(
          color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
    ],
  );

  static BoxDecoration gradientCircle = const BoxDecoration(
    gradient: LinearGradient(
      colors: AppColors.primaryGradient,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    shape: BoxShape.circle,
  );
}