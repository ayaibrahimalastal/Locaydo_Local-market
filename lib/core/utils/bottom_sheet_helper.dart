// lib/core/utils/bottom_sheet_helper.dart

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/shared/models/bottom_sheet_option.dart';

class BottomSheetHelper {
  static void showImagePickerOptions({
    required BuildContext context,
    required VoidCallback onGalleryTap,
    required VoidCallback onCameraTap,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary1),
              title: Text('اختر من المعرض', style: AppTextStyles.bodyLarge(ctx)),
              onTap: () { Navigator.pop(ctx); onGalleryTap(); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary1),
              title: Text('التقاط صورة', style: AppTextStyles.bodyLarge(ctx)),
              onTap: () { Navigator.pop(ctx); onCameraTap(); },
            ),
          ],
        ),
      ),
    );
  }

  static void showOptions({
    required BuildContext context,
    required List<BottomSheetOption> options,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => ListTile(
            leading: Icon(opt.icon, color: opt.iconColor ?? AppColors.primary1),
            title: Text(opt.title, style: AppTextStyles.bodyLarge(ctx)),
            onTap: () { Navigator.pop(ctx); opt.onTap(); },
          )).toList(),
        ),
      ),
    );
  }
}