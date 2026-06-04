import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/services/hive_cache_service.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/categories/data/models/category_model.dart';
import 'package:locaydo_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:locaydo_app/features/categories/domain/repositories/category_repository.dart';
import 'package:locaydo_app/features/favorites/data/models/favorites_model.dart';
import 'package:locaydo_app/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:locaydo_app/features/products/domain/repositories/product_repository.dart';

// ✅ دالة مساعدة لاستخدامها مع compute (خارج الكلاس)
@pragma('vm:entry-point')
List<ProductModel> _dedupProducts(List<ProductModel> list) {
  final seen = <String>{};
  return list.where((p) => seen.add(p.id)).toList();
}

class HomeViewModel extends ChangeNotifier {
  final Logger _logger;
  final CategoryRepository _categoryRepository;
  final ProductRepository _productRepository;
  final FavoritesRepositoryImpl _favoritesRepository;
  final HiveCacheService _cacheService;

  ProductCategory selectedCategory = ProductCategory.all;
  List<CategoryModel> _categories = [];
  List<ProductModel> _allProducts = [];
  bool isLoading = false;
  bool isCategoryChanging = false;
  bool hasNetworkError = false;
  String? errorMessage;
  bool _isShowingCachedData = false;

  // Cache for offline support
  final Map<ProductCategory, List<ProductModel>> _categoryCache = {};
  final Map<String, bool> _favoritesCache = {};
  final Map<String, bool> _favoriteSellersCache = {};
  
  // Stream subscriptions for real-time updates
  StreamSubscription<List<ProductModel>>? _productsStreamSubscription;
  StreamSubscription<Map<String, bool>>? _favoritesStreamSubscription;
  StreamSubscription<List<String>>? _favoriteSellersStreamSubscription;
  
  final Set<String> _pendingFavUpdates = {};
  final Set<String> _pendingFavSellerUpdates = {};
  bool _isInitialLoad = true;
  bool _isStreamsInitialized = false;
  bool _hasProductsLoaded = false;
  
  // ✅ متغيرات جديدة لمنع التهيئة المزدوجة
  bool _isInitializing = false;

  final List<VoidCallback> _favoriteListeners = [];
  final List<VoidCallback> _favoritesViewModelListeners = [];

  HomeViewModel({
    required Logger logger,
    required HiveCacheService hiveCacheService,
    CategoryRepository? categoryRepository,
    ProductRepository? productRepository,
    FavoritesRepositoryImpl? favoritesRepository,
  }) : _logger = logger,
       _cacheService = hiveCacheService,
       _categoryRepository = categoryRepository ?? CategoryRepositoryImpl(logger: logger),
       _productRepository = productRepository ?? ProductRepositoryImpl(logger: logger),
       _favoritesRepository = favoritesRepository ?? FavoritesRepositoryImpl(logger: logger) {
    _initialize();
  }

  // ── Initialization ──────────────────────────────────────────────
  Future<void> _initialize() async {
    // ✅ منع التهيئة المزدوجة
    if (_isInitializing || _isStreamsInitialized) {
      _logger.log('⚠️ Initialization already in progress or done');
      return;
    }
    
    _isInitializing = true;
    
    try {
      await _loadProductsFromCache();
      await _loadFreshDataFromNetwork();
      _setupRealtimeStreams();
    } finally {
      _isInitializing = false;
    }
  }
  
  Future<void> _loadProductsFromCache() async {
    if (_cacheService.hasProductsCache()) {
      _allProducts = _cacheService.getCachedProducts();
      _isShowingCachedData = true;
      _isInitialLoad = false;
      _hasProductsLoaded = true;
      
      _updateCategoryCache();
      
      _logger.log('✅ Loaded ${_allProducts.length} products from cache instantly');
      notifyListeners();
    } else {
      _logger.log('⚠️ No cache available, will show loading indicator');
      _isInitialLoad = true;
    }
  }
  
  void _updateCategoryCache() {
    _categoryCache[ProductCategory.all] = _allProducts;
    for (final category in ProductCategory.values) {
      if (category != ProductCategory.all) {
        final categoryProducts = _allProducts
            .where((p) => p.category == category && p.isAvailable && !p.isSold)
            .toList();
        _categoryCache[category] = categoryProducts;
      }
    }
  }
  
  Future<void> _loadFreshDataFromNetwork() async {
    try {
      isLoading = true;
      if (_isShowingCachedData) {
        notifyListeners();
      }
      
      await loadCategories();
      
      final freshProducts = await _productRepository.getAllProducts();
      
      // ✅ استخدام compute لتحسين الأداء
      _allProducts = await compute(_dedupProducts, freshProducts);
      
      _isShowingCachedData = false;
      _hasProductsLoaded = true;
      hasNetworkError = false;
      errorMessage = null;
      
      await _cacheService.cacheProducts(_allProducts);
      _updateCategoryCache();
      
      _logger.log('✅ Loaded fresh data: ${_allProducts.length} products');
      
    } catch (e) {
      _logger.error('❌ Failed to load fresh data', e);
      if (!_cacheService.hasProductsCache()) {
        _handleNetworkError('لا يوجد اتصال بالإنترنت');
      } else {
        errorMessage = 'يتم عرض نسخة محفوظة، التحديث غير متاح';
        notifyListeners();
      }
    } finally {
      isLoading = false;
      _isInitialLoad = false;
      notifyListeners();
    }
  }

  // ── Getters ───────────────────────────────────────────
  List<CategoryModel> get categories => _categories;
  List<ProductModel> get allProducts => _allProducts;

  bool get isInitialLoad => _isInitialLoad;
  bool get isShowingCachedData => _isShowingCachedData;
  
  String? get cacheMessage {
    if (_isShowingCachedData && hasNetworkError) {
      return '⚠️ وضع عدم الاتصال - يتم عرض نسخة محفوظة';
    }
    if (_isShowingCachedData && !hasNetworkError) {
      return '📱 يتم التحديث في الخلفية...';
    }
    return null;
  }

  List<ProductModel> get availableProducts {
    return _allProducts.where((p) => p.isAvailable && !p.isSold).toList();
  }

  List<ProductModel> get soldProducts {
    return _allProducts.where((p) => p.isSold).toList();
  }

  List<ProductModel> get filteredProducts {
    if (selectedCategory == ProductCategory.all) {
      return List.of(availableProducts);
    }
    return availableProducts.where((p) => p.category == selectedCategory).toList();
  }

  bool isProductFavoriteSync(String productId) =>
      _favoritesCache[productId] ?? false;
  
  bool isSellerFavoriteSync(String sellerId) =>
      _favoriteSellersCache[sellerId] ?? false;

  ProductModel? getProductById(String id) {
    try {
      final product = _allProducts.firstWhere((p) => p.id == id);
      if (product.isSold) return null;
      return product;
    } catch (_) {
      return null;
    }
  }

  ProductModel? getProductByIdIncludingSold(String id) {
    try {
      return _allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

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

  // ── Realtime Streams Setup ──────────────────────────────────────
  void _setupRealtimeStreams() {
    if (_isStreamsInitialized) return;
    _isStreamsInitialized = true;
    
    _logger.log('📡 Setting up real-time streams...');
    
    _productsStreamSubscription = _productRepository.watchAllProducts().listen(
      _onProductsUpdate,
      onError: (error) {
        _logger.error('❌ Products stream error', error);
        if (_allProducts.isEmpty) {
          _handleNetworkError('فشل تحميل المنتجات');
        }
      },
    );
    
    _favoritesStreamSubscription = _favoritesRepository.watchAllFavorites().listen(
      _onFavoritesUpdate,
      onError: _onFavoritesError,
    );
    
    _favoriteSellersStreamSubscription = _favoritesRepository.watchFavoriteSellerIds().listen(
      _onSellerFavoritesUpdate,
      onError: _onSellerFavoritesError,
    );
  }
  
  void _onProductsUpdate(List<ProductModel> products) {
    _logger.log('📦 Products stream update: ${products.length} products');
    
    _allProducts = _dedupProducts(products);
    _updateCategoryCache();
    
    _cacheService.cacheProducts(_allProducts);
    
    hasNetworkError = false;
    errorMessage = null;
    _isShowingCachedData = false;
    _isInitialLoad = false;
    notifyListeners();
  }
  
  void _onFavoritesUpdate(Map<String, bool> favorites) {
    _logger.log('❤️ Favorites stream update: ${favorites.length} favorites');
    _favoritesCache.clear();
    _favoritesCache.addAll(favorites);
    
    _cacheService.cacheFavorites(favorites);
    
    _notifyFavoriteListeners();
    _notifyFavoritesViewModels();
    notifyListeners();
  }
  
  void _onFavoritesError(dynamic error) {
    _logger.error('❌ Favorites stream error', error);
  }
  
  void _onSellerFavoritesUpdate(List<String> sellerIds) {
    _logger.log('👤 Seller favorites stream update: ${sellerIds.length} sellers');
    _favoriteSellersCache.clear();
    for (final sellerId in sellerIds) {
      _favoriteSellersCache[sellerId] = true;
    }
    _notifyFavoriteListeners();
    _notifyFavoritesViewModels();
    notifyListeners();
  }
  
  void _onSellerFavoritesError(dynamic error) {
    _logger.error('❌ Seller favorites stream error', error);
  }

  // ── Load Initial Data ──────────────────────────────────────────
  Future<void> loadInitialData() async {
    isLoading = true;
    hasNetworkError = false;
    notifyListeners();
    
    await Future.wait([
      loadCategories(),
      loadFavoriteSellers(),
    ]);
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _categoryRepository.getAllCategories();
      await _cacheService.cacheCategories(_categories);
      hasNetworkError = false;
    } on SocketException catch (e) {
      _logger.error('No internet connection', e);
      if (_cacheService.hasCategoriesCache()) {
        _categories = _cacheService.getCachedCategories();
        errorMessage = 'يتم عرض نسخة محفوظة من التصنيفات';
      } else {
        _handleNetworkError('لا يوجد اتصال بالإنترنت');
        _categories = [];
      }
    } catch (e) {
      _logger.error('Failed to load categories', e);
      _handleNetworkError('فشل تحميل الفئات');
      _categories = [];
    }
    notifyListeners();
  }

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

  // ── Category Management ─────────────────────────────────────────
  void setSelectedCategory(ProductCategory category) {
    if (selectedCategory == category) return;
    
    // ✅ إلغاء الاشتراك القديم أولاً
    _productsStreamSubscription?.cancel();
    _productsStreamSubscription = null;
    
    selectedCategory = category;
    
    if (_categoryCache.containsKey(category)) {
      _allProducts = _categoryCache[category]!;
      notifyListeners();
    }
    
    isCategoryChanging = true;
    notifyListeners();
    
    // ✅ إنشاء اشتراك جديد حسب الفئة
    if (category == ProductCategory.all) {
      _productsStreamSubscription = _productRepository.watchAllProducts().listen(
        (products) {
          _onProductsUpdate(products);
          isCategoryChanging = false;
          notifyListeners();
        },
        onError: (error) {
          _logger.error('❌ Products stream error', error);
          isCategoryChanging = false;
          notifyListeners();
          _handleNetworkError('فشل تحميل المنتجات');
        },
      );
    } else {
      _productsStreamSubscription = _productRepository.watchProductsByCategory(category.name).listen(
        (products) {
          _logger.log('📦 Category stream update: ${category.name} -> ${products.length} products');
          _allProducts = _dedupProducts(products);
          _categoryCache[category] = _allProducts;
          hasNetworkError = false;
          errorMessage = null;
          isCategoryChanging = false;
          notifyListeners();
        },
        onError: (error) {
          _logger.error('❌ Category stream error: ${category.name}', error);
          isCategoryChanging = false;
          if (_categoryCache.containsKey(category)) {
            _allProducts = _categoryCache[category]!;
            notifyListeners();
          } else {
            _handleNetworkError('فشل تحميل المنتجات');
          }
        },
      );
    }
  }

  // ── Favorites (Products) ─────────────────────────────────────────
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

    // ✅ تحديث الحالة المحلية أولاً (Optimistic Update)
    _favoritesCache[productId] = newStatus;
    await _cacheService.updateFavoriteInCache(productId, newStatus);
    notifyListeners();
    _notifyFavoriteListeners();
    _notifyFavoritesViewModels();

    // ✅ معالجة الخطأ بشكل صحيح مع try-catch
    try {
      if (newStatus) {
        await _favoritesRepository.addToFavorites(product);
      } else {
        await _favoritesRepository.removeFromFavorites(productId);
      }
      _logger.log('✅ Favorite toggled successfully: $productId -> $newStatus');
    } catch (e) {
      // ✅ استعادة الحالة السابقة عند الخطأ
      _logger.error('Failed to toggle favorite on server', e);
      _favoritesCache[productId] = oldStatus;
      await _cacheService.updateFavoriteInCache(productId, oldStatus);
      notifyListeners();
      _notifyFavoriteListeners();
      _notifyFavoritesViewModels();
      return false;
    } finally {
      _pendingFavUpdates.remove(productId);
    }
    
    return true;
  }

  // ── Favorites (Sellers) ─────────────────────────────────────────
  Future<bool> toggleFavoriteSeller(String sellerId) async {
    if (sellerId.isEmpty) return false;
    if (_pendingFavSellerUpdates.contains(sellerId)) return false;

    _pendingFavSellerUpdates.add(sellerId);
    final newStatus = !isSellerFavoriteSync(sellerId);
    final oldStatus = !newStatus;

    _logger.log('🔄 Toggling seller favorite: $sellerId, newStatus: $newStatus');

    // ✅ تحديث محلي
    if (newStatus) {
      _favoriteSellersCache[sellerId] = true;
    } else {
      _favoriteSellersCache.remove(sellerId);
    }
    
    notifyListeners();
    _notifyFavoriteListeners();
    _notifyFavoritesViewModels();

    // ✅ معالجة الخطأ بشكل صحيح مع try-catch
    try {
      if (newStatus) {
        await _favoritesRepository.addSellerToFavorites(sellerId);
      } else {
        await _favoritesRepository.removeSellerFromFavorites(sellerId);
      }
      _logger.log('✅ Seller favorite toggled successfully: $sellerId -> $newStatus');
    } catch (e) {
      // ✅ استعادة الحالة
      _logger.error('Failed to toggle seller favorite on server', e);
      if (oldStatus) {
        _favoriteSellersCache[sellerId] = true;
      } else {
        _favoriteSellersCache.remove(sellerId);
      }
      notifyListeners();
      _notifyFavoriteListeners();
      _notifyFavoritesViewModels();
      return false;
    } finally {
      _pendingFavSellerUpdates.remove(sellerId);
    }
    
    return true;
  }

  Future<void> refreshFavoritesCache() async {
    _logger.log('🔄 Refreshing favorites cache...');
    
    _favoritesCache.clear();
    for (final product in _allProducts) {
      final isFav = await _favoritesRepository.isFavorite(product.id);
      _favoritesCache[product.id] = isFav;
    }
    
    await _cacheService.cacheFavorites(_favoritesCache);
    await loadFavoriteSellers();
    
    _notifyFavoriteListeners();
    _notifyFavoritesViewModels();
    notifyListeners();
    
    _logger.log('✅ Favorites cache refreshed: ${_favoritesCache.length} products, ${_favoriteSellersCache.length} sellers');
  }

  Future<void> syncFavoritesFromFirebase() async {
    _logger.log('🔄 Syncing favorites from Firebase...');
    await refreshFavoritesCache();
  }

  // ── User Management (Login/Logout) ──────────────────────────────────
  
  Future<void> onUserChanged() async {
    _logger.log('👤 User changed, reinitializing HomeViewModel...');
    
    // ✅ إلغاء كل الاشتراكات أولاً
    _disposeStreams();
    
    // ✅ إعادة التعيين
    _isStreamsInitialized = false;
    _isInitializing = false;
    clearAllData();
    selectedCategory = ProductCategory.all;
    
    // ✅ إعادة التهيئة
    await _initialize();
    
    _logger.log('✅ HomeViewModel reinitialized successfully');
  }
  
  void _disposeStreams() {
    _productsStreamSubscription?.cancel();
    _productsStreamSubscription = null;
    _favoritesStreamSubscription?.cancel();
    _favoritesStreamSubscription = null;
    _favoriteSellersStreamSubscription?.cancel();
    _favoriteSellersStreamSubscription = null;
  }

  void clearAllData() {
    _logger.log('🗑️ Clearing all HomeViewModel data...');
    
    _allProducts.clear();
    _categories.clear();
    _favoritesCache.clear();
    _favoriteSellersCache.clear();
    _categoryCache.clear();
    
    isLoading = false;
    hasNetworkError = false;
    errorMessage = null;
    _hasProductsLoaded = false;
    _isInitialLoad = true;
    _isShowingCachedData = false;
    
    notifyListeners();
    _notifyFavoriteListeners();
    _notifyFavoritesViewModels();
  }

  // ── Refresh Methods ───────────────────────────────────────────
  Future<void> refreshProducts() async {
    _logger.log('🔄 Refreshing products...');
    isCategoryChanging = true;
    notifyListeners();
    
    _productsStreamSubscription?.cancel();
    _productsStreamSubscription = null;
    
    if (selectedCategory == ProductCategory.all) {
      _productsStreamSubscription = _productRepository.watchAllProducts().listen(
        (products) {
          _onProductsUpdate(products);
          isCategoryChanging = false;
          notifyListeners();
        },
        onError: (error) {
          _logger.error('❌ Refresh error', error);
          isCategoryChanging = false;
          notifyListeners();
          _handleNetworkError('فشل تحديث المنتجات');
        },
      );
    } else {
      _productsStreamSubscription = _productRepository.watchProductsByCategory(selectedCategory.name).listen(
        (products) {
          _allProducts = _dedupProducts(products);
          _categoryCache[selectedCategory] = _allProducts;
          hasNetworkError = false;
          errorMessage = null;
          isCategoryChanging = false;
          notifyListeners();
        },
        onError: (error) {
          _logger.error('❌ Refresh error', error);
          isCategoryChanging = false;
          notifyListeners();
          _handleNetworkError('فشل تحديث المنتجات');
        },
      );
    }
  }

  Future<void> refreshCategories() => loadCategories();

  void clearCache() {
    _categoryCache.clear();
    _favoritesCache.clear();
    _favoriteSellersCache.clear();
  }

  // ── Product Mutations ────────────────────────────────────────────
  void addNewProduct(ProductModel product) {
    if (product.id.isEmpty) return;
    if (_allProducts.any((p) => p.id == product.id)) return;

    _allProducts.insert(0, product);
    _favoritesCache[product.id] = false;
    _cacheService.updateFavoriteInCache(product.id, false);

    _categoryCache
        .putIfAbsent(ProductCategory.all, () => [])
        .insert(0, product);
    _categoryCache.putIfAbsent(product.category, () => []).insert(0, product);
    
    _cacheService.updateProductInCache(product);

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
      _cacheService.removeProductFromCache(productId);
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
    _cacheService.updateProductInCache(updated);
    notifyListeners();
  }

  void clearAllProducts() {
    _allProducts.clear();
    _favoritesCache.clear();
    _favoriteSellersCache.clear();
    _categoryCache.clear();
    _cacheService.clearProductsCache();
    notifyListeners();
    _notifyFavoriteListeners();
    _notifyFavoritesViewModels();
  }

  // ── Private Helpers ──────────────────────────────────────────────
  void _handleNetworkError(String message) {
    hasNetworkError = true;
    errorMessage = message;
    notifyListeners();
  }

  // ── Cleanup ──────────────────────────────────────────────────────
  @override
  void dispose() {
    _disposeStreams();
    _isStreamsInitialized = false;
    super.dispose();
  }
}