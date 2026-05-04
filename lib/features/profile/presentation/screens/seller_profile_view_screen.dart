import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/network/firebase_collections.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/utils/bottom_sheet_helper.dart';
import 'package:locaydo_app/core/utils/helpers.dart';
import 'package:locaydo_app/core/utils/image_picker_helper.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/shared/widgets/common/button.dart';
import 'package:locaydo_app/shared/widgets/common/smart_avatar.dart';
import 'package:locaydo_app/shared/widgets/form/input.dart';
import 'package:locaydo_app/shared/widgets/form/phone_input.dart';
import 'seller_profile_setup_screen.dart';

class SellerProfileViewScreen extends StatefulWidget {
  const SellerProfileViewScreen({super.key});

  @override
  State<SellerProfileViewScreen> createState() =>
      _SellerProfileViewScreenState();
}

class _SellerProfileViewScreenState extends State<SellerProfileViewScreen> {
  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocus       = FocusNode();
  final _phoneFocus      = FocusNode();

  String?     _profileImagePath;
  bool        _hasProfileImage = false;
  CountryCode _selectedCode    = CountryCode.palestine;

  bool    _isLoading = true;
  String? _loadError;
  String? _sellerId;

  String? _nameError;
  String? _phoneError;
  final _logger = DebugLogger();   

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSellerData() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, AppRoutes.login, (_) => false);
        }
        return;
      }

      final q = await FirebaseFirestore.instance
          .collection(FirebaseCollections.sellers)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final d = q.docs.first.data();
        _sellerId             = q.docs.first.id;
        _nameController.text  = d['name']      as String? ?? '';
        _phoneController.text = d['phone']     as String? ?? '';
        _profileImagePath     = d['avatarUrl'] as String?;
        _hasProfileImage      =
            _profileImagePath != null && _profileImagePath!.isNotEmpty;

        final cc = d['countryCode'] as String?;
        if (cc != null) {
          _selectedCode = CountryCode.values.firstWhere(
            (c) => c.code == cc,
            orElse: () => CountryCode.palestine,
          );
        }
        setState(() => _isLoading = false);
      } else {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const SellerProfileSetupScreen()),
          );
        }
      }
    } on FirebaseException catch (e) {
      setState(() {
        _loadError = e.code == 'permission-denied'
            ? 'ليس لديك صلاحية للوصول إلى هذه البيانات'
            : e.code == 'unavailable'
                ? 'تأكد من اتصالك بالإنترنت'
                : 'حدث خطأ: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'حدث خطأ: $e';
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تأكيد الحذف',
              style: AppTextStyles.displayMedium(context),
              textAlign: TextAlign.center),
          content: Text(
              'هل أنت متأكد من حذف ملف البيع؟\nسيتم حذف جميع المنتجات المرتبطة بك.',
              style: AppTextStyles.bodyLarge(context),
              textAlign: TextAlign.center),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: AppColors.stroke)),
                    ),
                    child: Text('إلغاء',
                        style: AppTextStyles.bodyLarge(context)
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteSellerProfile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorFields,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('تأكيد',
                        style: AppTextStyles.bodyLarge(context)
                            .copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSellerProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('لا يوجد مستخدم');

      // ✅ استخدام sellerId الصحيح للبحث عن المنتجات
      if (_sellerId == null || _sellerId!.isEmpty) {
        throw Exception('لا يوجد معرف بائع للحذف');
      }

      _logger.log('🗑️ Deleting products for sellerId: $_sellerId');

      // ✅ 1. البحث عن المنتجات باستخدام sellerId (وليس user.uid)
      final products = await FirebaseFirestore.instance
          .collection(FirebaseCollections.products)
          .where('sellerId', isEqualTo: _sellerId)  // ✅ استخدام sellerId
          .get();
      
      _logger.log('📦 Found ${products.docs.length} products to delete');

      // ✅ 2. حذف المنتجات من مفضلات المستخدمين الآخرين أولاً
      for (final productDoc in products.docs) {
        final productId = productDoc.id;
        
        // البحث عن جميع المستخدمين الذين أضافوا هذا المنتج إلى مفضلاتهم
        final allUsers = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .get();
        
        for (final userDoc in allUsers.docs) {
          try {
            await FirebaseFirestore.instance
                .collection(FirebaseCollections.users)
                .doc(userDoc.id)
                .collection('favoriteProducts')
                .doc(productId)
                .delete();
          } catch (_) {
            // المنتج غير موجود في مفضلة هذا المستخدم
          }
        }
        
        // ✅ 3. حذف المنتج نفسه
        await productDoc.reference.delete();
        _logger.log('✅ Product deleted: ${productDoc.data()['title']}');
      }

      // ✅ 4. حذف وثيقة البائع
      if (_sellerId != null && _sellerId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(FirebaseCollections.sellers)
            .doc(_sellerId)
            .delete();
        _logger.log('✅ Seller document deleted: $_sellerId');
      }

      // ✅ 5. إزالة sellerId من وثيقة المستخدم
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .update({
        'sellerId': FieldValue.delete(),
        'hasCompletedSellerProfile': false,
      });
      _logger.log('✅ Seller ID removed from user document');

      if (!mounted) return;
      Helpers.showSnackBar(context, 'تم حذف ملف البائع وجميع المنتجات بنجاح');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _logger.error('❌ Failed to delete seller profile', e);
        Helpers.showSnackBar(context, 'حدث خطأ: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentWidth    = context.contentWidth;
    final verticalSpacing = context.screenHeight * 0.02;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('بياناتي كبائع',
              style: AppTextStyles.displaySmall(context)
                  .copyWith(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (!_isLoading && _sellerId != null && _loadError == null)
              TextButton(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                      context, AppRoutes.sellerProfileEdit);
                  if (result == true) _loadSellerData();
                },
                child: Text('تعديل',
                    style: AppTextStyles.bodyLarge(context).copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        body: SafeArea(
          child: Builder(
            builder: (_) {
              if (_isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryDark),
                );
              }
              if (_loadError != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 80, color: AppColors.errorFields),
                        const SizedBox(height: 24),
                        Text(_loadError!,
                            style: AppTextStyles.bodyLarge(context)
                                .copyWith(color: AppColors.errorFields),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 32),
                        Button(
                          text:        'إعادة المحاولة',
                          onPressed:   _loadSellerData,
                          variant:     ButtonVariant.outline,
                          size:        ButtonSize.medium,
                          isFullWidth: false,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Container(
                    width:   contentWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: SmartAvatar(
                            initialImagePath: _profileImagePath,
                            initialHasImage:  _hasProfileImage,
                            showEditButton:   false,
                            onImageChanged:   (path) => setState(() {
                              _profileImagePath = path;
                              _hasProfileImage  = path != null;
                            }),
                            size: 140,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Input(
                          label:           AppStrings.sellerFullNameLabel,
                          controller:      _nameController,
                          focusNode:       _nameFocus,
                          errorText:       _nameError,
                          prefixIcon:      Icons.person_outline_rounded,
                          hintText:        AppStrings.sellerFullNameHint,
                          textInputAction: TextInputAction.next,
                          onSubmitted:     (_) => _phoneFocus.requestFocus(),
                          enabled:         false,
                        ),
                        SizedBox(height: verticalSpacing),
                        PhoneInput(
                          label:           AppStrings.sellerPhoneLabel,
                          controller:      _phoneController,
                          focusNode:       _phoneFocus,
                          errorText:       _phoneError,
                          hintText:        AppStrings.sellerPhoneHint,
                          selectedCode:    _selectedCode,
                          onCodeChanged:   (c) => setState(() => _selectedCode = c),
                          onChanged:       (_) => setState(() => _phoneError = null),
                          onSubmitted:     () => _phoneFocus.unfocus(),
                          textInputAction: TextInputAction.done,
                          enabled:         false,
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: _showDeleteConfirmation,
                          child: Text('حذف ملفي كبائع',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                  color: AppColors.errorFields,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}