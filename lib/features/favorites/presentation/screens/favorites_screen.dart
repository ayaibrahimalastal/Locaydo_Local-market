import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:locaydo_app/core/enums/favorites_enums.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/utils/animations.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/favorites/data/models/favorites_model.dart';
import 'package:locaydo_app/features/favorites/presentation/viewmodels/favorites_viewmodel.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/features/products/data/models/seller_product_model.dart';
import 'package:locaydo_app/shared/widgets/common/button.dart';
import 'package:locaydo_app/shared/widgets/common/favorite_button.dart';
import 'package:locaydo_app/shared/widgets/product/product_card.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  final _logger = DebugLogger();

  @override
  void initState() {
    super.initState();
    _animCtrl = AppAnimations.createFadeSlideController(this);
    _fade = AppAnimations.createFadeAnimation(_animCtrl);
    _animCtrl.forward();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _logger.log('🔄 App resumed, refreshing favorites...');
      _refreshFavorites();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshFavorites();
      }
    });
  }
  
  Future<void> _refreshFavorites() async {
    final favoritesViewModel = context.read<FavoritesViewModel>();
    final homeViewModel = context.read<HomeViewModel>();
    
    await homeViewModel.syncFavoritesFromFirebase();
    await favoritesViewModel.loadFavoriteProducts();
    await favoritesViewModel.loadFavoriteSellers();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesViewModel>(
      builder: (context, viewModel, _) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            elevation: 0,
            title: Text(
              'المُفضلة',
              style: AppTextStyles.displaySmall(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Center(
              child: SizedBox(
                width: context.contentWidth,
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _refreshFavorites();
                    await viewModel.refreshFavorites();
                  },
                  color: AppColors.primary1,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _TabsRow(
                            activeTab: viewModel.activeTab,
                            onTabChanged: viewModel.setActiveTab,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      if (viewModel.isLoading)
                        const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: CircularProgressIndicator(
                                color: AppColors.primary1,
                              ),
                            ),
                          ),
                        )
                      else if (viewModel.activeTab == FavoritesTab.products)
                        _buildProductsSliver(context, viewModel)
                      else
                        _buildSellersSliver(context, viewModel),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsSliver(BuildContext context, FavoritesViewModel viewModel) {
    final homeViewModel = context.read<HomeViewModel>();
    
    final allFavorites = viewModel.favoriteProducts;
    
    if (allFavorites.isEmpty) {
      return _emptySliver(
        context,
        icon: Icons.favorite_border_rounded,
        title: 'لا توجد منتجات مفضلة',
        subtitle: 'اضغط على أيقونة القلب ❤️ لإضافة منتج إلى المفضلة',
      );
    }
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((ctx, i) {
          final favoriteProduct = allFavorites[i];
          
          final fullProduct = homeViewModel.getProductById(favoriteProduct.id);
          final isSold = fullProduct?.status == ProductStatus.sold;
          final sellerId = fullProduct?.sellerId ?? '';
          final sellerName = fullProduct?.sellerName ?? '';
          
          final product = ProductModel(
            id: favoriteProduct.id,
            title: favoriteProduct.title,
            description: fullProduct?.description ?? '',
            price: favoriteProduct.price,
            currency: favoriteProduct.currency,
            location: favoriteProduct.location,
            imageUrl: favoriteProduct.imageUrl,
            additionalImages: fullProduct?.additionalImages ?? [],
            category: fullProduct?.category ?? ProductCategory.electronics,
            condition: fullProduct?.condition ?? ProductCondition.new_,
            paymentMethods: favoriteProduct.paymentMethods,
            sellerId: sellerId,
            sellerName: sellerName,
            createdAt: fullProduct?.createdAt ?? DateTime.now(),
            status: isSold ? ProductStatus.sold : ProductStatus.available,
          );
          
          return FadeTransition(
            opacity: _fade,
            child: Stack(
              children: [
                ProductCard(
                  product: product,
                  onFavoriteTap: () => viewModel.toggleProductFavoriteFromList(favoriteProduct.id),
                  onTap: () {
                    _logger.log('📍 Opening product details: ${product.title}');
                    Navigator.pushNamed(
                      context,
                      AppRoutes.productDetails,
                      arguments: product,
                    );
                  },
                  favoritePosition: FavoriteButtonPosition.topLeft,
                  isFavoriteOverride: true,
                ),
                if (isSold)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
            ),
          );
        }, childCount: allFavorites.length),
      ),
    );
  }

  // ✅ ✅ ✅ الجزء المعدل - استخدام Consumer<HomeViewModel> للبائعين ✅ ✅ ✅
  Widget _buildSellersSliver(BuildContext context, FavoritesViewModel viewModel) {
    if (viewModel.favoriteSellers.isEmpty) {
      return _emptySliver(
        context,
        icon: Icons.people_outline_rounded,
        title: 'لا توجد بائعين مفضلين',
        subtitle: 'قم بمتابعة البائعين',
      );
    }
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((ctx, i) {
          final seller = viewModel.favoriteSellers[i];
          
          // ✅ استخدام Consumer<HomeViewModel> لمراقبة حالة المتابعة
          return Consumer<HomeViewModel>(
            builder: (context, homeViewModel, child) {
              // ✅ الحصول على حالة المتابعة الحالية من HomeViewModel
              final isFollowed = homeViewModel.isSellerFavoriteSync(seller.id);
              
              return FadeTransition(
                opacity: _fade,
                child: _SellerCard(
                  key: ValueKey('${seller.id}_$isFollowed'), // ✅ تحديث المفتاح عند تغيير الحالة
                  seller: seller,
                  isFollowed: isFollowed,
                  onFollowTap: () => _toggleSellerFollow(seller.id, viewModel),
                  onTap: () => viewModel.onSellerTap(seller),
                ),
              );
            },
          );
        }, childCount: viewModel.favoriteSellers.length),
      ),
    );
  }

  // ✅ دالة لمتابعة/إلغاء متابعة بائع
  Future<void> _toggleSellerFollow(String sellerId, FavoritesViewModel viewModel) async {
    final homeViewModel = context.read<HomeViewModel>();
    
    _logger.log('🔄 Toggling seller follow: $sellerId');
    
    // ✅ تحديث HomeViewModel أولاً (سيؤدي إلى تحديث الواجهة تلقائياً)
    await homeViewModel.toggleFavoriteSeller(sellerId);
    
    // ✅ تحديث FavoritesViewModel في الخلفية
    await viewModel.loadFavoriteSellers();
    
    _logger.log('✅ Seller follow toggled successfully');
  }

  SliverToBoxAdapter _emptySliver(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(
                icon,
                size: 64,
                color: AppColors.textPlaceholder.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: AppColors.textPlaceholder,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textPlaceholder,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tabs Row ─────────────────────────────────────────────────────────────────

class _TabsRow extends StatelessWidget {
  final FavoritesTab activeTab;
  final void Function(FavoritesTab) onTabChanged;
  const _TabsRow({required this.activeTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: FavoritesTab.values.map((tab) {
        final isActive = activeTab == tab;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Button(
              text: tab.label,
              onPressed: () => onTabChanged(tab),
              variant: isActive ? ButtonVariant.primary : ButtonVariant.outline,
              size: ButtonSize.medium,
              isFullWidth: true,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Seller Card (معدل) ─────────────────────────────────────────────────────────

class _SellerCard extends StatelessWidget {
  final FavoriteSeller seller;
  final bool isFollowed;
  final VoidCallback onFollowTap;
  final VoidCallback onTap;
  
  const _SellerCard({
    super.key,
    required this.seller,
    required this.isFollowed,
    required this.onFollowTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.stroke.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  ClipOval(
                    child: seller.imageUrl != null && seller.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: seller.imageUrl!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 70,
                              height: 70,
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
                            errorWidget: (context, url, error) => Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary1.withOpacity(0.1),
                                border: Border.all(
                                  color: AppColors.primary1.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  seller.name.isNotEmpty ? seller.name.substring(0, 1) : '?',
                                  style: AppTextStyles.bodyLarge(context).copyWith(
                                    color: AppColors.primary1,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary1.withOpacity(0.1),
                              border: Border.all(
                                color: AppColors.primary1.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                seller.name.isNotEmpty ? seller.name.substring(0, 1) : '?',
                                style: AppTextStyles.bodyLarge(context).copyWith(
                                  color: AppColors.primary1,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    seller.name,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            FavoriteButton(
              isFavorite: isFollowed,
              onTap: onFollowTap,
              position: FavoriteButtonPosition.topLeft,
              size: FavoriteButtonSize.medium,
            ),
          ],
        ),
      ),
    );
  }
}