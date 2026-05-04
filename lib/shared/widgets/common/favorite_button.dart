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
/// 
/// يستخدم في:
/// - ProductCard
/// - SellerCard
/// - أي مكان يحتاج زر مفضلة
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

  @override
  Widget build(BuildContext context) {
    final iconSize = _getSize(context);
    final padding = _getPadding();
    
    return Positioned(
      top: 6,
      left: position == FavoriteButtonPosition.topLeft ? 6 : null,
      right: position == FavoriteButtonPosition.topRight ? 6 : null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(padding),
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
      ),
    );
  }
}

/// نسخة مبسطة من زر المفضلة (بدون Positioned)
/// تستخدم عندما لا تحتاج Positioning مخصص
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

  Color _getIconColor() {
    if (isFavorite) {
      return activeColor ?? AppColors.errorFields;
    }
    return inactiveColor ?? AppColors.iconforeground;
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = _getSize(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(_getPadding()),
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
}