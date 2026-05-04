// lib/core/utils/cloudinary_uploader.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class CloudinaryUploader {
  // ✅ Cloud name الخاص بك
  static const String cloudName = "dr1yjqdhb";
  
  // ✅ اسم الـ upload preset
  static const String uploadPreset = "flutter_uploads";
  
  static Future<String?> uploadImage(File imageFile) async {
    try {
      debugPrint('📸 Cloudinary: Uploading file...');
      debugPrint('📸 Cloud name: $cloudName');
      debugPrint('📸 Upload preset: $uploadPreset');
      
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload'
      );
      
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path)
      );
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      debugPrint('📸 Cloudinary response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> result = 
            json.decode(responseData) as Map<String, dynamic>;
        final String imageUrl = result['secure_url'] ?? result['url'];
        debugPrint('✅ Cloudinary upload success: $imageUrl');
        return imageUrl;
      } else {
        debugPrint('❌ Cloudinary upload failed: ${response.statusCode}');
        debugPrint('📸 Response: $responseData');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Cloudinary upload error: $e');
      return null;
    }
  }
}