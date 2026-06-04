// lib/shared/widgets/common/smart_avatar.dart
// ✅ imports مصلحة

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/utils/bottom_sheet_helper.dart';
import 'package:locaydo_app/core/utils/image_picker_helper.dart';
import 'package:locaydo_app/shared/models/bottom_sheet_option.dart';

class SmartAvatar extends StatefulWidget {
  final String?          initialImagePath;
  final bool             initialHasImage;
  final Function(String?) onImageChanged;
  final double           size;
  final bool             showEditButton;
  final String?          errorText;

  const SmartAvatar({
    super.key,
    this.initialImagePath,
    this.initialHasImage = false,
    required this.onImageChanged,
    this.size           = 140,
    this.showEditButton = true,
    this.errorText,
  });

  @override
  State<SmartAvatar> createState() => _SmartAvatarState();
}

class _SmartAvatarState extends State<SmartAvatar> {
  String? _imagePath;
  bool    _hasImage = false;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialImagePath;
    _hasImage  = widget.initialHasImage;
  }

  Future<void> _pickFromGallery() async {
    final path = await ImagePickerHelper.pickFromGallery(
        aspectRatioX: 1.0, aspectRatioY: 1.0);
    if (path != null && mounted) {
      setState(() { _imagePath = path; _hasImage = true; });
      widget.onImageChanged(path);
    }
  }

  Future<void> _takePhoto() async {
    final path = await ImagePickerHelper.takePhoto(
        aspectRatioX: 1.0, aspectRatioY: 1.0);
    if (path != null && mounted) {
      setState(() { _imagePath = path; _hasImage = true; });
      widget.onImageChanged(path);
    }
  }



  void _showOptions() {
    final options = <BottomSheetOption>[
      BottomSheetOption(icon: Icons.photo_library,
          title: AppStrings.chooseFromGallery,
          onTap: _pickFromGallery, iconColor: AppColors.primary1),
      BottomSheetOption(icon: Icons.camera_alt,
          title: AppStrings.takePhoto,
          onTap: _takePhoto, iconColor: AppColors.primary1),
    ];
    BottomSheetHelper.showOptions(context: context, options: options);
  }

  /// ✅ دالة لعرض الصورة (تدعم الرابط والملف المحلي مع caching)
  Widget _buildImage() {
    if (!_hasImage || _imagePath == null) {
      return _placeholder();
    }

    final imagePath = _imagePath!;
    
    // ✅ إذا كان الرابط يبدأ بـ http (Cloudinary) - استخدام CachedNetworkImage
    if (imagePath.startsWith('http')) {
      debugPrint('🖼️ Loading cached network image: $imagePath');
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imagePath,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: CircularProgressIndicator(
              color: AppColors.primary1,
            ),
          ),
          errorWidget: (context, url, error) => _placeholder(),
        ),
      );
    }
    
    // ✅ إذا كان مساراً محلياً (File)
    if (imagePath.startsWith('/') || imagePath.contains('storage')) {
      debugPrint('🖼️ Loading file image: $imagePath');
      return ClipOval(
        child: Image.file(
          File(imagePath),
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    
    // ✅ إذا كان من assets
    debugPrint('🖼️ Loading asset image: $imagePath');
    return ClipOval(
      child: Image.asset(
        imagePath,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.disabledBorder.withOpacity(0.1),
        ),
        child: Center(
          child: SvgPicture.asset(
            AppAssets.personOutline,
            width: widget.size * 0.5,
            height: widget.size * 0.5,
            colorFilter: const ColorFilter.mode(
                AppColors.iconDefault, BlendMode.srcIn),
            errorBuilder: (_, __, ___) => Icon(
                Icons.person,
                size: widget.size * 0.5,
                color: AppColors.iconDefault),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: widget.showEditButton ? _showOptions : null,
              child: Container(
                width: widget.size, height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.errorText != null
                        ? AppColors.errorFields
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: _buildImage(),
              ),
            ),

            if (widget.showEditButton)
              Positioned(
                bottom: 0, left: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: IconButton(
                    icon: SvgPicture.asset(AppAssets.edit,
                        width: 20, height: 20,
                        colorFilter: const ColorFilter.mode(
                            AppColors.iconforeground, BlendMode.srcIn),
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.edit,
                            color: AppColors.iconforeground, size: 20)),
                    onPressed: _showOptions,
                    padding: const EdgeInsets.all(8),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ),
              ),
          ],
        ),
        if (widget.errorText != null && widget.errorText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(widget.errorText!,
                style: AppTextStyles.errorText(context),
                textAlign: TextAlign.center),
          ),
      ],
    );
  }
}