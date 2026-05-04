// lib/shared/widgets/product/product_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/shared/widgets/common/favorite_button.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onFavoriteTap;
  final VoidCallback? onTap;
  final bool showFavoriteButton;
  final double? customAspectRatio;
  final FavoriteButtonPosition favoritePosition;
  final bool? isFavoriteOverride; // ✅ إضافة معامل لتجاوز حالة المفضلة

  const ProductCard({
    super.key,
    required this.product,
    required this.onFavoriteTap,
    this.onTap,
    this.showFavoriteButton = true,
    this.customAspectRatio,
    this.favoritePosition = FavoriteButtonPosition.topLeft,
    this.isFavoriteOverride, // ✅ معامل اختياري
  });

  bool get _isFavorite => isFavoriteOverride ?? false; // ✅ استخدام override أو false

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          debugPrint('📤 Opening product details: ${product.title}');
          Navigator.pushNamed(
            context,
            AppRoutes.productDetails,
            arguments: product,
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.stroke.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  _buildProductImage(context),
                  if (showFavoriteButton)
                    FavoriteButton(
                      isFavorite: _isFavorite, // ✅ استخدام المتغير الجديد
                      onTap: onFavoriteTap,
                      position: favoritePosition,
                      size: FavoriteButtonSize.medium,
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTitleAndPrice(context),
                    _buildPaymentMethods(context),
                    _buildLocation(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    final hasImage = product.imageUrl.isNotEmpty;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primary1.withOpacity(0.05),
        child: hasImage
            ? _buildImageFromPath()
            : Center(
                child: SvgPicture.asset(
                  AppAssets.vendorCheck,
                  width: context.responsiveFontSize(40),
                  height: context.responsiveFontSize(40),
                  colorFilter: const ColorFilter.mode(
                    AppColors.textPlaceholder,
                    BlendMode.srcIn,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildImageFromPath() {
    final imagePath = product.imageUrl;
    
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary1,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildErrorImage(),
      );
    }
    
    if (imagePath.startsWith('/')) {
      return Image.file(
        File(imagePath),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorImage(),
      );
    }
    
    return Image.asset(
      imagePath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildErrorImage(),
    );
  }

  Widget _buildErrorImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 30,
            color: AppColors.textPlaceholder,
          ),
          const SizedBox(height: 4),
          Text(
            'خطأ في تحميل الصورة',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textPlaceholder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleAndPrice(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            product.title,
            style: AppTextStyles.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: context.responsiveFontSize(12),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${product.price} ${product.currency}',
          style: AppTextStyles.bodyMedium(context).copyWith(
            fontSize: context.responsiveFontSize(12),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods(BuildContext context) {
    return Row(
      children: product.paymentMethods.map<Widget>((method) {
        return Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: method == PaymentMethod.cash
                ? AppColors.primary1.withOpacity(0.1)
                : const Color(0xFFB41A75).withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            method == PaymentMethod.cash ? 'كاش' : 'بنكي',
            style: AppTextStyles.bodySmall(context).copyWith(
              color: method == PaymentMethod.cash
                  ? AppColors.primary1
                  : const Color(0xFFB41A75),
              fontSize: context.responsiveFontSize(10),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocation(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          AppAssets.location,
          width: context.responsiveFontSize(10),
          height: context.responsiveFontSize(10),
          colorFilter: const ColorFilter.mode(
            AppColors.textPlaceholder,
            BlendMode.srcIn,
          ),
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.location_on_rounded,
              color: AppColors.textPlaceholder,
              size: context.responsiveFontSize(10),
            );
          },
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            product.location, // ❌ تمت إزالة ${product.area}
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textPlaceholder,
              fontSize: context.responsiveFontSize(10),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}