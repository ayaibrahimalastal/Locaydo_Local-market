// lib/features/categories/presentation/screens/category_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/utils/animations.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/shared/widgets/common/favorite_bottom_sheet.dart';
import 'package:locaydo_app/shared/widgets/common/favorite_button.dart';
import 'package:locaydo_app/shared/widgets/form/input.dart';
import 'package:locaydo_app/shared/widgets/product/product_card.dart';
import 'package:locaydo_app/shared/widgets/searh/location_filter_overlay.dart';
import 'package:provider/provider.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';

class CategoryDetailsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryDetailsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  // إضافة _slide على الرغم من عدم استخدامه حاليًا (احتياطي للاستخدام المستقبلي)
  late final Animation<Offset> _slide;

  List<String> _selectedLocations = [];

  static const List<String> _governorates = [
    'شمال غزة',
    'غزة المدينة',
    'الوسطى',
    'خان يونس',
    'رفح',
    'دير البلح',
  ];

  @override
  void initState() {
    super.initState();
    // ✅ الإصلاح: استخدام createFullAnimation بدلاً من create
    final anim = AppAnimations.createFullAnimation(this);
    _animCtrl = anim.controller;
    _fade = anim.fade;
    _slide = anim.slide; // تمت إضافتها للاكتمال
    _animCtrl.forward();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final vm = context.read<HomeViewModel>();
    // ✅ الإصلاح: استخدام fromString بدلاً من fromKey
    final target = ProductCategory.fromString(widget.categoryId);
    if (vm.selectedCategory != target) {
      vm.setSelectedCategory(target);
    } else if (vm.allProducts.isEmpty) {
      await vm.refreshProducts();
    }
  }

  List<ProductModel> _filtered(HomeViewModel vm) {
    var list = vm.filteredProducts.where((p) => p.isAvailable).toList();
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList();
    }
    if (_selectedLocations.isNotEmpty) {
      list = list
          .where((p) => _selectedLocations.contains(p.location))
          .toList();
    }
    return list;
  }

  void _showLocationFilter() => LocationFilterOverlay.show(
        context: context,
        initialSelectedLocations: _selectedLocations,
        onApplyFilters: (locs) => setState(() => _selectedLocations = locs), governorates:_governorates,
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.categoryName,
              style: AppTextStyles.displaySmall(context)
                  .copyWith(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        // ✅ الإصلاح: إزالة Center و SizedBox اللذين يستخدمان contentWidth غير المعرّف
        body: SafeArea(
          child: Consumer<HomeViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.allProducts.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryDark),
                );
              }

              if (vm.errorMessage != null && vm.allProducts.isEmpty) {
                return _ErrorView(
                  message: vm.errorMessage!,
                  onRetry: _loadProducts,
                );
              }

              final products = _filtered(vm);

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _searchAndFilterSliver(),
                  if (_selectedLocations.isNotEmpty) _locationChipsSliver(),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  _productsGrid(products, vm),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _searchAndFilterSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Input(
                hintText: AppStrings.searchHint,
                controller: _searchController,
                prefixIcon: Icons.search_rounded,
                suffixIcon: _searchController.text.isNotEmpty
                    ? Icons.close_rounded
                    : null,
                onSuffixIconPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 12),
            _FilterButton(
              hasFilters: _selectedLocations.isNotEmpty,
              onTap: _showLocationFilter,
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _locationChipsSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _selectedLocations
                .map(
                  (loc) => Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primaryDark.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(
                              () => _selectedLocations.remove(loc)),
                          child: const Icon(Icons.close,
                              size: 14, color: AppColors.primaryDark),
                        ),
                        const SizedBox(width: 4),
                        Text(loc,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryDark)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _productsGrid(List<ProductModel> products, HomeViewModel vm) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Column(
              children: [
                Icon(
                  _searchController.text.isEmpty && _selectedLocations.isEmpty
                      ? Icons.inventory_2_outlined
                      : Icons.search_off_rounded,
                  size: 64,
                  color: AppColors.textPlaceholder.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isEmpty && _selectedLocations.isEmpty
                      ? 'لا يوجد منتجات متاحة في ${widget.categoryName}'
                      : 'لا يوجد نتائج للبحث',
                  style: AppTextStyles.bodyLarge(context)
                      .copyWith(color: AppColors.textPlaceholder),
                ),
              ],
            ),
          ),
        ),
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
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final product = products[i];
            return FadeTransition(
              opacity: _fade,
              child: Consumer<HomeViewModel>(
                builder: (context, vm2, _) {
                  final updated = vm2.allProducts.firstWhere(
                    (p) => p.id == product.id,
                    orElse: () => product,
                  );
                  if (updated.isSold) return const SizedBox.shrink();

                  final isFav = vm2.isProductFavoriteSync(updated.id);
                  return ProductCard(
                    product: updated,
                    isFavoriteOverride: isFav,
                    favoritePosition: FavoriteButtonPosition.topLeft,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.productDetails,
                      arguments: updated,
                    ),
                    onFavoriteTap: () {
                      Future.microtask(() => FavoriteBottomSheet.show(
                            ctx,
                            productTitle: updated.title,
                            isAdding: !isFav,
                            onToggle: () => vm2.toggleFavorite(updated.id),
                            onComplete: () {},
                          ));
                    },
                  );
                },
              ),
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onTap;
  const _FilterButton({required this.hasFilters, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: hasFilters
              ? AppColors.primaryDark
              : AppColors.primaryDark.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFilters
                ? AppColors.primaryDark
                : AppColors.stroke.withValues(alpha: 0.3),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: SvgPicture.asset(
                AppAssets.filter,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  hasFilters ? Colors.white : AppColors.primaryDark,
                  BlendMode.srcIn,
                ),
              ),
            ),
            if (hasFilters)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.errorFields,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.errorFields),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyLarge(context)
                .copyWith(color: AppColors.errorFields),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark),
            child: Text(AppStrings.tryAgain),
          ),
        ],
      ),
    );
  }
}