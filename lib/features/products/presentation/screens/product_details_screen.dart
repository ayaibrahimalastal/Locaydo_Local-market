import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/network/firebase_collections.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/shared/widgets/common/favorite_bottom_sheet.dart';
import 'package:locaydo_app/shared/widgets/navigation/main_navigation_screen.dart';
import 'package:locaydo_app/shared/widgets/product/share_product_overlay.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailsScreen extends StatefulWidget {
  final dynamic product;
  final String? productId;
  final Function? onFavoriteToggle;

  const ProductDetailsScreen({
    super.key,
    this.product,
    this.productId,
    this.onFavoriteToggle,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final PageController _pageCtrl;
  int _currentImageIndex = 0;

  // ✅ حالة تحميل المنتج
  bool _isLoadingProduct = false;
  ProductModel? _loadedProduct;
  String? _loadError;

  static const double _imageHeight = 350;
  final _logger = DebugLogger();

  // Seller data
  String _sellerName = '';
  double _sellerRating = 0.0;
  String _sellerImage = '';
  String _phone = '';
  String _whatsapp = '';
  String _sellerDocId = '';
  String _countryCode = '+970';
  bool _loadingSeller = true;
  String? _sellerError;

  static const List<String> _buyingTips = [
    'اصطحاب شخص معك عند الشراء',
    'تحقق من حالة المنتج جيداً قبل الدفع',
  ];

  ProductModel get _product {
    if (widget.product is ProductModel) return widget.product as ProductModel;
    if (_loadedProduct != null) return _loadedProduct!;
    throw Exception('Product not loaded');
  }

  List<String> get _images {
    if (_isLoadingProduct) return [];
    final list = <String>[];
    if (_product.imageUrl.isNotEmpty) list.add(_product.imageUrl);
    list.addAll(_product.additionalImages);
    if (list.isEmpty) list.add('assets/images/placeholder.png');
    return list;
  }

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _initializeProduct();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeProduct() async {
    // ✅ إذا كان المنتج موجود بالفعل (تم تمريره ككائن)
    if (widget.product is ProductModel) {
      _loadedProduct = widget.product as ProductModel;
      await _loadSeller();
      setState(() {});
      return;
    }

    // ✅ إذا تم تمرير productId فقط (من الـ Deeplink)
    if (widget.productId != null) {
      await _loadProductById(widget.productId!);
      return;
    }

    // ✅ إذا تم تمرير product كـ String
    if (widget.product is String) {
      await _loadProductById(widget.product as String);
      return;
    }

    // ✅ إذا لم يتم العثور على المنتج
    setState(() {
      _loadError = 'المنتج غير موجود';
      _isLoadingProduct = false;
    });
  }

  Future<void> _loadProductById(String productId) async {
    setState(() {
      _isLoadingProduct = true;
      _loadError = null;
    });

    try {
      _logger.log('🔍 Loading product by ID: $productId');

      // ✅ جلب المنتج من Firestore
      final productDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.products)
          .doc(productId)
          .get();

      if (productDoc.exists && mounted) {
        // ✅ استخدام fromDocument (الطريقة الصحيحة)
        _loadedProduct = ProductModel.fromDocument(productDoc);
        _logger.log('✅ Product loaded: ${_loadedProduct!.title}');

        await _loadSeller();
        setState(() {
          _isLoadingProduct = false;
        });
      } else {
        _logger.log('⚠️ Product not found: $productId');
        setState(() {
          _isLoadingProduct = false;
          _loadError = 'المنتج غير موجود';
        });
      }
    } catch (e) {
      _logger.error('❌ Error loading product: $e');
      setState(() {
        _isLoadingProduct = false;
        _loadError = 'حدث خطأ أثناء تحميل المنتج';
      });
    }
  }

  Future<void> _loadSeller() async {
    if (_product.sellerId.isEmpty) {
      _logger.log('⚠️ Product has no sellerId');
      setState(() {
        _loadingSeller = false;
        _sellerError = 'لا توجد معلومات للبائع';
      });
      return;
    }

    try {
      _logger.log('🔍 Loading seller with ID: ${_product.sellerId}');

      final sellerDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.sellers)
          .doc(_product.sellerId)
          .get();

      if (sellerDoc.exists && mounted) {
        final d = sellerDoc.data()!;
        setState(() {
          _sellerDocId = sellerDoc.id;
          _sellerName = d['name'] as String? ?? 'بائع';
          _sellerRating = (d['rating'] as num? ?? 0).toDouble();
          _sellerImage = d['avatarUrl'] as String? ?? '';
          _phone = d['phone'] as String? ?? '';
          _whatsapp = d['whatsapp'] as String? ?? d['phone'] as String? ?? '';
          _countryCode = d['countryCode'] as String? ?? '+970';
          _loadingSeller = false;
        });
        _logger.log('✅ Seller found by doc ID: $_sellerName');
        return;
      }

      // ✅ إذا لم يتم العثور، جرب البحث باستخدام userId
      _logger.log('⚠️ Seller not found by ID, trying by userId...');
      final q = await FirebaseFirestore.instance
          .collection(FirebaseCollections.sellers)
          .where('userId', isEqualTo: _product.sellerId)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty && mounted) {
        final d = q.docs.first.data();
        setState(() {
          _sellerDocId = q.docs.first.id;
          _sellerName = d['name'] as String? ?? 'بائع';
          _sellerRating = (d['rating'] as num? ?? 0).toDouble();
          _sellerImage = d['avatarUrl'] as String? ?? '';
          _phone = d['phone'] as String? ?? '';
          _whatsapp = d['whatsapp'] as String? ?? d['phone'] as String? ?? '';
          _countryCode = d['countryCode'] as String? ?? '+970';
          _loadingSeller = false;
        });
        _logger.log('✅ Seller found by userId: $_sellerName');
      } else if (mounted) {
        _logger.log('⚠️ No seller found, using stored sellerName: ${_product.sellerName}');
        setState(() {
          _sellerName = _product.sellerName.isNotEmpty ? _product.sellerName : 'بائع';
          _loadingSeller = false;
          _sellerError = 'لا يمكن تحميل بيانات البائع الكاملة';
        });
      }
    } catch (e) {
      _logger.error('❌ Error loading seller: $e');
      if (mounted) {
        setState(() {
          _loadingSeller = false;
          _sellerError = 'حدث خطأ أثناء تحميل بيانات البائع';
          _sellerName = _product.sellerName.isNotEmpty ? _product.sellerName : 'بائع';
        });
      }
    }
  }

  // ✅ دالة لعرض محتوى مؤقت أثناء التحميل
  Widget _buildLoadingContent() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primaryDark,
            ),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل المنتج...',
              style: AppTextStyles.bodyLarge(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ دالة لعرض صفحة المنتج غير موجود
  Widget _buildNotFoundContent() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: _handleBack,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _loadError ?? 'المنتج غير موجود',
                style: AppTextStyles.displayMedium(context).copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'قد يكون المنتج قد تم حذفه أو انتهت صلاحيته',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textPlaceholder,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('العودة إلى الرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────
  void _goToSeller() {
    if (_sellerDocId.isNotEmpty) {
      _logger.log('🔍 Navigating to seller profile: $_sellerDocId');
      Navigator.pushNamed(context, AppRoutes.sellerView, arguments: _sellerDocId);
    }
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 0)),
        (route) => false,
      );
    }
  }

  // ── Contact ───────────────────────────────────────────
  Future<void> _call() async {
    if (_phone.isEmpty) {
      _snackBar('لا يوجد رقم هاتف للبائع');
      return;
    }
    final clean = _cleanPhone(_phone);
    final uri = Uri(scheme: 'tel', path: '$_countryCode$clean');
    _logger.log('📞 Calling: $_countryCode$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _snackBar('جهازك لا يدعم إجراء المكالمات');
    }
  }

  Future<void> _whatsappContact() async {
    if (_whatsapp.isEmpty) {
      _snackBar('لا يوجد رقم واتساب للبائع');
      return;
    }
    final clean = _cleanPhone(_whatsapp);
    final uri = Uri.parse('https://wa.me/$_countryCode$clean');
    _logger.log('💬 Opening WhatsApp: $_countryCode$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _snackBar('تطبيق واتساب غير مثبت على جهازك');
    }
  }

  String _cleanPhone(String raw) {
    var s = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (s.startsWith('0')) s = s.substring(1);
    return s;
  }

  void _snackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.errorSnackBar,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _toggleFavorite(HomeViewModel vm) async {
    await FavoriteBottomSheet.show(
      context,
      productTitle: _product.title,
      isAdding: !vm.isProductFavoriteSync(_product.id),
      onToggle: () => vm.toggleFavorite(_product.id),
      onComplete: () {},
    );
  }

  // ── Image builder ─────────────────────────────────────
  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryDark),
        ),
        errorWidget: (_, __, ___) => _errorImage(),
      );
    }
    if (path.startsWith('/')) {
      return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _errorImage());
    }
    return Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _errorImage());
  }

  Widget _errorImage() => Container(
        color: AppColors.primaryDark.withValues(alpha: 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 80, color: AppColors.primaryDark.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text('خطأ في تحميل الصورة',
                style: TextStyle(color: AppColors.primaryDark.withValues(alpha: 0.3))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    // ✅ عرض مؤشر التحميل إذا كان المنتج قيد التحميل
    if (_isLoadingProduct) {
      return _buildLoadingContent();
    }

    // ✅ عرض خطأ إذا لم يتم العثور على المنتج
    if (_loadError != null || _loadedProduct == null) {
      return _buildNotFoundContent();
    }

    final contentWidth = FigmaDesignSystem.getResponsiveWidth(context);
    final images = _images;
    final product = _product;

    // حساب الحد الأدنى لارتفاع البطاقة البيضاء
    final screenHeight = MediaQuery.of(context).size.height;
    final minCardHeight = screenHeight - _imageHeight;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<HomeViewModel>(
          builder: (context, vm, _) {
            final isFav = vm.isProductFavoriteSync(product.id);
            return Stack(
              children: [
                CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    // ✅ منطقة الصور
                    SliverAppBar(
                      expandedHeight: _imageHeight,
                      pinned: false,
                      floating: false,
                      stretch: false,
                      backgroundColor: Colors.white,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          children: [
                            PageView.builder(
                              controller: _pageCtrl,
                              onPageChanged: (i) => setState(() => _currentImageIndex = i),
                              itemCount: images.length,
                              itemBuilder: (_, i) => _buildImage(images[i]),
                            ),
                            // مؤشر الصفحات
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  images.length,
                                  (i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: i == _currentImageIndex ? 16 : 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: i == _currentImageIndex
                                          ? AppColors.primaryDark
                                          : Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ✅ محتوى المنتج
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          width: contentWidth,
                          constraints: BoxConstraints(minHeight: minCardHeight),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(product.category.label,
                                  style: AppTextStyles.bodyMedium(context)
                                      .copyWith(color: AppColors.primaryDark)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(product.title,
                                        style: AppTextStyles.displayMedium(context)
                                            .copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ),
                                  Text('${product.price} ₪',
                                      style: AppTextStyles.displayLarge(context)
                                          .copyWith(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text('الوصف',
                                  style: AppTextStyles.bodyLarge(context).copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(product.description,
                                  style: AppTextStyles.bodyMedium(context)
                                      .copyWith(color: const Color(0xFF555555), height: 1.6)),
                              const SizedBox(height: 24),
                              _specRow(context,
                                  icon: AppAssets.productPlacement,
                                  label: 'وضع المنتج',
                                  value: product.condition.label,
                                  valueColor: Colors.green),
                              const Divider(height: 1, color: Color(0xFFEEEEEE)),
                              _paymentRow(context, product),
                              const Divider(height: 1, color: Color(0xFFEEEEEE)),
                              _specRow(context,
                                  icon: AppAssets.location, label: 'الموقع', value: product.location),
                              const SizedBox(height: 24),
                              Text('نصائح أثناء الشراء',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              ..._buyingTips.asMap().entries.map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${e.key + 1}. ',
                                              style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
                                          Expanded(
                                            child: Text(e.value,
                                                style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              _sellerSection(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // أزرار التحكم العلوية
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: _TopButton(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                      onPressed: _handleBack,
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: Row(
                    children: [
                      _TopButton(
                        child: IconButton(
                          icon: isFav
                              ? SvgPicture.asset(AppAssets.heartFilled, width: 20)
                              : SvgPicture.asset(AppAssets.heart, width: 20,
                                  colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn)),
                          onPressed: () => _toggleFavorite(vm),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _TopButton(
                        child: IconButton(
                          icon: SvgPicture.asset(AppAssets.share, width: 20,
                              colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn)),
                          onPressed: () => ShareProductOverlay.show(context: context, product: product),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sellerSection() {
    if (_loadingSeller) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: _goToSeller,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            ClipOval(
              child: _sellerImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _sellerImage,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _avatarPlaceholder(),
                      errorWidget: (_, __, ___) => _avatarPlaceholder(),
                    )
                  : _avatarPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_sellerName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(_sellerRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _ContactBtn(
                    icon: AppAssets.phone,
                   // color: const Color(0xFF1E88E5),
                    onTap: _call,
                    enabled: _phone.isNotEmpty),
                const SizedBox(width: 12),
                _ContactBtn(
                    icon: AppAssets.whatsApp,
                  //  color: const Color(0xFF25D366),
                    onTap: _whatsappContact,
                    enabled: _whatsapp.isNotEmpty),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() => Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryDark.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: SvgPicture.asset(
            AppAssets.personOutline,
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(AppColors.primaryDark, BlendMode.srcIn),
          ),
        ),
      );

  Widget _specRow(BuildContext context,
      {required String icon, required String label, required String value, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SvgPicture.asset(icon,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary)),
          ),
          Text(value,
              style: AppTextStyles.bodyMedium(context)
                  .copyWith(fontWeight: FontWeight.w500, color: valueColor)),
        ],
      ),
    );
  }

  Widget _paymentRow(BuildContext context, ProductModel product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SvgPicture.asset(AppAssets.paymentMethods,
              width: 20,
              colorFilter: const ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn)),
          const SizedBox(width: 12),
          Expanded(
            child: Text('طرق الدفع المتاحة',
                style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textSecondary)),
          ),
          Row(
            children: product.paymentMethods.map((m) {
              final isCash = m == PaymentMethod.cash;
              return Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCash
                      ? AppColors.primaryDark.withValues(alpha: 0.1)
                      : const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  isCash ? 'كاش' : 'بنكي',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: isCash ? AppColors.primaryDark : const Color(0xFFC2185B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  final Widget child;
  const _TopButton({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
}

class _ContactBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  final bool enabled;

  const _ContactBtn({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(icon,
                width: 22,
                height: 22,
               ),
          ),
        ),
      );
}