// lib/shared/widgets/common/button.dart
// ✅ لا تعدّل — مأخوذ من Figma، imports مصلحة

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';


enum ButtonVariant { primary, secondary, destructive, outline, ghost, link }
enum ButtonSize    { small, medium, large, icon }

class Button extends StatelessWidget {
  final String        text;
  final VoidCallback  onPressed;
  final bool          isLoading;
  final bool          isDisabled;
  final bool          isFullWidth;
  final IconData?     icon;
  final ButtonVariant variant;
  final ButtonSize    size;
  final double?       height;
  final Color?        backgroundColor;
  final Color?        foregroundColor;

  const Button({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading       = false,
    this.isDisabled      = false,
    this.isFullWidth     = false,
    this.icon,
    this.variant         = ButtonVariant.primary,
    this.size            = ButtonSize.medium,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = !isDisabled && !isLoading;

    Color bgColor() {
      if (backgroundColor != null) return backgroundColor!;
      switch (variant) {
        case ButtonVariant.primary:     return AppColors.primary1;
        case ButtonVariant.secondary:   return AppColors.primary2;
        case ButtonVariant.destructive: return AppColors.errorFields;
        default:                        return Colors.transparent;
      }
    }

    Color fgColor() {
      if (foregroundColor != null) return foregroundColor!;
      switch (variant) {
        case ButtonVariant.primary:
        case ButtonVariant.secondary:
        case ButtonVariant.destructive: return Colors.white;
        case ButtonVariant.outline:     return AppColors.primary1;
        case ButtonVariant.ghost:       return AppColors.textPrimary;
        case ButtonVariant.link:        return AppColors.primary1;
      }
    }

    double btnHeight() {
      if (height != null) return height!;
      switch (size) {
        case ButtonSize.small:  return FigmaDesignSystem.buttonHeight * 0.75;
        case ButtonSize.medium: return FigmaDesignSystem.buttonHeight;
        case ButtonSize.large:  return FigmaDesignSystem.buttonHeight * 1.1;
        case ButtonSize.icon:   return FigmaDesignSystem.buttonHeight;
      }
    }

    EdgeInsets padding() {
      if (size == ButtonSize.icon) return const EdgeInsets.all(8);
      final g = FigmaDesignSystem.gapBetweenFields;
      switch (size) {
        case ButtonSize.small:
          return EdgeInsets.symmetric(horizontal: g * 0.75, vertical: g * 0.5);
        case ButtonSize.medium:
          return EdgeInsets.symmetric(horizontal: g, vertical: g * 0.6);
        case ButtonSize.large:
          return EdgeInsets.symmetric(horizontal: g * 1.25, vertical: g * 0.75);
        default:
          return EdgeInsets.zero;
      }
    }

    double fontSize() {
      switch (size) {
        case ButtonSize.small:  return 12;
        case ButtonSize.medium: return 14;
        case ButtonSize.large:  return 16;
        case ButtonSize.icon:   return 14;
      }
    }

    Widget label() => Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon,
              size: FigmaDesignSystem.getResponsiveFontSize(context, 16),
              color: fgColor()),
          const SizedBox(width: 8),
        ],
        Text(text,
            style: AppTextStyles.bodyMedium(context).copyWith(
                fontSize: FigmaDesignSystem.getResponsiveFontSize(
                    context, fontSize()),
                fontWeight: FontWeight.w500,
                color: fgColor())),
      ],
    );

    Widget spinner() => SizedBox(
      height: FigmaDesignSystem.getResponsiveFontSize(context, 20),
      width:  FigmaDesignSystem.getResponsiveFontSize(context, 20),
      child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
    );

    // ── link ────────────────────────────────────────────────────────────
    if (variant == ButtonVariant.link) {
      return TextButton(
        onPressed: isEnabled ? onPressed : null,
        style: TextButton.styleFrom(padding: padding()),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: FigmaDesignSystem.getResponsiveFontSize(context, 16),
                  color: fgColor()),
              const SizedBox(width: 4),
            ],
            Text(text,
                style: AppTextStyles.bodyMedium(context).copyWith(
                    decoration: TextDecoration.underline,
                    color: fgColor(),
                    fontSize: FigmaDesignSystem.getResponsiveFontSize(
                        context, fontSize()))),
          ],
        ),
      );
    }

    // ── outline / ghost ──────────────────────────────────────────────────
    if (variant == ButtonVariant.outline || variant == ButtonVariant.ghost) {
      return SizedBox(
        height: btnHeight(),
        width: isFullWidth ? double.infinity : null,
        child: TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            backgroundColor: bgColor(), foregroundColor: fgColor(),
            padding: padding(),
            minimumSize: isFullWidth
                ? Size(double.infinity, btnHeight())
                : Size(btnHeight() * 2, btnHeight()),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(FigmaDesignSystem.borderRadius),
              side: variant == ButtonVariant.outline
                  ? BorderSide(color: AppColors.stroke)
                  : BorderSide.none,
            ),
          ),
          child: isLoading ? spinner() : label(),
        ),
      );
    }

    // ── primary / secondary / destructive ────────────────────────────────
    final useGradient = variant == ButtonVariant.primary &&
        backgroundColor == null && !isDisabled;

    final btn = ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: useGradient ? Colors.transparent : bgColor(),
        foregroundColor: fgColor(),
        elevation: 0,
        padding: padding(),
        minimumSize: isFullWidth
            ? Size(double.infinity, btnHeight())
            : Size(btnHeight() * 2, btnHeight()),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(FigmaDesignSystem.borderRadius)),
      ),
      child: isLoading ? spinner() : label(),
    );

    if (useGradient) {
      return Container(
        width: isFullWidth ? double.infinity : null,
        height: btnHeight(),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
          borderRadius:
              BorderRadius.circular(FigmaDesignSystem.borderRadius),
        ),
        child: btn,
      );
    }
    return btn;
  }
}