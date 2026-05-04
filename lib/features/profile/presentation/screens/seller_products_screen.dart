import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/utils/animations.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/features/products/data/models/seller_product_model.dart';
import 'package:locaydo_app/features/profile/presentation/viewmodels/seller_products_viewmodel.dart';
import 'package:locaydo_app/shared/widgets/common/favorite_bottom_sheet.dart';
import 'package:locaydo_app/shared/widgets/common/favorite_button.dart';
import 'package:locaydo_app/shared/widgets/product/product_card.dart';
import 'package:provider/provider.dart';

enum SellerProductsType { available, sold }

class SellerProductsScreen extends StatefulWidget {
  final SellerProductsType type;

  const SellerProductsScreen.available({super.key}) : type = SellerProductsType.available;
  const SellerProductsScreen.sold({super.key}) : type = SellerProductsType.sold;

  @override
  State<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends State<SellerProductsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  final _logger = DebugLogger();

  @override
  void initState() {
    super.initState();
    final animation = AppAnimations.createFullAnimation(this);
    _animCtrl = animation.controller;
    _fade = animation.fade;
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String get _title =>
      widget.type == SellerProductsType.available
          ? 'المنتجات المتاحة للبيع'
          : 'المنتجات المُباعة';

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SellerProductsViewModel(
            logger: DebugLogger(),
            homeViewModel: context.read<HomeViewModel>(),
          ),
        ),
      ],
      child: Consumer<SellerProductsViewModel>(
        builder: (context, viewModel, _) {
          final products = widget.type == SellerProductsType.available
              ? viewModel.availableProducts
              : viewModel.soldProducts;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  _title,
                  style: AppTextStyles.displaySmall(context).copyWith(fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
              ),
              body: SafeArea(
                child: Center(
                  child: SizedBox(
                    width: context.contentWidth,
                    child: _buildBody(context, viewModel, products),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, SellerProductsViewModel viewModel, List<SellerProduct> products) {
    if (viewModel.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(color: AppColors.primary1),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.type == SellerProductsType.available
                    ? Icons.inventory_2_outlined
                    : Icons.shopping_cart_outlined,
                size: 64,
                color: AppColors.textPlaceholder.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                widget.type == SellerProductsType.available
                    ? 'لا توجد منتجات متاحة'
                    : 'لا توجد منتجات مباعة',
                style: AppTextStyles.bodyLarge(context).copyWith(color: AppColors.textPlaceholder),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refreshProducts,
      color: AppColors.primary1,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final product = products[i];
                  return FadeTransition(
                    opacity: _fade,
                    child: _buildProductCard(product, viewModel),
                  );
                },
                childCount: products.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    SellerProduct product,
    SellerProductsViewModel viewModel,
  ) {
    final isSold = product.status == ProductStatus.sold;

    return Stack(
      children: [
        Consumer<HomeViewModel>(
          builder: (context, homeVM, child) {
            final isFavorite = homeVM.isProductFavoriteSync(product.id);

            final productModel = ProductModel(
              id: product.id,
              title: product.title,
              description: product.description,
              price: product.price,
              currency: product.currency,
              location: product.location,
              imageUrl: product.imageUrl,
              additionalImages: product.additionalImages,
              category: product.category,
              condition: product.condition,
              paymentMethods: product.paymentMethods,
              sellerId: FirebaseAuth.instance.currentUser?.uid ?? product.sellerId,
              sellerName: '',
              createdAt: product.createdAt,
              status: product.status,
            );

            return ProductCard(
              product: productModel,
              onFavoriteTap: () async {
                await FavoriteBottomSheet.show(
                  context,
                  productTitle: product.title,
                  isAdding: !isFavorite,
                  onToggle: () async {
                    return await homeVM.toggleFavorite(product.id);
                  },
                  onComplete: () {},
                );
              },
              onTap: () {
                if (homeVM.getProductById(product.id) == null) {
                  homeVM.addNewProduct(productModel);
                }
                final existingProduct = homeVM.getProductById(product.id);
                Navigator.pushNamed(
                  context,
                  AppRoutes.productDetails,
                  arguments: existingProduct ?? productModel,
                );
              },
              favoritePosition: FavoriteButtonPosition.topLeft,
              showFavoriteButton: false,
              isFavoriteOverride: isFavorite,
            );
          },
        ),
        Positioned(
          top: 4,
          left: 4,
          child: _OptionsButton(
            onTap: () => viewModel.showProductOptions(context, product),
          ),
        ),
        if (isSold)
          Positioned(
            bottom: 8,
            left: 8,
            child: _SoldBadge(),
          ),
      ],
    );
  }
}

class _OptionsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _OptionsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.more_horiz_rounded, size: 16),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 16,
      ),
    );
  }
}

class _SoldBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'مباع',
        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}