// lib/features/categories/presentation/viewmodels/category_details_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';


class CategoryDetailsViewModel extends ChangeNotifier {
  final Logger _logger;
  final ProductCategory category;
  final HomeViewModel _homeViewModel;

  String searchQuery = '';
  bool isLoading     = false;
  String? errorMessage;

  List<ProductModel> get products => _homeViewModel.allProducts
      .where((p) => p.category == category)
      .toList();

  List<ProductModel> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    return products
        .where((p) =>
            p.title.contains(searchQuery) ||
            p.description.contains(searchQuery))
        // ❌ تمت إزالة || p.area.contains(searchQuery)
        .toList();
  }

  int get productsCount => products.length;

  CategoryDetailsViewModel({
    required Logger logger,
    required this.category,
    required HomeViewModel homeViewModel,
  })  : _logger = logger,
        _homeViewModel = homeViewModel {
    _homeViewModel.addListener(_onHomeChanged);
    _logger.log(
        'CategoryDetailsViewModel init: ${category.label} — $productsCount products');
  }

  void _onHomeChanged() {
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (searchQuery != query) {
      searchQuery = query;
      notifyListeners();
    }
  }

  void toggleFavorite(String productId) =>
      _homeViewModel.toggleFavorite(productId);

  Future<void> refreshProducts() async {
    isLoading = true;
    notifyListeners();
    try {
      await _homeViewModel.refreshProducts();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'فشل تحديث المنتجات';
      _logger.error('Refresh failed', e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _homeViewModel.removeListener(_onHomeChanged);
    super.dispose();
  }
}