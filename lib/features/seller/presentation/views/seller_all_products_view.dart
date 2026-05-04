import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/features/products/data/models/seller_product_model.dart';
import 'package:locaydo_app/shared/widgets/common/favorite_button.dart';
import 'package:locaydo_app/shared/widgets/product/product_card.dart';
import 'package:provider/provider.dart';

enum SellerAllProductsType { available, sold }

class SellerAllProductsView extends StatefulWidget {
  final String sellerId;
  final SellerAllProductsType type;

  const SellerAllProductsView({
    super.key,
    required this.sellerId,
    required this.type,
  });

  @override
  State<SellerAllProductsView> createState() => _SellerAllProductsViewState();
}

class _SellerAllProductsViewState extends State<SellerAllProductsView> {
  final _logger = DebugLogger();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // ✅ حفظ مرجع لـ HomeViewModel لإزالة المستمع
  HomeViewModel? _homeViewModel;

  String get _title =>
      widget.type == SellerAllProductsType.available
          ? 'المنتجات المتاحة'
          : 'المنتجات المباعة';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    
    // ✅ الحصول على الـ ViewModel بعد build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _homeViewModel = context.read<HomeViewModel>();
        _homeViewModel?.addListener(_onHomeViewModelChanged);
      }
    });
  }

  @override
  void dispose() {
    // ✅ إزالة المستمع بشكل آمن
    _homeViewModel?.removeListener(_onHomeViewModelChanged);
    super.dispose();
  }

  void _onHomeViewModelChanged() {
    if (mounted) {
      _logger.log('🔄 HomeViewModel changed, refreshing UI...');
      setState(() {});
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productsQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: widget.sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      final allProducts = <ProductModel>[];
      for (var doc in productsQuery.docs) {
        final product = ProductModel.fromDocument(doc);
        allProducts.add(product);
      }

      setState(() {
        _products = widget.type == SellerAllProductsType.available
            ? allProducts.where((p) => p.status == ProductStatus.available).toList()
            : allProducts.where((p) => p.status == ProductStatus.sold).toList();
        _isLoading = false;
      });

      _logger.log('📦 Loaded ${_products.length} products');
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء تحميل المنتجات';
        _isLoading = false;
      });
      _logger.error('❌ Failed to load products', e);
    }
  }

  void _toggleProductFavorite(String productId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('يجب تسجيل الدخول أولاً');
      return;
    }

    final homeViewModel = context.read<HomeViewModel>();
    await homeViewModel.toggleFavorite(productId);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorSnackBar,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Consumer<HomeViewModel>(
      builder: (context, homeViewModel, child) {
        final isFavorite = homeViewModel.isProductFavoriteSync(product.id);
        final isSold = product.status == ProductStatus.sold;

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
            if (isSold)
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
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            _title,
            style: AppTextStyles.displaySmall(context).copyWith(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary1),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.errorFields),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary1,
                foregroundColor: Colors.white,
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.type == SellerAllProductsType.available
                  ? Icons.inventory_2_outlined
                  : Icons.shopping_cart_outlined,
              size: 64,
              color: AppColors.textPlaceholder.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              widget.type == SellerAllProductsType.available
                  ? 'لا توجد منتجات متاحة'
                  : 'لا توجد منتجات مباعة',
              style: AppTextStyles.bodyLarge(context).copyWith(color: AppColors.textPlaceholder),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppColors.primary1,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          return _buildProductCard(_products[index]);
        },
      ),
    );
  }
}