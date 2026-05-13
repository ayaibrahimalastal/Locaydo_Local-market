// lib/shared/widgets/common/favorite_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';

/// موضع زر المفضلة
enum FavoriteButtonPosition {
  topLeft,
  topRight,
}

/// حجم زر المفضلة
enum FavoriteButtonSize {
  small,
  medium,
  large,
}

/// زر المفضلة القابل لإعادة الاستخدام
class FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final FavoriteButtonPosition position;
  final FavoriteButtonSize size;
  final double? customSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;
  final bool showBackground;
  final bool showBorder;

  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.position = FavoriteButtonPosition.topRight,
    this.size = FavoriteButtonSize.medium,
    this.customSize,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
    this.showBackground = true,
    this.showBorder = true,
  });

  double _getSize(BuildContext context) {
    if (customSize != null) return customSize!;
    
    switch (size) {
      case FavoriteButtonSize.small:
        return context.responsiveFontSize(12);
      case FavoriteButtonSize.medium:
        return context.responsiveFontSize(16);
      case FavoriteButtonSize.large:
        return context.responsiveFontSize(20);
    }
  }

  double _getPadding() {
    switch (size) {
      case FavoriteButtonSize.small:
        return 4;
      case FavoriteButtonSize.medium:
        return 6;
      case FavoriteButtonSize.large:
        return 8;
    }
  }

  Color _getIconColor() {
    if (isFavorite) {
      return activeColor ?? AppColors.errorFields;
    }
    return inactiveColor ?? AppColors.iconforeground;
  }

  Widget _buildButton(BuildContext context) {
    final iconSize = _getSize(context);
    final paddingValue = _getPadding();  // ✅ تصحيح: استدعاء الدالة بشكل صحيح
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(paddingValue),  // ✅ استخدام paddingValue
        decoration: showBackground
            ? BoxDecoration(
                color: backgroundColor ?? Colors.white,
                shape: BoxShape.circle,
                border: showBorder
                    ? Border.all(
                        color: Colors.black.withOpacity(0.12),
                        width: 0.8,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              )
            : null,
        child: SvgPicture.asset(
          isFavorite ? AppAssets.heartFilled : AppAssets.heart,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(
            _getIconColor(),
            BlendMode.srcIn,
          ),
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _getIconColor(),
              size: iconSize,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ استخدام Align بدلاً من Positioned لحل مشكلة الاختبارات
    return Align(
      alignment: position == FavoriteButtonPosition.topLeft
          ? Alignment.topLeft
          : Alignment.topRight,
      child: _buildButton(context),
    );
  }
}

/// نسخة تستخدم Positioned (للاستخدام داخل Stack فقط)
class PositionedFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final FavoriteButtonPosition position;
  final FavoriteButtonSize size;
  final double? customSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;
  final bool showBackground;
  final bool showBorder;
  final double top;
  final double left;
  final double right;

  const PositionedFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.position = FavoriteButtonPosition.topRight,
    this.size = FavoriteButtonSize.medium,
    this.customSize,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
    this.showBackground = true,
    this.showBorder = true,
    this.top = 6,
    this.left = 6,
    this.right = 6,
  });

  double _getSize() {
    if (customSize != null) return customSize!;
    
    switch (size) {
      case FavoriteButtonSize.small:
        return 12;
      case FavoriteButtonSize.medium:
        return 16;
      case FavoriteButtonSize.large:
        return 20;
    }
  }

  double _getPadding() {
    switch (size) {
      case FavoriteButtonSize.small:
        return 4;
      case FavoriteButtonSize.medium:
        return 6;
      case FavoriteButtonSize.large:
        return 8;
    }
  }

  Widget _buildButton() {
    final iconSize = _getSize();
    final paddingValue = _getPadding();  // ✅ تصحيح
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(paddingValue),  // ✅ استخدام paddingValue
        decoration: showBackground
            ? BoxDecoration(
                color: backgroundColor ?? Colors.white,
                shape: BoxShape.circle,
                border: showBorder
                    ? Border.all(
                        color: Colors.black.withOpacity(0.12),
                        width: 0.8,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              )
            : null,
        child: SvgPicture.asset(
          isFavorite ? AppAssets.heartFilled : AppAssets.heart,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(
            isFavorite ? (activeColor ?? AppColors.errorFields) : (inactiveColor ?? AppColors.iconforeground),
            BlendMode.srcIn,
          ),
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? (activeColor ?? AppColors.errorFields) : (inactiveColor ?? AppColors.iconforeground),
              size: iconSize,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: position == FavoriteButtonPosition.topLeft ? left : null,
      right: position == FavoriteButtonPosition.topRight ? right : null,
      child: _buildButton(),
    );
  }
}

/// نسخة مبسطة (بدون Positioning)
class SimpleFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  final FavoriteButtonSize size;
  final double? customSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showBorder;

  const SimpleFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
    this.size = FavoriteButtonSize.medium,
    this.customSize,
    this.activeColor,
    this.inactiveColor,
    this.showBorder = true,
  });

  double _getSize(BuildContext context) {
    if (customSize != null) return customSize!;
    
    switch (size) {
      case FavoriteButtonSize.small:
        return context.responsiveFontSize(12);
      case FavoriteButtonSize.medium:
        return context.responsiveFontSize(16);
      case FavoriteButtonSize.large:
        return context.responsiveFontSize(20);
    }
  }

  double _getPadding() {
    switch (size) {
      case FavoriteButtonSize.small:
        return 4;
      case FavoriteButtonSize.medium:
        return 6;
      case FavoriteButtonSize.large:
        return 8;
    }
  }

  Color _getIconColor() {
    if (isFavorite) {
      return activeColor ?? AppColors.errorFields;
    }
    return inactiveColor ?? AppColors.iconforeground;
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = _getSize(context);
    final paddingValue = _getPadding();  // ✅ تصحيح
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(paddingValue),  // ✅ استخدام paddingValue
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: Colors.black.withOpacity(0.12),
                  width: 0.8,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: SvgPicture.asset(
          isFavorite ? AppAssets.heartFilled : AppAssets.heart,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(
            _getIconColor(),
            BlendMode.srcIn,
          ),
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _getIconColor(),
              size: iconSize,
            );
          },
        ),
      ),
    );
  }
}