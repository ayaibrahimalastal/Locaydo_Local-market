// lib/core/utils/image_picker_helper.dart
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickFromGallery({
    double aspectRatioX = 1.0,
    double aspectRatioY = 1.0,
    double compressQuality = 80.0,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: compressQuality.toInt(),
      );
      if (image != null) return image.path;
      return null;
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }

  static Future<String?> takePhoto({
    double aspectRatioX = 1.0,
    double aspectRatioY = 1.0,
    double compressQuality = 80.0,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: compressQuality.toInt(),
      );
      if (image != null) return image.path;
      return null;
    } catch (e) {
      debugPrint('❌ Error taking photo: $e');
      return null;
    }
  }
}