// (Public seller profile — view from buyer perspective)
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/utils/animations.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/features/products/data/models/seller_product_model.dart';
import 'package:locaydo_app/features/ratings/data/models/rating_model.dart';
import 'package:locaydo_app/features/ratings/data/repositories/rating_repository.dart';
import 'package:locaydo_app/features/seller/presentation/views/seller_all_products_view.dart';
import 'package:locaydo_app/shared/widgets/common/favorite_button.dart';
import 'package:locaydo_app/shared/widgets/product/product_card.dart';
import 'package:locaydo_app/shared/widgets/seller/rating_overlay.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerProfileView extends StatefulWidget {
  final String sellerId;

  const SellerProfileView({super.key, required this.sellerId});

  @override
  State<SellerProfileView> createState() => _SellerProfileViewState();
}

class _SellerProfileViewState extends State<SellerProfileView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  SellerData? _sellerData;
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _errorMessage;
  double? _userRating;
  String? _currentUserId;

  late final Stream<DocumentSnapshot> _sellerStream;
  late final Stream<DocumentSnapshot> _favoriteStream;

  @override
  void initState() {
    super.initState();
    final animation = AppAnimations.createFullAnimation(this);
    _animCtrl = animation.controller;
    _fade = animation.fade;
    _slide = animation.slide;
    _animCtrl.forward();

    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _sellerStream =
        FirebaseFirestore.instance
            .collection('sellers')
            .doc(widget.sellerId)
            .snapshots();
    _setupFavoriteStream();

    _loadSellerData();
    _checkUserRating();
    _checkIfFavorite();
  }

  void _setupFavoriteStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _favoriteStream =
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('favoriteSellers')
              .doc(widget.sellerId)
              .snapshots();

      _favoriteStream.listen((snapshot) {
        if (mounted) {
          setState(() {
            _isFavorite = snapshot.exists;
          });
        }
      });
    }
  }

  Future<void> _loadSellerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sellerDoc =
          await FirebaseFirestore.instance
              .collection('sellers')
              .doc(widget.sellerId)
              .get();

      if (!sellerDoc.exists) {
        throw Exception('البائع غير موجود');
      }

      final sellerData = sellerDoc.data()!;
      final userIdFromSeller = sellerData['userId'];

      final productsQuery =
          await FirebaseFirestore.instance
              .collection('products')
              .where('sellerId', isEqualTo: widget.sellerId)
              .orderBy('createdAt', descending: true)
              .get();

      final availableProducts = <ProductModel>[];
      final soldProducts = <ProductModel>[];

      for (var doc in productsQuery.docs) {
        final product = ProductModel.fromDocument(doc);
        if (product.status == ProductStatus.sold) {
          soldProducts.add(product);
        } else {
          availableProducts.add(product);
        }
      }

      setState(() {
        _sellerData = SellerData(
          id: widget.sellerId,
          name: sellerData['name'] ?? 'بائع',
          rating: (sellerData['rating'] ?? 0).toDouble(),
          totalRatings: sellerData['totalRatings'] ?? 0,
          imageUrl: sellerData['avatarUrl'] ?? '',
          phoneNumber: sellerData['phone'] ?? '',
          whatsappNumber: sellerData['whatsapp'] ?? sellerData['phone'] ?? '',
          availableProducts: availableProducts,
          soldProducts: soldProducts,
          userId: userIdFromSeller ?? '',
          countryCode: sellerData['countryCode'] ?? '+970',
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkUserRating() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final repository = RatingRepository(logger: DebugLogger());
      final rating = await repository.getUserRatingForSeller(widget.sellerId);
      setState(() {
        _userRating = rating;
      });
    } catch (e) {
      debugPrint('❌ Error checking user rating: $e');
    }
  }

  Future<void> _checkIfFavorite() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final favDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('favoriteSellers')
              .doc(widget.sellerId)
              .get();

      setState(() {
        _isFavorite = favDoc.exists;
      });
    } catch (e) {
      debugPrint('❌ Error checking favorite: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('يجب تسجيل الدخول أولاً');
      return;
    }

    try {
      final sellerRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('favoriteSellers')
          .doc(widget.sellerId);

      if (_isFavorite) {
        await sellerRef.delete();
        _showSuccessSnackBar('تمت إزالة البائع من المفضلة');
      } else {
        final sellerDoc =
            await FirebaseFirestore.instance
                .collection('sellers')
                .doc(widget.sellerId)
                .get();

        if (sellerDoc.exists) {
          final data = sellerDoc.data()!;
          await sellerRef.set({
            'sellerId': widget.sellerId,
            'name': data['name'] ?? '',
            'rating': (data['rating'] ?? 0).toDouble(),
            'totalRatings': data['totalRatings'] ?? 0,
            'imageUrl': data['avatarUrl'] ?? '',
            'productCount': _sellerData?.availableProducts.length ?? 0,
            'addedAt': FieldValue.serverTimestamp(),
          });
          _showSuccessSnackBar('تمت إضافة البائع إلى المفضلة');
        } else {
          _showErrorSnackBar('البائع غير موجود');
        }
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ: ${e.toString()}');
    }
  }

  Future<void> _launchPhone() async {
    if (_sellerData?.phoneNumber.isEmpty ?? true) {
      _showErrorSnackBar('رقم الهاتف غير متوفر');
      return;
    }

    String phoneNumber = _sellerData!.phoneNumber;
    String countryCode = _sellerData!.countryCode;
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('0')) cleanNumber = cleanNumber.substring(1);
    String fullNumber = '$countryCode$cleanNumber';

    final Uri phoneUri = Uri(scheme: 'tel', path: fullNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorSnackBar('جهازك لا يدعم إجراء المكالمات');
    }
  }

  Future<void> _launchWhatsApp() async {
    if (_sellerData?.whatsappNumber.isEmpty ?? true) {
      _showErrorSnackBar('رقم الواتساب غير متوفر');
      return;
    }

    String phoneNumber = _sellerData!.whatsappNumber;
    String countryCode = _sellerData!.countryCode;
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('0')) cleanNumber = cleanNumber.substring(1);
    String fullNumber = '$countryCode$cleanNumber';

    final Uri whatsappUri = Uri.parse('https://wa.me/$fullNumber');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('تطبيق واتساب غير مثبت على جهازك');
    }
  }

  void _showRatingOverlay() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid == _sellerData?.userId) {
      _showErrorSnackBar('لا يمكنك تقييم نفسك');
      return;
    }
    if (_userRating != null) {
      _showErrorSnackBar('لقد قمت بتقييم هذا البائع بالفعل');
      return;
    }
    RatingOverlay.show(
      context: context,
      sellerId: _sellerData!.id,
      sellerName: _sellerData!.name,
      onRatingSubmitted: () {
        _loadSellerData();
        _checkUserRating();
        _showSuccessSnackBar('تم إرسال تقييمك بنجاح');
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorSnackBar,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<List<RatingModel>> _getSellerRatings() async {
    try {
      final repository = RatingRepository(logger: DebugLogger());
      return await repository.getSellerRatings(widget.sellerId);
    } catch (e) {
      return [];
    }
  }

  Widget _buildRatingItem(RatingModel rating) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.stroke.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          ClipOval(
            child:
                rating.userAvatar != null && rating.userAvatar!.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: rating.userAvatar!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            width: 40,
                            height: 40,
                            color: AppColors.primary1.withOpacity(0.1),
                          ),
                      errorWidget:
                          (context, url, error) =>
                              _buildRatingAvatarPlaceholder(rating.userName),
                    )
                    : _buildRatingAvatarPlaceholder(rating.userName),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rating.userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return Icon(
                      starValue <= rating.rating.ceil()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 14,
                      color:
                          starValue <= rating.rating.ceil()
                              ? AppColors.warning
                              : AppColors.textPlaceholder,
                    );
                  }),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(rating.createdAt),
            style: TextStyle(fontSize: 11, color: AppColors.textPlaceholder),
          ),
        ],
      ),
    );
  }

  void _showAllRatings(List<RatingModel> ratings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (context, scrollController) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.stroke,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'جميع التقييمات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: ratings.length,
                        itemBuilder:
                            (context, index) =>
                                _buildRatingItem(ratings[index]),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildRatingAvatarPlaceholder(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary1.withOpacity(0.1),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.primary1,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 365)
      return '${(difference.inDays / 365).floor()} سنة';
    if (difference.inDays > 30)
      return '${(difference.inDays / 30).floor()} شهر';
    if (difference.inDays > 0) return '${difference.inDays} يوم';
    if (difference.inHours > 0) return '${difference.inHours} ساعة';
    if (difference.inMinutes > 0) return '${difference.inMinutes} دقيقة';
    return 'الآن';
  }

  Widget _buildRatingsSection() {
    return FutureBuilder<List<RatingModel>>(
      future: _getSellerRatings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary1,
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final ratings = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'تقييمات المستخدمين',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...ratings.take(3).map((rating) => _buildRatingItem(rating)),
            if (ratings.length > 3)
              TextButton(
                onPressed: () => _showAllRatings(ratings),
                child: const Text(
                  'عرض جميع التقييمات',
                  style: TextStyle(color: AppColors.primary1),
                ),
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ✅ دالة بناء بطاقة المنتج مع Consumer لمراقبة التغييرات
  Widget _buildProductCard(ProductModel product, bool isAvailable) {
    return Consumer<HomeViewModel>(
      builder: (context, homeViewModel, child) {
        final isFavorite = homeViewModel.isProductFavoriteSync(product.id);

        return Stack(
          children: [
            ProductCard(
              product: product,
              onFavoriteTap: () => _toggleProductFavorite(product.id),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.productDetails,
                  arguments: product,
                );
              },
              favoritePosition: FavoriteButtonPosition.topLeft,
              isFavoriteOverride: isFavorite,
            ),
            if (!isAvailable)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'مباع',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _toggleProductFavorite(String productId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('يجب تسجيل الدخول أولاً');
      return;
    }
    final homeViewModel = context.read<HomeViewModel>();
    await homeViewModel.toggleFavorite(productId);
    // ✅ لا حاجة لـ setState لأن Consumer سيتعامل مع التحديث
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary1),
        ),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.errorFields,
              ),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSellerData,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }
    if (_sellerData == null) {
      return const Scaffold(body: Center(child: Text('البائع غير موجود')));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'صفحة البائع',
            style: AppTextStyles.displaySmall(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: (_userRating == null) ? _showRatingOverlay : null,
              child: Text(
                _userRating != null ? 'تم التقييم' : 'أضف تقييم',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color:
                      _userRating != null
                          ? AppColors.textSecondary
                          : AppColors.primary1,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: _sellerStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final newRating = (data['rating'] ?? 0).toDouble();
                  final newTotalRatings = data['totalRatings'] ?? 0;
                  final newCountryCode = data['countryCode'] ?? '+970';
                  if (_sellerData != null) {
                    _sellerData = SellerData(
                      id: _sellerData!.id,
                      name: _sellerData!.name,
                      rating: newRating,
                      totalRatings: newTotalRatings,
                      imageUrl: _sellerData!.imageUrl,
                      phoneNumber: _sellerData!.phoneNumber,
                      whatsappNumber: _sellerData!.whatsappNumber,
                      availableProducts: _sellerData!.availableProducts,
                      soldProducts: _sellerData!.soldProducts,
                      userId: _sellerData!.userId,
                      countryCode: newCountryCode,
                    );
                  }
                }
                return _buildSellerInfoBar();
              },
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: SingleChildScrollView(
                    child: Center(
                      child: SizedBox(
                        width: context.contentWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildAvailableProductsSection(),
                            const SizedBox(height: 24),
                            _buildSoldProductsSection(),
                            _buildRatingsSection(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildAvatarMedium(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sellerData!.name,
                  style: AppTextStyles.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.warning, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _sellerData!.rating.toStringAsFixed(1),
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${_sellerData!.totalRatings})',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textPlaceholder,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildMediumContactButton(
                icon: AppAssets.phone,
                color: AppColors.primary1,
                onTap: _launchPhone,
              ),
              const SizedBox(width: 12),
              _buildMediumContactButton(
                icon: AppAssets.whatsApp,
                color: const Color(0xFF25D366),
                onTap: _launchWhatsApp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarMedium() {
    return Stack(
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.stroke, width: 1.5),
          ),
          child: ClipOval(
            child:
                _sellerData!.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: _sellerData!.imageUrl,
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary1.withOpacity(0.1),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary1,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) =>
                              _buildAvatarPlaceholderMedium(),
                    )
                    : _buildAvatarPlaceholderMedium(),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: SimpleFavoriteButton(
              isFavorite: _isFavorite,
              onTap: _toggleFavorite,
              size: FavoriteButtonSize.small,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholderMedium() {
    return Container(
      color: AppColors.primary1.withOpacity(0.1),
      child: SvgPicture.asset(
        AppAssets.personOutline,
        width: 30,
        height: 30,
        colorFilter: const ColorFilter.mode(
          AppColors.iconDefault,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildMediumContactButton({
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            icon,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            errorBuilder:
                (_, __, ___) => Icon(Icons.call, color: color, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableProductsSection() {
    final hasAvailableProducts = _sellerData!.availableProducts.isNotEmpty;
    final products = _sellerData!.availableProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المنتجات المتوفرة لدى البائع',
                style: AppTextStyles.displaySmall(
                  context,
                ).copyWith(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (hasAvailableProducts)
                TextButton(
                   onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => SellerAllProductsView(
                              sellerId: widget.sellerId,
                              type: SellerAllProductsType.available,
                            ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'رؤية الكل',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (hasAvailableProducts)
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  width: 160,
                  margin: EdgeInsets.only(
                    left: index == products.length - 1 ? 0 : 12,
                  ),
                  child: _buildProductCard(product, true),
                );
              },
            ),
          )
        else
          _buildEmptyMessage(
            icon: Icons.inventory_2_outlined,
            message: 'لا توجد منتجات متاحة حالياً',
          ),
      ],
    );
  }

  Widget _buildSoldProductsSection() {
    final hasSoldProducts = _sellerData!.soldProducts.isNotEmpty;
    final products = _sellerData!.soldProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المنتجات المُباعة لدى البائع',
                style: AppTextStyles.displaySmall(
                  context,
                ).copyWith(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (hasSoldProducts)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => SellerAllProductsView(
                              sellerId: widget.sellerId,
                              type: SellerAllProductsType.sold,
                            ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'رؤية الكل',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (hasSoldProducts)
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  width: 160,
                  margin: EdgeInsets.only(
                    left: index == products.length - 1 ? 0 : 12,
                  ),
                  child: _buildProductCard(product, false),
                );
              },
            ),
          )
        else
          _buildEmptyMessage(
            icon: Icons.shopping_cart_outlined,
            message: 'لا توجد منتجات مباعة حتى الآن',
          ),
      ],
    );
  }

  Widget _buildEmptyMessage({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.textPlaceholder.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textPlaceholder, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SellerData {
  final String id;
  final String name;
  final double rating;
  final int totalRatings;
  final String imageUrl;
  final String phoneNumber;
  final String whatsappNumber;
  final List<ProductModel> availableProducts;
  final List<ProductModel> soldProducts;
  final String userId;
  final String countryCode;

  SellerData({
    required this.id,
    required this.name,
    required this.rating,
    required this.totalRatings,
    required this.imageUrl,
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.availableProducts,
    required this.soldProducts,
    required this.userId,
    required this.countryCode,
  });

  factory SellerData.empty() {
    return SellerData(
      id: '',
      name: '',
      rating: 0,
      totalRatings: 0,
      imageUrl: '',
      phoneNumber: '',
      whatsappNumber: '',
      availableProducts: [],
      soldProducts: [],
      userId: '',
      countryCode: '+970',
    );
  }
}