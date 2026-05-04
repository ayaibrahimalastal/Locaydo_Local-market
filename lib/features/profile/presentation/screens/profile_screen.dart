// lib/features/profile/presentation/screens/profile_screen.dart
// ✅ لا تعدّل التصميم — مأخوذ من Figma

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/network/firebase_collections.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/shared/widgets/form/input.dart';
import 'package:provider/provider.dart';

class CancelledException implements Exception {}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String? _errorMessage;

  String _userName         = '';
  double _userRating       = 0;
  String _avatarUrl        = '';
  bool   _hasSellerProfile = false;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final d        = userDoc.data()!;
        _userName      = d['username'] as String? ?? user.displayName ?? '';
        _userRating    = (d['rating'] as num? ?? 0).toDouble();
        final sellerId = d['sellerId'] as String?;
        final completed = d['hasCompletedSellerProfile'] as bool? ?? false;
        _hasSellerProfile =
            (sellerId != null && sellerId.isNotEmpty) || completed;

        if (_hasSellerProfile && sellerId != null && sellerId.isNotEmpty) {
          final sellerDoc = await FirebaseFirestore.instance
              .collection(FirebaseCollections.sellers)
              .doc(sellerId)
              .get();
          if (sellerDoc.exists) {
            _avatarUrl = sellerDoc.data()?['avatarUrl'] as String? ?? '';
          }
        } else {
          _avatarUrl = d['avatarUrl'] as String? ?? '';
        }
      } else {
        _userName = user.displayName ?? '';
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
    }
  }

  // ── Navigate to seller info ───────────────────────────
  void _navigateToSellerInfo() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryDark),
              const SizedBox(height: 16),
              Text('جاري التحقق من ملف البائع...',
                  style: AppTextStyles.bodyMedium(context)
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { if (mounted) Navigator.pop(context); return; }

      final userDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .get();

      bool    hasSeller = false;
      String? sellerId;
      if (userDoc.exists) {
        final d    = userDoc.data()!;
        sellerId   = d['sellerId'] as String?;
        final comp = d['hasCompletedSellerProfile'] as bool? ?? false;
        hasSeller  = (sellerId != null && sellerId.isNotEmpty) || comp;
      }

      _hasSellerProfile = hasSeller;
      if (hasSeller && sellerId != null && sellerId.isNotEmpty) {
        final sd = await FirebaseFirestore.instance
            .collection(FirebaseCollections.sellers)
            .doc(sellerId)
            .get();
        if (sd.exists) _avatarUrl = sd.data()?['avatarUrl'] as String? ?? '';
      }
      if (mounted) setState(() {});
      if (mounted) Navigator.pop(context); // close loading dialog

      if (hasSeller) {
        final result = await Navigator.pushNamed(
            context, AppRoutes.sellerProfileView);
        if (result == true) _loadUserData();
      } else {
        final result =
            await Navigator.pushNamed(context, AppRoutes.sellerProfile);
        if (result == true) { _hasSellerProfile = true; _loadUserData(); }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('حدث خطأ: $e'),
          
        ));
      }
    }
  }

  // ── Password dialog ───────────────────────────────────
  Future<String?> _showPasswordDialog() async {
    final ctrl  = TextEditingController();
    String? err;
    bool confirming = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, ss) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('تأكيد الهوية',
                style: AppTextStyles.displayMedium(context)
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('لحذف حسابك، يرجى إدخال كلمة المرور الخاصة بك.',
                    style: AppTextStyles.bodyMedium(context)
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Input(
                  hintText:  'كلمة المرور',
                  controller: ctrl,
                  errorText:  err,
                  isSecure:   true,
                  onChanged: (_) {
                    if (err != null) ss(() => err = null);
                  },
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: confirming
                          ? null
                          : () => Navigator.pop(ctx, null),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.stroke)),
                      ),
                      child: Text('إلغاء',
                          style: AppTextStyles.bodyMedium(context)
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: confirming
                          ? null
                          : () async {
                              if (ctrl.text.isEmpty) {
                                ss(() => err = 'كلمة المرور مطلوبة');
                                return;
                              }
                              ss(() => confirming = true);
                              try {
                                final u = FirebaseAuth.instance.currentUser!;
                                await u.reauthenticateWithCredential(
                                    EmailAuthProvider.credential(
                                        email: u.email!, password: ctrl.text));
                                if (ctx.mounted) Navigator.pop(ctx, ctrl.text);
                              } on FirebaseAuthException catch (e) {
                                ss(() {
                                  err = e.code == 'invalid-credential'
                                      ? 'خطأ في كلمة المرور'
                                      : e.message ?? 'حدث خطأ';
                                  confirming = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorFields,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: confirming
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : Text('تأكيد',
                              style: AppTextStyles.bodyMedium(context)
                                  .copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تسجيل الخروج',
              style: AppTextStyles.displayMedium(context)
                  .copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          content: Text('هل أنت متأكد من تسجيل الخروج؟',
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
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.stroke)),
                    ),
                    child: Text('إلغاء',
                        style: AppTextStyles.bodyMedium(context)
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleLogout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('تسجيل الخروج',
                        style: AppTextStyles.bodyMedium(context)
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

  Future<void> _handleLogout() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primaryDark),
                const SizedBox(height: 16),
                Text('جاري تسجيل الخروج...',
                    style: AppTextStyles.bodyMedium(context)
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );

      context.read<HomeViewModel>().clearAllProducts();
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pop(context);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.welcome, (_) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('حدث خطأ: ${e.message}'),
          backgroundColor: AppColors.errorSnackBar,
        ));
      }
    }
  }

  // ── Delete account ────────────────────────────────────
  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('حذف الحساب',
              style: AppTextStyles.displayMedium(context).copyWith(
                  fontWeight: FontWeight.bold, color: AppColors.errorFields),
              textAlign: TextAlign.center),
          content: Text(
              'هل أنت متأكد من حذف حسابك؟\nسيتم حذف جميع بياناتك نهائياً.',
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
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.stroke)),
                    ),
                    child: Text('إلغاء',
                        style: AppTextStyles.bodyMedium(context)
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleDeleteAccount();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorFields,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('حذف',
                        style: AppTextStyles.bodyMedium(context)
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

Future<void> _handleDeleteAccount() async {
  try {
    final pwd = await _showPasswordDialog();
    if (pwd == null || pwd.isEmpty) throw CancelledException();

    _showLoadingDialog();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('لا يوجد مستخدم');

    final userDoc = await FirebaseFirestore.instance
        .collection(FirebaseCollections.users)
        .doc(user.uid)
        .get();
    
    final sellerId = userDoc.data()?['sellerId'] as String?;
    
    // ✅ الحصول على sellerId للاستعلام
    // المنتجات في Firebase مخزنة بـ sellerId (وليس userId)
    final sellerIdForQuery = (sellerId != null && sellerId.isNotEmpty) 
        ? sellerId 
        : user.uid;

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري حذف المنتجات والبيانات...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // ✅ 1. حذف جميع منتجات البائع
    // ✅ البحث باستخدام sellerId (وليس userId)
    final products = await FirebaseFirestore.instance
        .collection(FirebaseCollections.products)
        .where('sellerId', isEqualTo: sellerIdForQuery)  // ✅ استخدام sellerId
        .get();
    
    debugPrint('📝 عدد المنتجات المراد حذفها: ${products.docs.length}');
    
    for (final productDoc in products.docs) {
      final productId = productDoc.id;
      
      // حذف المنتج من مفضلات جميع المستخدمين
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
      
      // حذف المنتج نفسه
      await productDoc.reference.delete();
      debugPrint('✅ تم حذف المنتج: ${productDoc.data()['title']}');
    }

    // ✅ 2. إذا كان هناك منتجات في oldProducts (إذا كنت تستخدم collection منفصل)
    try {
      final oldProducts = await FirebaseFirestore.instance
          .collection(FirebaseCollections.products)
          .where('userId', isEqualTo: sellerIdForQuery)
          .get();
      
      for (final productDoc in oldProducts.docs) {
        final productId = productDoc.id;
        
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
          } catch (_) {}
        }
        
        await productDoc.reference.delete();
        debugPrint('✅ تم حذف المنتج القديم: ${productDoc.data()['title']}');
      }
    } catch (e) {
      debugPrint('⚠️ لا توجد منتجات قديمة: $e');
    }

    // ✅ 3. حذف بيانات البائع إذا كان موجوداً
    if (sellerId != null && sellerId.isNotEmpty) {
      // حذف التقييمات المستلمة
      try {
        final ratings = await FirebaseFirestore.instance
            .collection(FirebaseCollections.sellers)
            .doc(sellerId)
            .collection('receivedRatings')
            .get();
        for (final d in ratings.docs) {
          await d.reference.delete();
        }
      } catch (e) {
        debugPrint('⚠️ لا توجد تقييمات لحذفها: $e');
      }
      
      // حذف وثيقة البائع
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.sellers)
          .doc(sellerId)
          .delete();
      debugPrint('✅ تم حذف ملف البائع');
    }

    // ✅ 4. حذف المجموعات الفرعية للمستخدم
    for (final sub in ['sentRatings', 'favoriteProducts', 'favoriteSellers']) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .doc(user.uid)
            .collection(sub)
            .get();
        for (final d in snap.docs) {
          await d.reference.delete();
        }
        debugPrint('✅ تم حذف مجموعة: $sub');
      } catch (e) {
        debugPrint('⚠️ مجموعة $sub غير موجودة: $e');
      }
    }

    // ✅ 5. إزالة البائع من مفضلات الآخرين
    if (sellerId != null && sellerId.isNotEmpty) {
      try {
        final allUsers = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .get();
        
        for (final userDoc in allUsers.docs) {
          try {
            await FirebaseFirestore.instance
                .collection(FirebaseCollections.users)
                .doc(userDoc.id)
                .collection('favoriteSellers')
                .doc(sellerId)
                .delete();
          } catch (_) {}
        }
        debugPrint('✅ تم إزالة البائع من مفضلات الآخرين');
      } catch (e) {
        debugPrint('⚠️ خطأ في إزالة البائع من المفضلات: $e');
      }
    }

    // ✅ 6. حذف وثيقة المستخدم
    await FirebaseFirestore.instance
        .collection(FirebaseCollections.users)
        .doc(user.uid)
        .delete();
    debugPrint('✅ تم حذف وثيقة المستخدم');

    // ✅ 7. حذف حساب Firebase Authentication
    await user.delete();
    debugPrint('✅ تم حذف حساب Firebase');

    if (mounted) Navigator.pop(context); // إغلاق loading dialog
    
    if (mounted) {
      context.read<HomeViewModel>().clearAllProducts();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حذف الحساب وجميع المنتجات بنجاح'),
          backgroundColor: AppColors.errorSnackBar,
          duration: Duration(seconds: 2),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context, 
          AppRoutes.welcome, 
          (_) => false
        );
      }
    }
  } on CancelledException {
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء عملية حذف الحساب'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } on FirebaseAuthException catch (e) {
    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    if (mounted) {
      String errorMessage;
      if (e.code == 'invalid-credential') {
        errorMessage = 'خطأ في كلمة المرور';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'لأسباب أمنية، يرجى تسجيل الدخول مرة أخرى ثم المحاولة';
      } else {
        errorMessage = e.message ?? 'حدث خطأ';
      }
      
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.errorSnackBar,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    if (mounted) {
      debugPrint('❌ خطأ في حذف الحساب: $e');
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ غير متوقع: $e'),
          backgroundColor: AppColors.errorSnackBar,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryDark),
              const SizedBox(height: 16),
              Text('جاري حذف الحساب...',
                  style: AppTextStyles.bodyMedium(context)
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        body: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: _errorMessage != null
                ? _buildErrorState(context)
                : _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final screenHeight = context.screenHeight;
    return Center(
      child: SizedBox(
        width: context.contentWidth,
        child: Stack(
          children: [
            SizedBox(
              height: screenHeight * 0.35,
              width:  double.infinity,
              child:  CustomPaint(painter: _ProfileHeaderPainter()),
            ),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: context.topPadding),
                  Text('ملفي الشخصي',
                      style: TextStyle(
                        fontFamily:  'Dubai',
                        fontSize:    context.responsiveFontSize(18),
                        fontWeight:  FontWeight.bold,
                        color:       Colors.white,
                      )),
                  const SizedBox(height: 16),
                  _buildAvatar(124.0),
                  const SizedBox(height: 8),
                  Text(
                    _userName.isNotEmpty ? _userName : 'مستخدم',
                    style: TextStyle(
                      fontFamily:  'Dubai',
                      fontSize:    context.responsiveFontSize(18),
                      fontWeight:  FontWeight.w700,
                      color:       AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _MenuSection(
                        onLogout:          _showLogoutConfirmation,
                        onDeleteAccount:   _showDeleteAccountConfirmation,
                        onSellerInfoTap:   _navigateToSellerInfo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(double size) {
    return Container(
      decoration: BoxDecoration(
        shape:  BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
              color:  Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipOval(
        child: _avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: _avatarUrl,
                width:  size, height: size, fit: BoxFit.cover,
                placeholder: (_, __) => _avatarPlaceholder(size),
                errorWidget: (_, __, ___) => _avatarPlaceholder(size),
              )
            : _avatarPlaceholder(size),
      ),
    );
  }

  Widget _avatarPlaceholder(double size) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.backgroundLight.withValues(alpha: 0.5),
        ),
        child: Center(
          child: Text(
            _userName.isNotEmpty
                ? _userName.substring(0, 1).toUpperCase()
                : '?',
            style: TextStyle(
                fontSize:   40,
                fontWeight: FontWeight.bold,
                color:      AppColors.primaryDark),
          ),
        ),
      );

  Widget _buildErrorState(BuildContext context) => SafeArea(
        child: Center(
          child: Container(
            width:   context.contentWidth,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.errorFields, size: 48),
                const SizedBox(height: 16),
                Text(_errorMessage!,
                    style:     AppTextStyles.bodyLarge(context),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _errorMessage = null),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
}

// ── Header Painter ────────────────────────────────────────────────────────────

class _ProfileHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin:  Alignment.topCenter,
        end:    Alignment.bottomCenter,
        colors: [AppColors.primaryDark, AppColors.primaryLight],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 60)
      ..quadraticBezierTo(
          size.width * 0.5, size.height - 100, 0, size.height - 60)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Menu Section ──────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final VoidCallback onSellerInfoTap;

  const _MenuSection({
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onSellerInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuItem(
          title:    'بياناتي الاساسية',
          iconPath: AppAssets.personOutline,
          onTap:    () => Navigator.pushNamed(context, AppRoutes.basicInfo),
        ),
        const _ItemDivider(),
        _MenuItem(
          title:    'بياناتي كبائع',
          iconPath: AppAssets.personSeller,
          onTap:    onSellerInfoTap,
        ),
        const _ItemDivider(),
        _MenuItem(
          title:    'المنتجات المتاحة للبيع',
          iconPath: AppAssets.packageReceive,
          onTap:    () => Navigator.pushNamed(
              context, AppRoutes.sellerAvailableProducts),
        ),
        const _ItemDivider(),
        _MenuItem(
          title:    'المنتجات المُباعة',
          iconPath: AppAssets.packageSent,
          onTap:    () => Navigator.pushNamed(
              context, AppRoutes.sellerSoldProducts),
        ),
        const _ItemDivider(),
        _MenuItem(
          title:       'تسجيل الخروج',
          iconPath:    AppAssets.logout,
          showChevron: false,
          onTap:       onLogout,
        ),
        const _ItemDivider(),
        _MenuItem(
          title:       'حذف الحساب',
          iconPath:    AppAssets.personRemoveOutlined,
          showChevron: false,
          titleColor:  AppColors.errorFields,
          iconColor:   AppColors.errorFields,
          onTap:       onDeleteAccount,
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String     title;
  final String     iconPath;
  final bool       showChevron;
  final Color      titleColor;
  final Color      iconColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.title,
    required this.iconPath,
    required this.onTap,
    this.showChevron = true,
    this.titleColor  = AppColors.textSecondary,
    this.iconColor   = AppColors.iconDefault,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:         onTap,
      borderRadius:  BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            SvgPicture.asset(iconPath,
                width: 20, height: 20,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily:  'Dubai',
                  fontSize:    context.responsiveFontSize(16),
                  fontWeight:  FontWeight.w500,
                  color:       titleColor,
                ),
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right,
                  size: 24, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ItemDivider extends StatelessWidget {
  const _ItemDivider();

  @override
  Widget build(BuildContext _) =>
      Divider(height: 0.2, thickness: 0.2, color: AppColors.stroke);
}
