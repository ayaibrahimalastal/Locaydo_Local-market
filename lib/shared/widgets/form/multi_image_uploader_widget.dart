// lib/shared/widgets/form/multi_image_uploader_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/utils/bottom_sheet_helper.dart';
import 'package:locaydo_app/core/utils/image_picker_helper.dart';

class MultiImageUploaderWidget extends StatelessWidget {
  final List<String> imagePaths;
  final Function(String) onAddImage;
  final Function(int) onRemoveImage;
  final String? errorText;
  final String label;
  final String hintText;
  final int maxImages;

  const MultiImageUploaderWidget({
    super.key,
    required this.imagePaths,
    required this.onAddImage,
    required this.onRemoveImage,
    this.errorText,
    required this.label,
    required this.hintText,
    this.maxImages = 6,
  });

  Future<void> _handleAddImage(BuildContext context) async {
    if (imagePaths.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يمكنك إضافة $maxImages صور كحد أقصى'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    BottomSheetHelper.showImagePickerOptions(
      context: context,
      onGalleryTap: () async {
        final path = await ImagePickerHelper.pickFromGallery();
        if (path != null) {
          onAddImage(path);
        }
      },
      onCameraTap: () async {
        final path = await ImagePickerHelper.takePhoto();
        if (path != null) {
          onAddImage(path);
        }
      },
    );
  }

  /// ✅ دالة مساعدة لتحديد نوع الصورة وعرضها بشكل صحيح
  Widget _buildImageItem(BuildContext context, int index) {
    final imagePath = imagePaths[index];
    final isNetworkImage = imagePath.startsWith('http');
    
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stroke.withOpacity(0.2), width: 1),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isNetworkImage
                ? CachedNetworkImage(
                    imageUrl: imagePath,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.primary1.withOpacity(0.1),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary1,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.primary1.withOpacity(0.1),
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
                            'خطأ في التحميل',
                            style: TextStyle(
                              fontSize: 8,
                              color: AppColors.textPlaceholder,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primary1.withOpacity(0.1),
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
          ),
          // ✅ زر الحذف
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onRemoveImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          // ✅ علامة الصورة الرئيسية (أول صورة)
          if (index == 0)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary1,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 10,
                      color: Colors.white,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'رئيسية',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // ✅ علامة "مستضافة" للصور الموجودة مسبقاً
          if (isNetworkImage && index != 0)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'موجودة',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // ✅ عرض الصور المرفوعة
        if (imagePaths.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imagePaths.length,
              itemBuilder: (ctx, i) => _buildImageItem(context, i),
            ),
          ),
        
        const SizedBox(height: 12),
        
        // ✅ زر إضافة صورة جديدة
        GestureDetector(
          onTap: () => _handleAddImage(context),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null
                    ? AppColors.errorFields
                    : AppColors.stroke.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 25,
                  color: AppColors.textPlaceholder,
                ),
                const SizedBox(width: 8),
                Text(
                  imagePaths.isEmpty ? hintText : 'إضافة صورة أخرى',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                ),
                if (imagePaths.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '(${imagePaths.length}/$maxImages)',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textPlaceholder,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        if (errorText != null)
          Padding(
          padding: const EdgeInsets.only(top: 8), 
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: AppColors.errorFields,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText!,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.errorFields,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}