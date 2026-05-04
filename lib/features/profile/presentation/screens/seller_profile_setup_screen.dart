// lib/features/profile/presentation/screens/seller_profile_setup_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/utils/cloudinary_uploader.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';
import 'package:locaydo_app/core/utils/animations.dart';
import 'package:locaydo_app/core/utils/bottom_sheet_helper.dart';
import 'package:locaydo_app/core/utils/helpers.dart';
import 'package:locaydo_app/core/utils/image_picker_helper.dart';
import 'package:locaydo_app/core/utils/validators.dart';
import 'package:locaydo_app/shared/widgets/common/button.dart';
import 'package:locaydo_app/shared/widgets/form/image_uploader_widget.dart';
import 'package:locaydo_app/shared/widgets/form/input.dart';
import 'package:locaydo_app/shared/widgets/form/phone_input.dart';
import 'package:locaydo_app/features/products/presentation/screens/product_form_screen.dart';

class SellerProfileSetupScreen extends StatefulWidget {
  final String? userId;
  final bool fromEdit;
  final String? source;

  const SellerProfileSetupScreen({
    super.key,
    this.userId,
    this.fromEdit = false,
    this.source,
  });

  @override
  State<SellerProfileSetupScreen> createState() =>
      _SellerProfileSetupScreenState();
}

class _SellerProfileSetupScreenState
    extends State<SellerProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  String? _profileImagePath;
  bool _hasProfileImage = false;
  CountryCode _selectedCode = CountryCode.palestine;

  String? _nameError;
  String? _phoneError;
  String? _imageError;

  bool _isLoading = false;
  bool _isNavigating = false; // منع الـ build أثناء التنقل

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AppAnimations.createFadeSlideController(this);
    _fade = AppAnimations.createFadeAnimation(_animCtrl);
    _slide = AppAnimations.createSlideAnimation(_animCtrl);
    _animCtrl.forward();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          _sellerId = data['sellerId'];
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading seller data: $e');
    }
  }

  String? _sellerId;

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

  bool _validateForm() {
    setState(() {
      _nameError = AppValidators.validateSellerName(_nameController.text);
      _phoneError = AppValidators.validateSellerPhone(_phoneController.text);
      _imageError = !_hasProfileImage ? AppStrings.sellerImageRequired : null;
    });
    return _nameError == null && _phoneError == null && _imageError == null;
  }

  Future<String?> _uploadImageToCloudinary(String imagePath) async {
    try {
      debugPrint('📸 Uploading to Cloudinary: $imagePath');
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('❌ File does not exist');
        return null;
      }
      final result = await CloudinaryUploader.uploadImage(file);
      debugPrint('📸 Cloudinary result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Cloudinary error: $e');
      return null;
    }
  }

  void _navigateToNextScreen() {
    if (widget.source == 'add_product') {
      // التنقل إلى شاشة إضافة المنتج
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ProductFormScreen.add(),
        ),
      );
    } else {
      // العودة إلى البروفايل
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('لا يوجد مستخدم');

      String? uploadedImageUrl;

      if (_hasProfileImage && _profileImagePath != null) {
        if (_profileImagePath!.startsWith('http')) {
          uploadedImageUrl = _profileImagePath;
        } else {
          uploadedImageUrl = await _uploadImageToCloudinary(_profileImagePath!);
        }
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        await userRef.set({
          'uid': user.uid,
          'username': user.displayName ?? '',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final updatedUserDoc = await userRef.get();
      final existingSellerId = updatedUserDoc.data()?['sellerId'];

      if (existingSellerId != null && existingSellerId.toString().isNotEmpty) {
        final updateData = {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'countryCode': _selectedCode.code,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        if (uploadedImageUrl != null && uploadedImageUrl.isNotEmpty) {
          updateData['avatarUrl'] = uploadedImageUrl;
        }
        
        await FirebaseFirestore.instance
            .collection('sellers')
            .doc(existingSellerId)
            .update(updateData);
        
      } else {
        final sellerRef = FirebaseFirestore.instance.collection('sellers').doc();
        final sellerData = {
          'userId': user.uid,
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'countryCode': _selectedCode.code,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (uploadedImageUrl != null && uploadedImageUrl.isNotEmpty) {
          sellerData['avatarUrl'] = uploadedImageUrl;
        }

        await sellerRef.set(sellerData);

        await userRef.update({
          'sellerId': sellerRef.id,
          'hasCompletedSellerProfile': true,
        });
      }

      if (!mounted) return;

      // عرض رسالة النجاح
      Helpers.showSnackBar(
        context,
        'تم حفظ بيانات البائع بنجاح',
        color: AppColors.success,
      );

      // ✅ منع إعادة بناء الشاشة
      setState(() {
        _isNavigating = true;
      });

      // ✅ تأخير التنقل حتى يتم إخفاء الشاشة
      await Future.delayed(const Duration(milliseconds: 10));

      if (!mounted) return;

      // ✅ التنقل بعد التأخير
      _navigateToNextScreen();

    } catch (e) {
      debugPrint('❌ ERROR in _onSave: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        Helpers.showSnackBar(
          context,
          'حدث خطأ: ${e.toString()}',
          color: AppColors.errorSnackBar,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ إذا كنا نتنقل، نعرض حاوية شفافة بدلاً من الشاشة
    if (_isNavigating) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary1,
          ),
        ),
      );
    }

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
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(AppStrings.sellerProfileTitle,
              style: AppTextStyles.displaySmall(context)
                  .copyWith(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary1,
                  ),
                )
              : FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Center(
                      child: Container(
                        width: contentWidth,
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const SizedBox(height: 8),
                              Input(
                                label: AppStrings.sellerFullNameLabel,
                                controller: _nameController,
                                focusNode: _nameFocus,
                                errorText: _nameError,
                                prefixIcon: Icons.person_outline_rounded,
                                hintText: AppStrings.sellerFullNameHint,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) =>
                                    setState(() => _nameError = null),
                                onSubmitted: (_) =>
                                    _phoneFocus.requestFocus(),
                              ),
                              SizedBox(height: verticalSpacing),
                              PhoneInput(
                                label: AppStrings.sellerPhoneLabel,
                                controller: _phoneController,
                                focusNode: _phoneFocus,
                                errorText: _phoneError,
                                hintText: AppStrings.sellerPhoneHint,
                                selectedCode: _selectedCode,
                                onCodeChanged: (c) =>
                                    setState(() => _selectedCode = c),
                                onChanged: (_) =>
                                    setState(() => _phoneError = null),
                                onSubmitted: () => _phoneFocus.unfocus(),
                                textInputAction: TextInputAction.done,
                              ),
                              SizedBox(height: verticalSpacing),
                              ImageUploaderWidget(
                                hasImage: _hasProfileImage,
                                imageUrl: _profileImagePath,
                                onTap: _pickImage,
                                onDelete: () => setState(() {
                                  _profileImagePath = null;
                                  _hasProfileImage = false;
                                }),
                                label: AppStrings.sellerImageLabel,
                                hintText: AppStrings.sellerImageHint,
                                successText: AppStrings.sellerImageSuccess,
                                errorText: _imageError,
                                type: ImageUploaderType.profile,
                                showHint: true,
                              ),
                              const SizedBox(height: 32),
                              Button(
                                text: AppStrings.sellerSaveButton,
                                onPressed: _onSave,
                                isLoading: _isLoading,
                                variant: ButtonVariant.primary,
                                size: ButtonSize.medium,
                                isFullWidth: true,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}