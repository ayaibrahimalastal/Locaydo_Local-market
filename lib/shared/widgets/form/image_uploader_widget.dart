// lib/shared/widgets/form/image_uploader_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';

enum ImageUploaderType {
  profile,
  product,
  document,
}

enum ImageSource {
  asset,
  file,
  network,
}

class ImageUploaderWidget extends StatelessWidget {
  final bool hasImage;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String? label;
  final String? hintText;
  final String? successText;
  final String? errorText;
  final double? height;
  final double? width;
  final ImageUploaderType type;
  final bool showHint;
  final ImageSource imageSource;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? successColor;

  const ImageUploaderWidget({
    super.key,
    required this.hasImage,
    this.imageUrl,
    required this.onTap,
    required this.onDelete,
    this.label,
    this.hintText,
    this.successText,
    this.errorText,
    this.height,
    this.width,
    this.type = ImageUploaderType.product,
    this.showHint = false,
    this.imageSource = ImageSource.file,
    this.backgroundColor,
    this.iconColor,
    this.successColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            child: Text(
              label!,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        _buildUploader(context),
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.error_outline, color: AppColors.errorFields, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorText!,
                  style: AppTextStyles.errorText(context),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
        if (showHint) ...[
          const SizedBox(height: 4),
          _buildHint(context),
        ],
      ],
    );
  }

  Widget _buildUploader(BuildContext context) {
    final double containerHeight = height ?? (type == ImageUploaderType.profile ? 164 : 164);
    final double containerWidth = width ?? double.infinity;

    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: errorText != null ? AppColors.errorFields : AppColors.stroke,
            ),
            child: Container(
              height: containerHeight,
              width: containerWidth,
              decoration: BoxDecoration(
                color: backgroundColor ?? const Color(0xFFFDFCFC),
                borderRadius: _getBorderRadius(),
              ),
              child: Center(
                child: hasImage && imageUrl != null && imageUrl!.isNotEmpty
                    ? _buildImagePreview(context)
                    : _buildUploadPlaceholder(context),
              ),
            ),
          ),
        ),
        if (hasImage)
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  color: AppColors.errorFields,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    // ✅ تحديد حجم الصورة حسب النوع
    final double imageSize = type == ImageUploaderType.profile ? 120 : 120;
    
    Widget imageWidget;
    
    // ✅ معالجة الصورة حسب المصدر
    if (kIsWeb) {
      // ✅ للويب
      imageWidget = Image.network(
        imageUrl!,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorImage(context),
      );
    } else {
      // ✅ للموبايل
      switch (imageSource) {
        case ImageSource.file:
          imageWidget = Image.file(
            File(imageUrl!),
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildErrorImage(context),
          );
          break;
        case ImageSource.network:
          imageWidget = Image.network(
            imageUrl!,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildErrorImage(context),
          );
          break;
        case ImageSource.asset:
        default:
          imageWidget = Image.asset(
            imageUrl!,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildErrorImage(context),
          );
          break;
      }
    }
    
    // ✅ إذا كان نوع الصورة profile، نجعلها دائرية
    if (type == ImageUploaderType.profile) {
      return ClipOval(
        child: imageWidget,
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageWidget,
    );
  }

  Widget _buildErrorImage(BuildContext context) {
    return Container(
      color: AppColors.primary1.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 40,
            color: AppColors.textPlaceholder,
          ),
          const SizedBox(height: 8),
          Text(
            'خطأ في تحميل الصورة',
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          AppAssets.attachPicture,
          width: 40,
          height: 40,
          colorFilter: ColorFilter.mode(
            iconColor ?? AppColors.textSecondary,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hintText ?? (type == ImageUploaderType.profile
              ? 'ارفع صورتك الشخصية'
              : 'ارفق الصور هنا'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: iconColor ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHint(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: AppColors.primaryGradient,
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Container(
        width: double.infinity,
        child: Text(
          'من فضلك أدخل صورة شخصية واضحة',
          textAlign: TextAlign.right,
          style: AppTextStyles.bodySmall(context).copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    switch (type) {
      case ImageUploaderType.profile:
        return BorderRadius.circular(100);
      case ImageUploaderType.product:
        return BorderRadius.circular(12);
      case ImageUploaderType.document:
        return BorderRadius.circular(4);
    }
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;

  const DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const dashWidth = 6.0;
    const dashSpace = 4.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );
    final path = Path()..addRRect(rrect);
    final dashPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}