import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/categories/data/models/category_model.dart';
import 'package:locaydo_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:locaydo_app/features/categories/domain/repositories/category_repository.dart';
import 'package:locaydo_app/features/favorites/data/models/favorites_model.dart';
import 'package:locaydo_app/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:locaydo_app/features/products/domain/repositories/product_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final Logger _logger;
  final CategoryRepository _categoryRepository;
  final ProductRepository _productRepository;
  final FavoritesRepositoryImpl _favoritesRepository;

  ProductCategory selectedCategory = ProductCategory.all;
  List<CategoryModel> _categories = [];
  List<ProductModel> _allProducts = [];
  bool isLoading = false;
  bool isCategoryChanging = false;
  bool hasNetworkError = false;
  String? errorMessage;

  final Map<ProductCategory, List<ProductModel>> _categoryCache = {};
  final Map<String, bool> _favoritesCache = {};
  
  // ✅ كاش للبائعين المفضلين
  final Map<String, bool> _favoriteSellersCache = {};
  final Set<String> _pendingFavSellerUpdates = {};
  
  final Set<String> _pendingFavUpdates = {};
  bool _isInitialLoad = true;

  final List<VoidCallback> _favoriteListeners = [];
  final List<VoidCallback> _favoritesViewModelListeners = [];

  HomeViewModel({
    required Logger logger,
    CategoryRepository? categoryRepository,
    ProductRepository? productRepository,
    FavoritesRepositoryImpl? favoritesRepository,
  }) : _logger = logger,
       _categoryRepository =
           categoryRepository ?? CategoryRepositoryImpl(logger: logger),
       _productRepository =
           productRepository ?? ProductRepositoryImpl(logger: logger),
       _favoritesRepository =
           favoritesRepository ?? FavoritesRepositoryImpl(logger: logger) {
    loadInitialData();
  }

  // ── Getters ───────────────────────────────────────────
  List<CategoryModel> get categories => _categories;
  List<ProductModel> get allProducts => _allProducts;

  List<ProductModel> get filteredProducts {
    if (selectedCategory == ProductCategory.all) return List.of(_allProducts);
    return _allProducts.where((p) => p.category == selectedCategory).toList();
  }

  bool isProductFavoriteSync(String productId) =>
      _favoritesCache[productId] ?? false;
  
  // ✅ دالة للتحقق من حالة البائع المفضل
  bool isSellerFavoriteSync(String sellerId) =>
      _favoriteSellersCache[sellerId] ?? false;

  // ── Listeners ─────────────────────────────────────────
  void addFavoriteListener(VoidCallback l) => _favoriteListeners.add(l);
  void removeFavoriteListener(VoidCallback l) => _favoriteListeners.remove(l);
  void addFavoritesViewModelListener(VoidCallback l) =>
      _favoritesViewModelListeners.add(l);
  void removeFavoritesViewModelListener(VoidCallback l) =>
      _favoritesViewModelListeners.remove(l);

  void _notifyFavoriteListeners() {
    for (final l in _favoriteListeners) l();
  }

  void _notifyFavoritesViewModels() {
    for (final l in _favoritesViewModelListeners) l();
  }

  // ── Load ──────────────────────────────────────────────
  Future<void> loadInitialData() async {
    isLoading = true;
    hasNetworkError = false;
    notifyListeners();
    await Future.wait([
      loadCategories(),
      loadAllProducts(),
      loadFavoriteSellers(), // ✅ تحميل البائعين المفضلين عند البدء
    ]);
    isLoading = false;
    _isInitialLoad = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _categoryRepository.getAllCategories();
      hasNetworkError = false;
    } on SocketException catch (e) {
      _logger.error('No internet connection', e);
      _handleNetworkError('لا يوجد اتصال بالإنترنت');
      _categories = [];
    } catch (e) {
      _logger.error('Failed to load categories', e);
      _handleNetworkError('فشل تحميل الفئات');
      _categories = [];
    }
    notifyListeners();
  }

  Future<void> loadAllProducts() async {
    try {
      if (_categoryCache.containsKey(ProductCategory.all) && !_isInitialLoad) {
        _allProducts = _categoryCache[ProductCategory.all]!;
        unawaited(_loadFavoritesAsync());
        notifyListeners();
        return;
      }

      if (_isInitialLoad) {
        isCategoryChanging = true;
        notifyListeners();
      }

      hasNetworkError = false;
      final products = await _productRepository.getAllProducts();
      _allProducts = _dedup(products);
      _categoryCache[ProductCategory.all] = _allProducts;
      errorMessage = null;

      await _loadFavoritesAll();
    } on SocketException catch (e) {
      _logger.error('No internet', e);
      if (_categoryCache.containsKey(ProductCategory.all)) {
        _allProducts = _categoryCache[ProductCategory.all]!;
        await _loadFavoritesAll();
        errorMessage = null;
        hasNetworkError = false;
      } else {
        _handleNetworkError('لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة');
        _allProducts = [];
      }
    } catch (e) {
      _logger.error('Failed to load products', e);
      _handleNetworkError('فشل تحميل المنتجات');
      _allProducts = [];
    } finally {
      if (_isInitialLoad) isCategoryChanging = false;
      notifyListeners();
    }
  }

  Future<void> loadProductsByCategory(ProductCategory category) async {
    try {
      if (_categoryCache.containsKey(category)) {
        _allProducts = _categoryCache[category]!;
        selectedCategory = category;
        unawaited(_loadFavoritesAsync());
        notifyListeners();
        unawaited(_refreshCategoryBg(category));
        return;
      }

      isCategoryChanging = true;
      hasNetworkError = false;
      notifyListeners();

      final products = await _productRepository.getProductsByCategory(
        category.name,
      );
      _allProducts = _dedup(products);
      _categoryCache[category] = _allProducts;
      errorMessage = null;

      await _loadFavoritesAll();
    } on SocketException catch (_) {
      if (_categoryCache.containsKey(ProductCategory.all)) {
        final all = _categoryCache[ProductCategory.all]!;
        _allProducts = all.where((p) => p.category == category).toList();
        await _loadFavoritesAll();
        errorMessage = null;
        hasNetworkError = false;
      } else {
        _handleNetworkError('لا يوجد اتصال بالإنترنت');
        _allProducts = [];
      }
    } catch (e) {
      _logger.error('Failed to load category: ${category.label}', e);
      _handleNetworkError('فشل تحميل المنتجات');
      _allProducts = [];
    } finally {
      isCategoryChanging = false;
      notifyListeners();
    }
  }

  Future<void> _refreshCategoryBg(ProductCategory category) async {
    try {
      final products = await _productRepository.getProductsByCategory(
        category.name,
      );
      _categoryCache[category] = _dedup(products);
      if (selectedCategory == category) {
        _allProducts = _categoryCache[category]!;
        await _loadFavoritesAll();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadProductsBySeller(String sellerId) async {
    try {
      isLoading = true;
      hasNetworkError = false;
      notifyListeners();
      _allProducts = await _productRepository.getProductsBySeller(sellerId);
      await _loadFavoritesAll();
      errorMessage = null;
    } on SocketException catch (_) {
      _handleNetworkError('لا يوجد اتصال بالإنترنت');
    } catch (e) {
      _logger.error('Failed to load seller products', e);
      errorMessage = 'فشل تحميل منتجات البائع';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Favorites (Products) ─────────────────────────────────────────
  Future<void> _loadFavoritesAll() async {
    _favoritesCache.clear();
    for (final p in _allProducts) {
      _favoritesCache[p.id] = await _favoritesRepository.isFavorite(p.id);
    }
    notifyListeners();
  }

  Future<void> _loadFavoritesAsync() async {
    for (final p in _allProducts) {
      final isFav = await _favoritesRepository.isFavorite(p.id);
      if (_favoritesCache[p.id] != isFav) _favoritesCache[p.id] = isFav;
    }
    notifyListeners();
  }

  Future<bool> toggleFavorite(String productId) async {
    final product = _allProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    if (product.id.isEmpty || product.title.isEmpty) return false;
    if (_pendingFavUpdates.contains(productId)) return false;

    _pendingFavUpdates.add(productId);
    final newStatus = !isProductFavoriteSync(productId);
    final oldStatus = !newStatus;

    _favoritesCache[productId] = newStatus;
    notifyListeners();
    _notifyFavoriteListeners();
    _notifyFavoritesViewModels();

    unawaited(
      (newStatus
              ? _favoritesRepository.addToFavorites(product)
              : _favoritesRepository.removeFromFavorites(productId))
          .then((_) => _pendingFavUpdates.remove(productId))
          .catchError((e) {
            _favoritesCache[productId] = oldStatus;
            notifyListeners();
            _notifyFavoriteListeners();
            _notifyFavoritesViewModels();
            _pendingFavUpdates.remove(productId);
          }),
    );

    return true;
  }

  // ✅ ── Favorites (Sellers) ─────────────────────────────────────────
  
  /// ✅ تحميل البائعين المفضلين وملء الكاش
  Future<void> loadFavoriteSellers() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      _logger.log('📦 Loading favorite sellers into cache for user: ${user.uid}');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favoriteSellers')
          .get();
      
      _favoriteSellersCache.clear();
      for (final doc in snapshot.docs) {
        _favoriteSellersCache[doc.id] = true;
      }
      _logger.log('✅ Loaded ${_favoriteSellersCache.length} favorite sellers into cache');
      notifyListeners();
      _notifyFavoritesViewModels();
    } catch (e) {
      _logger.error('Failed to load favorite sellers', e);
    }
  }

  /// ✅ تبديل حالة متابعة البائع (UI first)
  Future<bool> toggleFavoriteSeller(String sellerId) async {
    if (sellerId.isEmpty) return false;
    if (_pendingFavSellerUpdates.contains(sellerId)) return false;

    _pendingFavSellerUpdates.add(sellerId);
    final newStatus = !isSellerFavoriteSync(sellerId);
    final oldStatus = !newStatus;

    _logger.log('🔄 Toggling seller favorite: $sellerId, newStatus: $newStatus');

    // ✅ تحديث الكاش فوراً (UI first)
    if (newStatus) {
      _favoriteSellersCache[sellerId] = true;
    } else {
      _favoriteSellersCache.remove(sellerId);
    }
    
    notifyListeners();
    _notifyFavoriteListeners();
    _notifyFavoritesViewModels();

    // ✅ تحديث قاعدة البيانات في الخلفية
    unawaited(
      (newStatus
              ? _favoritesRepository.addSellerToFavorites(sellerId)
              : _favoritesRepository.removeSellerFromFavorites(sellerId))
          .then((_) {
            _logger.log('✅ Seller favorite updated on server: $sellerId');
            _pendingFavSellerUpdates.remove(sellerId);
          })
          .catchError((e) {
            _logger.error('Failed to toggle seller favorite on server', e);
            // التراجع عن التغيير
            if (oldStatus) {
              _favoriteSellersCache[sellerId] = true;
            } else {
              _favoriteSellersCache.remove(sellerId);
            }
            notifyListeners();
            _notifyFavoriteListeners();
            _notifyFavoritesViewModels();
            _pendingFavSellerUpdates.remove(sellerId);
          }),
    );

    return true;
  }

  Future<void> refreshFavoritesCache() async {
    await _loadFavoritesAsync();
    await loadFavoriteSellers();
    _notifyFavoriteListeners();
    _notifyFavoritesViewModels();
  }

  Future<void> syncFavoritesFromFirebase() async {
    await refreshFavoritesCache();
  }

  void updateProductFavoriteCache(String productId, bool isFavorite) {
    if (_favoritesCache[productId] == isFavorite) return;
    _favoritesCache[productId] = isFavorite;
    notifyListeners();
    _notifyFavoriteListeners();
    _notifyFavoritesViewModels();
  }

  void updateSellerFavoriteCache(String sellerId, bool isFavorite) {
    if (_favoriteSellersCache[sellerId] == isFavorite) return;
    if (isFavorite) {
      _favoriteSellersCache[sellerId] = true;
    } else {
      _favoriteSellersCache.remove(sellerId);
    }
    notifyListeners();
    _notifyFavoriteListeners();
    _notifyFavoritesViewModels();
  }

  // ── Product mutations ─────────────────────────────────
  void setSelectedCategory(ProductCategory category) {
    if (selectedCategory == category) return;
    selectedCategory = category;
    category == ProductCategory.all
        ? loadAllProducts()
        : loadProductsByCategory(category);
  }

  void addNewProduct(ProductModel product) {
    if (product.id.isEmpty) return;
    if (_allProducts.any((p) => p.id == product.id)) return;

    _allProducts.insert(0, product);
    _favoritesCache[product.id] = false;

    _categoryCache
        .putIfAbsent(ProductCategory.all, () => [])
        .insert(0, product);
    _categoryCache.putIfAbsent(product.category, () => []).insert(0, product);

    if (selectedCategory == ProductCategory.all ||
        selectedCategory == product.category) {
      notifyListeners();
    }
  }

  void removeProduct(String productId) {
    bool changed = false;
    final before = _allProducts.length;
    _allProducts.removeWhere((p) => p.id == productId);
    if (_allProducts.length < before) changed = true;

    for (final list in _categoryCache.values) {
      list.removeWhere((p) => p.id == productId);
    }
    if (_favoritesCache.remove(productId) != null) changed = true;

    if (changed) {
      notifyListeners();
      _notifyFavoriteListeners();
      _notifyFavoritesViewModels();
    }
  }

  void forceRemoveProduct(String productId) => removeProduct(productId);

  void updateProduct(ProductModel updated) {
    final idx = _allProducts.indexWhere((p) => p.id == updated.id);
    if (idx != -1) _allProducts[idx] = updated;
    for (final list in _categoryCache.values) {
      final i = list.indexWhere((p) => p.id == updated.id);
      if (i != -1) list[i] = updated;
    }
    notifyListeners();
  }

  void clearAllProducts() {
    _allProducts.clear();
    _favoritesCache.clear();
    _favoriteSellersCache.clear();
    _categoryCache.clear();
    notifyListeners();
    _notifyFavoriteListeners();
    _notifyFavoritesViewModels();
  }

  // ── Refresh ───────────────────────────────────────────
  Future<void> refreshProducts() async {
    _categoryCache.remove(selectedCategory);
    selectedCategory == ProductCategory.all
        ? await loadAllProducts()
        : await loadProductsByCategory(selectedCategory);
  }

  Future<void> refreshCategories() => loadCategories();

  void clearCache() {
    _categoryCache.clear();
    _favoritesCache.clear();
    _favoriteSellersCache.clear();
  }

  ProductModel? getProductById(String id) {
    try {
      return _allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Private ───────────────────────────────────────────
  List<ProductModel> _dedup(List<ProductModel> list) {
    final seen = <String>{};
    return list.where((p) => seen.add(p.id)).toList();
  }

  void _handleNetworkError(String message) {
    hasNetworkError = true;
    errorMessage = message;
  }
}