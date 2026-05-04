// lib/features/profile/presentation/screens/seller_profile_edit_screen.dart
// ✅ لا تعدّل التصميم — مأخوذ من Figma

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';
import 'package:locaydo_app/core/utils/cloudinary_uploader.dart';
import 'package:locaydo_app/core/utils/helpers.dart';
import 'package:locaydo_app/core/utils/image_picker_helper.dart';
import 'package:locaydo_app/core/utils/bottom_sheet_helper.dart';
import 'package:locaydo_app/core/utils/validators.dart';
import 'package:locaydo_app/shared/widgets/common/smart_avatar.dart';
import 'package:locaydo_app/shared/widgets/form/input.dart';
import 'package:locaydo_app/shared/widgets/form/phone_input.dart';

class SellerProfileEditScreen extends StatefulWidget {
  const SellerProfileEditScreen({super.key});

  @override
  State<SellerProfileEditScreen> createState() =>
      _SellerProfileEditScreenState();
}

class _SellerProfileEditScreenState extends State<SellerProfileEditScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  String? _profileImagePath;
  bool _hasProfileImage = false;
  CountryCode _selectedCode = CountryCode.palestine;
  String? _sellerId;

  String? _nameError;
  String? _phoneError;
  String? _imageError;
  
  bool _isLoading = true;
  String? _loadError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _loadError = 'الرجاء تسجيل الدخول أولاً';
          _isLoading = false;
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      _sellerId = userDoc.data()?['sellerId'];
      
      if (_sellerId == null || _sellerId!.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(_sellerId)
          .get();

      if (sellerDoc.exists) {
        final data = sellerDoc.data()!;
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _profileImagePath = data['avatarUrl'];
        _hasProfileImage = _profileImagePath != null && _profileImagePath!.isNotEmpty;

        final countryCode = data['countryCode'];
        if (countryCode != null) {
          _selectedCode = CountryCode.values.firstWhere(
            (c) => c.code == countryCode,
            orElse: () => CountryCode.palestine,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading seller data: $e');
      setState(() {
        _loadError = 'حدث خطأ أثناء تحميل البيانات';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    BottomSheetHelper.showImagePickerOptions(
      context: context,
      onGalleryTap: () async {
        final path = await ImagePickerHelper.pickFromGallery();
        if (path != null && mounted) {
          setState(() {
            _profileImagePath = path;
            _hasProfileImage = true;
            _imageError = null;
          });
          Helpers.showSnackBar(context, 'تم اختيار الصورة بنجاح');
        }
      },
      onCameraTap: () async {
        final path = await ImagePickerHelper.takePhoto();
        if (path != null && mounted) {
          setState(() {
            _profileImagePath = path;
            _hasProfileImage = true;
            _imageError = null;
          });
          Helpers.showSnackBar(context, 'تم التقاط الصورة بنجاح');
        }
      },
    );
  }

  Future<String?> _uploadImageToCloudinary(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('❌ File does not exist');
        return null;
      }
      return await CloudinaryUploader.uploadImage(file);
    } catch (e) {
      debugPrint('❌ Cloudinary error: $e');
      return null;
    }
  }

  bool _validateForm() {
    setState(() {
      _nameError = AppValidators.validateSellerName(_nameController.text);
      _phoneError = AppValidators.validateSellerPhone(_phoneController.text);
    });
    return _nameError == null && _phoneError == null;
  }

  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();
    if (!_validateForm()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('لا يوجد مستخدم');

      String? uploadedImageUrl;
      bool imageChanged = false; // ✅ تتبع إذا تغيرت الصورة

      if (_hasProfileImage && _profileImagePath != null) {
        if (_profileImagePath!.startsWith('http')) {
          uploadedImageUrl = _profileImagePath;
          debugPrint('📸 Using existing URL: $uploadedImageUrl');
        } else {
          debugPrint('📸 Uploading new image to Cloudinary...');
          uploadedImageUrl = await _uploadImageToCloudinary(_profileImagePath!);
          imageChanged = true;
          debugPrint('📸 Upload result: $uploadedImageUrl');
        }
      } else {
        uploadedImageUrl = null;
        imageChanged = true;
        debugPrint('📸 No image (user deleted the image)');
      }

      if (_sellerId != null && _sellerId!.isNotEmpty) {
        final updateData = {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'countryCode': _selectedCode.code,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (uploadedImageUrl != null && uploadedImageUrl.isNotEmpty) {
          updateData['avatarUrl'] = uploadedImageUrl;
        } else {
          updateData['avatarUrl'] = FieldValue.delete();
          debugPrint('📸 Deleting avatarUrl from database');
        }

        // ✅ إذا تغيرت الصورة، قم بزيادة imageVersion
        if (imageChanged) {
          updateData['imageVersion'] = FieldValue.increment(1);
          debugPrint('🖼️ Image changed, incrementing imageVersion');
        }

        await FirebaseFirestore.instance
            .collection('sellers')
            .doc(_sellerId)
            .update(updateData);

        debugPrint('✅ Seller updated successfully');
      }

      if (!mounted) return;

      Helpers.showSnackBar(
        context,
        'تم حفظ التعديلات بنجاح',
        color: AppColors.success,
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'حدث خطأ: ${e.toString()}',
          color: AppColors.errorSnackBar,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildNoSellerView(double contentWidth) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 80,
              color: AppColors.primary1.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'ليس لديك ملف بائع',
              style: AppTextStyles.displaySmall(context)?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'لا يمكن التعديل لأنه ليس لديك ملف بائع بعد',
              style: AppTextStyles.bodyLarge(context)?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(double contentWidth) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.errorFields,
            ),
            const SizedBox(height: 24),
            Text(
              _loadError ?? 'حدث خطأ غير متوقع',
              style: AppTextStyles.bodyLarge(context)?.copyWith(
                color: AppColors.errorFields,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(double contentWidth, double verticalSpacing) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          width: contentWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(
                child: SmartAvatar(
                  initialImagePath: _profileImagePath,
                  initialHasImage: _hasProfileImage,
                  showEditButton: true,
                  onImageChanged: (path) => setState(() {
                    _profileImagePath = path;
                    _hasProfileImage = path != null;
                  }),
                  size: 140,
                ),
              ),
              const SizedBox(height: 24),

              Input(
                label: AppStrings.sellerFullNameLabel,
                controller: _nameController,
                focusNode: _nameFocus,
                errorText: _nameError,
                prefixIcon: Icons.person_outline_rounded,
                hintText: AppStrings.sellerFullNameHint,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _nameError = null),
                onSubmitted: (_) => _phoneFocus.requestFocus(),
              ),
              SizedBox(height: verticalSpacing),

              PhoneInput(
                label: AppStrings.sellerPhoneLabel,
                controller: _phoneController,
                focusNode: _phoneFocus,
                errorText: _phoneError,
                hintText: AppStrings.sellerPhoneHint,
                selectedCode: _selectedCode,
                onCodeChanged: (c) => setState(() => _selectedCode = c),
                onChanged: (_) => setState(() => _phoneError = null),
                onSubmitted: () => _phoneFocus.unfocus(),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentWidth = context.contentWidth;
    final verticalSpacing = context.screenHeight * 0.02;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'تعديل بيانات البائع',
            style: AppTextStyles.displaySmall(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            if (!_isLoading && !_isSaving && _sellerId != null && _loadError == null)
              TextButton(
                onPressed: _onSave,
                child: Text(
                  'حفظ',
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    color: AppColors.primary1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary1,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Builder(
            builder: (context) {
              if (_isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary1,
                  ),
                );
              }
              
              if (_loadError != null) {
                return _buildErrorView(contentWidth);
              }
              
              if (_sellerId == null || _sellerId!.isEmpty) {
                return _buildNoSellerView(contentWidth);
              }
              
              return _buildEditForm(contentWidth, verticalSpacing);
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }
}