import 'package:hive_flutter/hive_flutter.dart';
import 'package:locaydo_app/features/categories/data/models/category_model.dart';
import 'package:locaydo_app/features/categories/data/models/hive_category_model.dart' as hive;
import 'package:locaydo_app/features/products/data/models/hive_product_model.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';

class HiveCacheService {
  // ✅ أسماء الثوابت
  static const String _productsBoxName = 'products_cache';
  static const String _categoriesBoxName = 'categories_cache';
  static const String _favoritesBoxName = 'favorites_cache';
  static const String _metadataBoxName = 'metadata';
  
  static const String _lastUpdateKey = 'last_products_update';
  static const String _cacheVersionKey = 'cache_version';
  static const int _currentCacheVersion = 1;
  static const int _cacheDurationMinutes = 30;
  
  // ✅ المتغيرات
  late Box<HiveProductModel> _productsBox;
  late Box<hive.HiveCategoryModel> _categoriesBox;
  late Box<bool> _favoritesBox;
  late Box<String> _metadataBox;
  
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    await Hive.initFlutter();
    
    // تسجيل الـ Adapters
    Hive.registerAdapter(HiveProductModelAdapter());
    Hive.registerAdapter(hive.HiveCategoryModelAdapter());
    
    // فتح الصناديق
    _productsBox = await Hive.openBox<HiveProductModel>(_productsBoxName);
    _categoriesBox = await Hive.openBox<hive.HiveCategoryModel>(_categoriesBoxName);
    _favoritesBox = await Hive.openBox<bool>(_favoritesBoxName);
    _metadataBox = await Hive.openBox<String>(_metadataBoxName);
    
    _isInitialized = true;
    
    await _checkCacheVersion();
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('HiveCacheService not initialized. Call init() first.');
    }
  }

  Future<void> _checkCacheVersion() async {
    _ensureInitialized();
    final savedVersion = _metadataBox.get(_cacheVersionKey);
    if (savedVersion != _currentCacheVersion.toString()) {
      await clearAllCache();
      await _metadataBox.put(_cacheVersionKey, _currentCacheVersion.toString());
    }
  }

  // ─── Products Cache ──────────────────────────────────────────
  
  Future<void> cacheProducts(List<ProductModel> products) async {
    _ensureInitialized();
    await _productsBox.clear();
    for (final product in products) {
      await _productsBox.put(product.id, HiveProductModel.fromProduct(product));
    }
    await _metadataBox.put(_lastUpdateKey, DateTime.now().toIso8601String());
  }

  List<ProductModel> getCachedProducts() {
    _ensureInitialized();
    return _productsBox.values
        .map((hiveProduct) => hiveProduct.toProductModel())
        .toList();
  }

  ProductModel? getCachedProductById(String id) {
    _ensureInitialized();
    final hiveProduct = _productsBox.get(id);
    return hiveProduct?.toProductModel();
  }

  bool hasProductsCache() {
    _ensureInitialized();
    return _productsBox.isNotEmpty;
  }

  int getCachedProductsCount() {
    _ensureInitialized();
    return _productsBox.length;
  }

  bool isProductsCacheValid() {
    _ensureInitialized();
    final lastUpdateStr = _metadataBox.get(_lastUpdateKey);
    if (lastUpdateStr == null) return false;
    
    final lastUpdate = DateTime.parse(lastUpdateStr);
    final difference = DateTime.now().difference(lastUpdate);
    return difference.inMinutes < _cacheDurationMinutes;
  }

  Future<void> updateProductInCache(ProductModel product) async {
    _ensureInitialized();
    await _productsBox.put(product.id, HiveProductModel.fromProduct(product));
  }

  Future<void> removeProductFromCache(String productId) async {
    _ensureInitialized();
    await _productsBox.delete(productId);
  }

  // ─── Categories Cache ──────────────────────────────────────────
  
  Future<void> cacheCategories(List<CategoryModel> categories) async {
    _ensureInitialized();
    await _categoriesBox.clear();
    for (final category in categories) {
      // ✅ تحويل CategoryModel الأصلي إلى HiveCategoryModel
      await _categoriesBox.put(category.id, hive.HiveCategoryModel.fromCategory(category));
    }
  }

  List<CategoryModel> getCachedCategories() {
    _ensureInitialized();
    // ✅ تحويل HiveCategoryModel إلى CategoryModel الأصلي
    return _categoriesBox.values
        .map((hiveCategory) => hiveCategory.toCategoryModel())
        .toList();
  }

  bool hasCategoriesCache() {
    _ensureInitialized();
    return _categoriesBox.isNotEmpty;
  }

  // ─── Favorites Cache ──────────────────────────────────────────
  
  Future<void> cacheFavorites(Map<String, bool> favorites) async {
    _ensureInitialized();
    await _favoritesBox.clear();
    for (final entry in favorites.entries) {
      await _favoritesBox.put(entry.key, entry.value);
    }
  }

  Map<String, bool> getCachedFavorites() {
    _ensureInitialized();
    final Map<String, bool> favorites = {};
    for (final key in _favoritesBox.keys) {
      favorites[key as String] = _favoritesBox.get(key) ?? false;
    }
    return favorites;
  }

  Future<void> updateFavoriteInCache(String productId, bool isFavorite) async {
    _ensureInitialized();
    await _favoritesBox.put(productId, isFavorite);
  }

  bool isProductFavoriteFromCache(String productId) {
    _ensureInitialized();
    return _favoritesBox.get(productId) ?? false;
  }

  Future<void> clearFavoritesCache() async {
    _ensureInitialized();
    await _favoritesBox.clear();
  }

  // ─── Clear Cache ──────────────────────────────────────────────
  
  Future<void> clearProductsCache() async {
    _ensureInitialized();
    await _productsBox.clear();
    await _metadataBox.delete(_lastUpdateKey);
  }

  Future<void> clearCategoriesCache() async {
    _ensureInitialized();
    await _categoriesBox.clear();
  }

  Future<void> clearAllCache() async {
    _ensureInitialized();
    await _productsBox.clear();
    await _categoriesBox.clear();
    await _favoritesBox.clear();
    await _metadataBox.clear();
  }
  
  // ─── Utility ─────────────────────────────────────────────────
  
  Future<void> close() async {
    if (_isInitialized) {
      await _productsBox.close();
      await _categoriesBox.close();
      await _favoritesBox.close();
      await _metadataBox.close();
      _isInitialized = false;
    }
  }
}