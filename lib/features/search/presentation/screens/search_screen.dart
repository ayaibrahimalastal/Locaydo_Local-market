// lib/features/search/presentation/screens/search_screen.dart

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/enums/search_enums.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/search/data/models/search_result_model.dart';
import 'package:locaydo_app/features/search/presentation/viewmodels/search_viewmodel.dart';
import 'package:locaydo_app/shared/widgets/form/input.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  final SearchType searchType;

  const SearchScreen.users({super.key})    : searchType = SearchType.users;
  const SearchScreen.products({super.key}) : searchType = SearchType.products;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late final AnimationController _animCtrl;
  late final Animation<double>   _fade;

  SearchViewModel? _viewModel;
  Timer?           _debounce;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _searchController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    final text = _searchController.text;
    _debounce?.cancel();
    if (text.isEmpty) {
      _viewModel?.clearSearch();
      _animCtrl.forward(from: 0);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _viewModel?.setSearchQuery(text);
      _animCtrl.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(
        logger:     DebugLogger(),
        searchType: widget.searchType,
      ),
      child: Consumer<SearchViewModel>(
        builder: (context, vm, _) {
          _viewModel = vm;
          vm.setContext(context);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                title: Text('بحث',
                    style: AppTextStyles.displaySmall(context)
                        .copyWith(fontWeight: FontWeight.bold)),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: SafeArea(child: _buildBody(context, vm)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, SearchViewModel vm) {
    final query = _searchController.text;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // ── Search field ─────────────────────────────────
        SliverToBoxAdapter(
          child: Center(
            child: SizedBox(
              width: context.contentWidth,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Input(
                  hintText:            widget.searchType.hintText,
                  controller:          _searchController,
                  prefixIcon:          Icons.search_rounded,
                  suffixIcon:
                      query.isNotEmpty ? Icons.close_rounded : null,
                  onSuffixIconPressed: () {
                    _searchController.clear();
                    vm.clearSearch();
                  },
                ),
              ),
            ),
          ),
        ),

        // ── Results ───────────────────────────────────────
        if (query.isNotEmpty) ...[
          _resultsHeader(context),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (vm.isLoading)
            _loadingSliver()
          else if (vm.hasResults)
            widget.searchType == SearchType.users
                ? _usersSliver(context, vm)
                : _productsSliver(context, vm)
          else
            _emptySliver(context),
        ] else
          _initialSliver(context),
      ],
    );
  }

  SliverToBoxAdapter _resultsHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: SizedBox(
          width: context.contentWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('النتائج',
                style: AppTextStyles.displaySmall(context)
                    .copyWith(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _loadingSliver() {
    return const SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primaryDark),
        ),
      ),
    );
  }

  Widget _usersSliver(BuildContext context, SearchViewModel vm) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => FadeTransition(
            opacity: _fade,
            child: _UserListItem(
              user:  vm.filteredUserResults[i],
              onTap: () => vm.onUserTap(vm.filteredUserResults[i]),
            ),
          ),
          childCount: vm.filteredUserResults.length,
        ),
      ),
    );
  }

  Widget _productsSliver(BuildContext context, SearchViewModel vm) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:   2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing:  12,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) {
            final p = vm.filteredProductResults[i];
            return FadeTransition(
              opacity: _fade,
              child: _ProductSearchCard(
                product:       p,
                onFavoriteTap: () => vm.toggleFavorite(p.id),
                onTap:         () => vm.onProductTap(p),
              ),
            );
          },
          childCount: vm.filteredProductResults.length,
        ),
      ),
    );
  }

  Widget _emptySliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              children: [
                Icon(Icons.search_off_rounded,
                    size: context.responsiveFontSize(64),
                    color: AppColors.textPlaceholder.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('لا يوجد نتائج',
                    style: AppTextStyles.bodyLarge(context)
                        .copyWith(color: AppColors.textPlaceholder),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _initialSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            children: [
              Icon(
                widget.searchType == SearchType.users
                    ? Icons.people_rounded
                    : Icons.shopping_bag_rounded,
                size:  context.responsiveFontSize(64),
                color: AppColors.textPlaceholder.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                widget.searchType.hintText,
                style: AppTextStyles.bodyLarge(context)
                    .copyWith(color: AppColors.textPlaceholder),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── User List Item ────────────────────────────────────────────────────────────

class _UserListItem extends StatelessWidget {
  final UserSearchResult user;
  final VoidCallback     onTap;

  const _UserListItem({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.stroke.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            ClipOval(
              child: user.imageUrl != null && user.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl:     user.imageUrl!,
                      width: 48, height: 48, fit: BoxFit.cover,
                      placeholder:  (_, __) => _avatar(context, user.name),
                      errorWidget:  (_, __, ___) => _avatar(context, user.name),
                    )
                  : _avatar(context, user.name),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(user.name,
                  style: AppTextStyles.bodyLarge(context)
                      .copyWith(fontWeight: FontWeight.bold)),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.primaryDark,
                size:  context.responsiveFontSize(16)),
          ],
        ),
      ),
    );
  }

  Widget _avatar(BuildContext context, String name) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryDark.withValues(alpha: 0.1),
        border: Border.all(
            color: AppColors.primaryDark.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppTextStyles.bodyLarge(context).copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: context.responsiveFontSize(18),
          ),
        ),
      ),
    );
  }
}

// ── Product Search Card ───────────────────────────────────────────────────────

class _ProductSearchCard extends StatelessWidget {
  final ProductSearchResult product;
  final VoidCallback        onFavoriteTap;
  final VoidCallback        onTap;

  const _ProductSearchCard({
    required this.product,
    required this.onFavoriteTap,
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
              color: AppColors.stroke.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImageStack(
              product:       product,
              onFavoriteTap: onFavoriteTap,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PriceAndTitle(product: product),
                  const SizedBox(height: 4),
                  _SellerRow(product: product),
                  const SizedBox(height: 4),
                  _PaymentRow(methods: product.paymentMethods),
                  const SizedBox(height: 4),
                  _LocationRow(
                    location: product.location,
                    area:     product.area,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImageStack extends StatelessWidget {
  final ProductSearchResult product;
  final VoidCallback        onFavoriteTap;

  const _ProductImageStack({
    required this.product,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: hasImage
              ? CachedNetworkImage(
                  imageUrl: product.imageUrl!,
                  height: 110, width: double.infinity, fit: BoxFit.cover,
                  placeholder: (_, __) => _imagePlaceholder(context),
                  errorWidget: (_, __, ___) => _imagePlaceholder(context),
                )
              : _imagePlaceholder(context),
        ),
        Positioned(
          top: 6, right: 6,
          child: GestureDetector(
            onTap: onFavoriteTap,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3),
                ],
              ),
              child: Icon(
                product.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: product.isFavorite
                    ? AppColors.errorFields
                    : AppColors.textPlaceholder,
                size: context.responsiveFontSize(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder(BuildContext context) => Container(
        height: 110,
        width: double.infinity,
        color: AppColors.primaryDark.withValues(alpha: 0.05),
        child: Center(
          child: Icon(Icons.image_outlined,
              color: AppColors.textPlaceholder,
              size: context.responsiveFontSize(30)),
        ),
      );
}

class _PriceAndTitle extends StatelessWidget {
  final ProductSearchResult product;
  const _PriceAndTitle({required this.product});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${product.price} ${product.currency}',
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.primaryDark, fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 4),
          Text(product.title,
              style: AppTextStyles.bodyMedium(context)
                  .copyWith(fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      );
}

class _SellerRow extends StatelessWidget {
  final ProductSearchResult product;
  const _SellerRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = product.sellerAvatarUrl != null &&
        product.sellerAvatarUrl!.isNotEmpty;

    return Row(
      children: [
        ClipOval(
          child: hasAvatar
              ? CachedNetworkImage(
                  imageUrl: product.sellerAvatarUrl!,
                  width: 14, height: 14, fit: BoxFit.cover,
                  placeholder: (_, __) => _avatarPlaceholder(),
                  errorWidget: (_, __, ___) => _avatarPlaceholder(),
                )
              : _avatarPlaceholder(),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(product.sellerName,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textSecondary, fontSize: 10,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _avatarPlaceholder() => Container(
        width: 14, height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryDark.withValues(alpha: 0.1),
        ),
        child: const Center(
          child: Icon(Icons.person_outline,
              size: 8, color: AppColors.primaryDark),
        ),
      );
}

class _PaymentRow extends StatelessWidget {
  final List<PaymentMethod> methods;
  const _PaymentRow({required this.methods});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: methods.map((m) {
        final isCash = m == PaymentMethod.cash;
        final color  = isCash ? AppColors.primaryDark : const Color(0xFFB41A75);
        return Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(m.label,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: color, fontWeight: FontWeight.w600,
              )),
        );
      }).toList(),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final String location;
  final String area;
  const _LocationRow({required this.location, required this.area});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on_rounded,
            color: AppColors.textPlaceholder, size: 9),
        const SizedBox(width: 2),
        Expanded(
          child: Text('$location، $area',
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textPlaceholder, fontSize: 9,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
