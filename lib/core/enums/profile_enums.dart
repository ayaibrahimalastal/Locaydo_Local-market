// lib/core/enums/profile_enums.dart

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';

enum ProfileMenuItem {
  basicInfo('بياناتك الأساسية', Icons.person_outline_rounded),
  sellerInfo('بياناتك كبائع', Icons.storefront_outlined),
  availableProducts('المنتجات المتاحة للبيع', Icons.shopping_bag_outlined),
  savedProducts('المنتجات المحفوظة', Icons.bookmark_outline_rounded),
  logout('تسجيل الخروج', Icons.logout_rounded),
  deleteAccount('حذف الحساب', Icons.delete_outline_rounded);

  final String title;
  final IconData icon;
  const ProfileMenuItem(this.title, this.icon);

  Color get color {
    switch (this) {
      case ProfileMenuItem.logout:
      case ProfileMenuItem.deleteAccount:
        return AppColors.errorFields;
      default:
        return AppColors.textPrimary;
    }
  }
}