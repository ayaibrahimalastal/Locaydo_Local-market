// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/features/categories/data/models/category_model.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/shared/widgets/common/favorite_bottom_sheet.dart';
import 'package:locaydo_app/shared/widgets/common/favorite_button.dart';
import 'package:locaydo_app/shared/widgets/product/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          context.read<HomeViewModel>();
        } catch (e) {
          debugPrint('❌ HomeViewModel not available: $e');
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeViewModel>().refreshProducts();
    }
  }

  void _navigateToCategories() async {
    final reset = await Navigator.pushNamed(context, AppRoutes.categories);
    if (reset == true && mounted) {
      final vm = context.read<HomeViewModel>();
      if (vm.selectedCategory != ProductCategory.all) {
        vm.setSelectedCategory(ProductCategory.all);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: vm.refreshProducts,
                color: AppColors.primaryDark,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),
                    _buildLocationBar(),
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    _buildSearchBar(),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    _buildCategoriesSection(vm),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    _buildProductsGrid(vm),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Sections ──────────────────────────────────────────
  SliverToBoxAdapter _buildLocationBar() {
    return SliverToBoxAdapter(
      child: Center(
        child: SizedBox(
          width: context.contentWidth,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                SvgPicture.asset(
                  AppAssets.location,
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                      AppColors.primaryDark, BlendMode.srcIn),
                ),
                const SizedBox(width: 4),
                Text(
                  'قطاع غزة، غزة',
                  style: AppTextStyles.bodySmall(context)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Center(
        child: SizedBox(
          width: context.contentWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.searchUsers),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.stroke.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: AppColors.textPlaceholder, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "ابحث عن بائع...",
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textPlaceholder,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildCategoriesSection(HomeViewModel vm) {
    return SliverToBoxAdapter(
      child: Center(
        child: SizedBox(
          width: context.contentWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.categoriesTitle,
                      style: AppTextStyles.displaySmall(context)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: _navigateToCategories,
                      child: Text(
                        AppStrings.viewAll,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textPlaceholder,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 1 + vm.categories.length,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _AllCategoryItem(
                          isSelected:
                              vm.selectedCategory == ProductCategory.all,
                          onTap: () =>
                              vm.setSelectedCategory(ProductCategory.all),
                        );
                      }
                      final cat = vm.categories[i - 1];
                      final catEnum = cat.toProductCategory();
                      return _CategoryItem(
                        category:   cat,
                        isSelected: vm.selectedCategory == catEnum,
                        onTap:      () => vm.setSelectedCategory(catEnum),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid(HomeViewModel vm) {
    if (vm.hasNetworkError && vm.allProducts.isEmpty) {
      return SliverToBoxAdapter(child: _ErrorState(vm: vm));
    }
    if (vm.isCategoryChanging ||
        (vm.isLoading && vm.allProducts.isEmpty)) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(color: AppColors.primaryDark),
          ),
        ),
      );
    }

    final available = vm.filteredProducts
        .where((p) => p.isAvailable)
        .toList();

    if (available.isEmpty) {
      return SliverToBoxAdapter(child: _EmptyState(vm: vm));
    }

    return SliverToBoxAdapter(
      child: Center(
        child: SizedBox(
          width: context.contentWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: available.length,
              itemBuilder: (ctx, i) =>
                  _ProductCardItem(product: available[i]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _ProductCardItem extends StatelessWidget {
  final ProductModel product;
  const _ProductCardItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        final updated = vm.getProductById(product.id) ?? product;
        if (updated.isSold) return const SizedBox.shrink();

        final isFav = vm.isProductFavoriteSync(updated.id);
        return ProductCard(
          product:          updated,
          isFavoriteOverride: isFav,
          favoritePosition: FavoriteButtonPosition.topLeft,
          onFavoriteTap: () {
            Future.microtask(() async {
              await FavoriteBottomSheet.show(
                context,
                productTitle: updated.title,
                isAdding:     !isFav,
                onToggle:     () => vm.toggleFavorite(updated.id),
                onComplete:   () {},
              );
            });
          },
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.productDetails,
            arguments: updated,
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final HomeViewModel vm;
  const _ErrorState({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 64,
                color: AppColors.textPlaceholder.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              vm.errorMessage ?? 'لا يوجد اتصال بالإنترنت',
              style: AppTextStyles.bodyLarge(context)
                  .copyWith(color: AppColors.textPlaceholder),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: vm.refreshProducts,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppStrings.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final HomeViewModel vm;
  const _EmptyState({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.textPlaceholder.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              vm.selectedCategory == ProductCategory.all
                  ? 'لا توجد منتجات متاحة حالياً'
                  : 'لا توجد منتجات في ${vm.selectedCategory.label}',
              style: AppTextStyles.bodyLarge(context)
                  .copyWith(color: AppColors.textPlaceholder),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllCategoryItem extends StatelessWidget {
  final bool         isSelected;
  final VoidCallback onTap;
  const _AllCategoryItem({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _CategoryCircle(
      svgPath:    AppAssets.all,
      label:      'الكل',
      isSelected: isSelected,
      onTap:      onTap,
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final bool          isSelected;
  final VoidCallback  onTap;
  const _CategoryItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = category.name.length > 6
        ? '${category.name.substring(0, 5)}..'
        : category.name;
    return _CategoryCircle(
      svgPath:    category.iconPath,
      label:      label,
      isSelected: isSelected,
      onTap:      onTap,
      tooltip:    category.name,
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  final String       svgPath;
  final String       label;
  final bool         isSelected;
  final VoidCallback onTap;
  final String?      tooltip;

  const _CategoryCircle({
    required this.svgPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:      tooltip ?? label,
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 75,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryDark.withValues(alpha: 0.1),
                  border: isSelected
                      ? Border.all(color: AppColors.primaryDark, width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      svgPath,
                      width: 26,
                      height: 26,
                      colorFilter: ColorFilter.mode(
                        isSelected
                            ? AppColors.primaryDark
                            : AppColors.iconDefault,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 70,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
