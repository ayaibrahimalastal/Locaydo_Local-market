// lib/features/favorites/presentation/viewmodels/favorites_viewmodel.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/enums/favorites_enums.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/favorites/data/models/favorites_model.dart';
import 'package:locaydo_app/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/main.dart';

class FavoritesViewModel extends ChangeNotifier {
  final Logger _logger;
  final FavoritesRepositoryImpl _repository;
  HomeViewModel? _homeViewModel;

  FavoritesTab activeTab = FavoritesTab.products;

  List<FavoriteProduct> _favoriteProducts = [];
  List<FavoriteSeller> _favoriteSellers = [];

  bool isLoading = false;
  bool isInitialLoad = true;
  String? errorMessage;
  
  final Set<String> _pendingUpdates = {};
  
  // Stream subscriptions for real-time updates
  StreamSubscription<Map<String, bool>>? _favoritesStreamSubscription;
  StreamSubscription<List<String>>? _favoriteSellersStreamSubscription;
  
  // Cache for product existence
  final Map<String, bool> _productExistsCache = {};

  List<FavoriteProduct> get favoriteProducts => _favoriteProducts;
  List<FavoriteSeller> get favoriteSellers => _favoriteSellers;

  FavoritesViewModel({
    required Logger logger,
    required FavoritesRepositoryImpl repository,
    HomeViewModel? homeViewModel,
  })  : _logger = logger,
        _repository = repository,
        _homeViewModel = homeViewModel {
    
    if (_homeViewModel != null) {
      _homeViewModel!.addFavoriteListener(_onHomeViewModelFavoriteChanged);
      _homeViewModel!.addFavoritesViewModelListener(_onHomeViewModelFavoriteChanged);
      _homeViewModel!.addListener(_onHomeViewModelGeneralChanged);
    }
    
    _initialize();
  }
  
  Future<void> _initialize() async {
    isLoading = true;
    isInitialLoad = true;
    notifyListeners();
    
    await Future.wait([
      loadFavoriteProducts(),
      loadFavoriteSellers(),
    ]);
    
    isLoading = false;
    isInitialLoad = false;
    notifyListeners();
    
    _setupRealtimeStreams();
  }
  
  void _setupRealtimeStreams() {
    _logger.log('📡 Setting up real-time favorites streams...');
    
    _favoritesStreamSubscription = _repository.watchAllFavorites().listen(
      _syncFavoritesFromStream,
      onError: (error) {
        _logger.error('❌ Favorites stream error', error);
      },
    );
    
    _favoriteSellersStreamSubscription = _repository.watchFavoriteSellerIds().listen(
      (sellerIds) async {
        _logger.log('👤 Real-time sellers update: ${sellerIds.length} sellers');
        await _syncSellersFromStream(sellerIds);
      },
      onError: (error) {
        _logger.error('❌ Seller favorites stream error', error);
      },
    );
  }
  
  Future<void> _syncFavoritesFromStream(Map<String, bool> favoritesMap) async {
    if (_pendingUpdates.isNotEmpty) {
      _logger.log('⏳ Skipping stream sync due to pending updates');
      return;
    }
    
    final newFavoriteProducts = <FavoriteProduct>[];
    
    for (final productId in favoritesMap.keys) {
      final productExists = await _checkProductExists(productId);
      if (!productExists) {
        _logger.log('🗑️ Product $productId no longer exists, removing from favorites');
        await _repository.removeFromFavorites(productId);
        continue;
      }
      
      final product = await _getProductDetailsIncludingSold(productId);
      if (product != null) {
        newFavoriteProducts.add(FavoriteProduct(
          id: product.id,
          title: product.title,
          price: product.price,
          currency: product.currency,
          location: product.location,
          imageUrl: product.imageUrl,
          paymentMethods: product.paymentMethods,
          isFavorite: true,
          isSold: product.isSold,
        ));
      }
    }
    
    if (!_areFavoriteListsEqual(_favoriteProducts, newFavoriteProducts)) {
      _favoriteProducts = newFavoriteProducts;
      _logger.log('✅ Synced ${_favoriteProducts.length} favorites from stream');
      notifyListeners();
    }
  }
  
  Future<void> _syncSellersFromStream(List<String> sellerIds) async {
    if (_pendingUpdates.contains('seller_batch')) {
      _logger.log('⏳ Skipping seller stream sync due to pending updates');
      return;
    }
    
    final newSellers = <FavoriteSeller>[];
    
    for (final sellerId in sellerIds) {
      final seller = await _getSellerDetails(sellerId);
      if (seller != null) {
        newSellers.add(seller);
      } else {
        _logger.log('🗑️ Seller $sellerId not found, cleaning up');
        await _repository.removeSellerFromFavorites(sellerId);
      }
    }
    
    if (!_areSellerListsEqual(_favoriteSellers, newSellers)) {
      _favoriteSellers = newSellers;
      _logger.log('✅ Synced ${_favoriteSellers.length} sellers from stream');
      notifyListeners();
    }
  }
  
  Future<bool> _checkProductExists(String productId) async {
    if (_productExistsCache.containsKey(productId)) {
      return _productExistsCache[productId]!;
    }
    
    final exists = await _repository.isProductExists(productId);
    _productExistsCache[productId] = exists;
    return exists;
  }
  
  Future<ProductModel?> _getProductDetailsIncludingSold(String productId) async {
    if (_homeViewModel != null) {
      final product = _homeViewModel!.getProductByIdIncludingSold(productId);
      if (product != null) return product;
    }
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      
      if (doc.exists) {
        return ProductModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      _logger.error('Failed to get product details: $productId', e);
    }
    
    return null;
  }
  
  Future<FavoriteSeller?> _getSellerDetails(String sellerId) async {
    try {
      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .get();
      
      if (sellerDoc.exists) {
        final data = sellerDoc.data()!;
        
        final productsSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: data['userId'])
            .get();
        
        return FavoriteSeller(
          id: sellerId,
          name: data['name'] ?? '',
          rating: (data['rating'] ?? 0).toDouble(),
          totalRatings: data['totalRatings'] ?? 0,
          imageUrl: data['avatarUrl'],
          productCount: productsSnapshot.docs.length,
          isFollowed: true,
          imageVersion: data['imageVersion'] ?? 1,
        );
      }
    } catch (e) {
      _logger.error('Failed to get seller details: $sellerId', e);
    }
    
    return null;
  }

  void _onHomeViewModelFavoriteChanged() {
    _logger.log('🔄 HomeViewModel favorite changed, refreshing...');
    _syncFavoritesFromHomeViewModel();
  }
  
  void _onHomeViewModelGeneralChanged() {
    _logger.log('🔄 HomeViewModel general change detected');
    _syncFavoritesFromHomeViewModel();
  }
  
  Future<void> _syncFavoritesFromHomeViewModel() async {
    if (_homeViewModel == null || _pendingUpdates.isNotEmpty) return;
    
    final allProducts = _homeViewModel!.allProducts;
    final newFavoriteProducts = <FavoriteProduct>[];
    
    for (final product in allProducts) {
      if (_pendingUpdates.contains(product.id)) {
        continue;
      }
      
      if (_homeViewModel!.isProductFavoriteSync(product.id)) {
        newFavoriteProducts.add(FavoriteProduct(
          id: product.id,
          title: product.title,
          price: product.price,
          currency: product.currency,
          location: product.location,
          imageUrl: product.imageUrl,
          paymentMethods: product.paymentMethods,
          isFavorite: true,
          isSold: product.isSold,
        ));
      }
    }
    
    if (!_areFavoriteListsEqual(_favoriteProducts, newFavoriteProducts)) {
      _favoriteProducts = newFavoriteProducts;
      notifyListeners();
      _logger.log('✅ Synced ${_favoriteProducts.length} favorites from HomeViewModel');
    }
  }

  Future<void> loadFavoriteProducts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.log('⚠️ No user logged in!');
        errorMessage = 'الرجاء تسجيل الدخول أولاً';
        notifyListeners();
        return;
      }
      
      _logger.log('👤 Loading favorite products for user: ${user.email}');
      _favoriteProducts = await _repository.getFavoriteProducts();
      _logger.log('✅ Loaded ${_favoriteProducts.length} favorite products');
      
      await _validateFavoriteProducts();
      
    } catch (e) {
      errorMessage = 'فشل تحميل المفضلة';
      _logger.error('❌ Failed to load favorites', e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadFavoriteSellers() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.log('⚠️ No user logged in');
        return;
      }
      
      _logger.log('📦 Loading favorite sellers for user: ${user.uid}');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favoriteSellers')
          .orderBy('addedAt', descending: true)
          .get();
      
      final sellers = <FavoriteSeller>[];
      
      for (final doc in snapshot.docs) {
        final sellerId = doc.id;
        final seller = await _getSellerDetails(sellerId);
        
        if (seller != null) {
          sellers.add(seller);
        } else {
          _logger.log('🗑️ Cleaning invalid favorite seller: $sellerId');
          await doc.reference.delete();
        }
      }
      
      _favoriteSellers = sellers;
      _logger.log('✅ Loaded ${_favoriteSellers.length} favorite sellers');
      notifyListeners();
      
    } catch (e) {
      _logger.error('❌ Failed to load favorite sellers', e);
    }
  }
  
  Future<void> _validateFavoriteProducts() async {
    final List<FavoriteProduct> validProducts = [];
    
    for (final product in _favoriteProducts) {
      final productExists = await _repository.isProductExists(product.id);
      if (productExists) {
        validProducts.add(product);
      } else {
        _logger.log('🗑️ Removing invalid favorite: ${product.title}');
        await _repository.removeFromFavorites(product.id);
      }
    }
    
    if (validProducts.length != _favoriteProducts.length) {
      _favoriteProducts = validProducts;
      _logger.log('✅ Validated favorites: ${_favoriteProducts.length} valid products');
      notifyListeners();
    }
  }

  Future<void> toggleProductFavoriteFromList(String productId) async {
    final productIndex = _favoriteProducts.indexWhere((p) => p.id == productId);
    if (productIndex == -1) return;
    
    if (_pendingUpdates.contains(productId)) {
      _logger.log('⚠️ Update already pending for $productId, skipping');
      return;
    }
    _pendingUpdates.add(productId);
    
    final product = _favoriteProducts[productIndex];
    
    _logger.log('🗑️ Removing product from favorites UI: ${product.title}');
    
    _favoriteProducts.removeAt(productIndex);
    notifyListeners();
    
    unawaited(
      _repository.removeFromFavorites(productId).then((_) {
        _logger.log('✅ Product removed from favorites server: ${product.title}');
        _pendingUpdates.remove(productId);
        _productExistsCache.remove(productId);
      }).catchError((e) {
        _logger.error('❌ Failed to remove from favorites server, reverting...', e);
        _favoriteProducts.insert(productIndex, product);
        notifyListeners();
        errorMessage = 'فشل تحديث المفضلة، حاول مرة أخرى';
        _pendingUpdates.remove(productId);
      })
    );
    
    if (_homeViewModel != null) {
      unawaited(_homeViewModel!.refreshFavoritesCache());
    }
  }

  Future<bool> addProductToFavorites(ProductModel product) async {
    if (_pendingUpdates.contains(product.id)) {
      _logger.log('⚠️ Update already pending for ${product.id}, skipping');
      return false;
    }
    _pendingUpdates.add(product.id);
    
    _logger.log('❤️ Adding product to favorites UI: ${product.title}');
    
    final newFavorite = FavoriteProduct(
      id: product.id,
      title: product.title,
      price: product.price,
      currency: product.currency,
      location: product.location,
      imageUrl: product.imageUrl,
      paymentMethods: product.paymentMethods,
      isFavorite: true,
      isSold: product.isSold,
    );
    
    _favoriteProducts.insert(0, newFavorite);
    notifyListeners();
    
    unawaited(
      _repository.addToFavorites(product).then((_) {
        _logger.log('✅ Product added to favorites server: ${product.title}');
        _pendingUpdates.remove(product.id);
        _productExistsCache[product.id] = true;
      }).catchError((e) {
        _logger.error('❌ Failed to add to favorites server, reverting...', e);
        _favoriteProducts.removeWhere((p) => p.id == product.id);
        notifyListeners();
        errorMessage = 'فشل إضافة المنتج إلى المفضلة';
        _pendingUpdates.remove(product.id);
      })
    );
    
    if (_homeViewModel != null) {
      unawaited(_homeViewModel!.refreshFavoritesCache());
    }
    
    return true;
  }

  Future<void> toggleSellerFollow(String sellerId) async {
    if (_pendingUpdates.contains('seller_$sellerId')) {
      _logger.log('⚠️ Update already pending for seller $sellerId, skipping');
      return;
    }
    _pendingUpdates.add('seller_$sellerId');
    
    try {
      final isCurrentlyFollowed = _favoriteSellers.any((s) => s.id == sellerId);
      
      if (isCurrentlyFollowed) {
        _favoriteSellers.removeWhere((s) => s.id == sellerId);
        _logger.log('🗑️ Seller unfollowed from UI: $sellerId');
      } else {
        final seller = await _getSellerDetails(sellerId);
        if (seller != null) {
          _favoriteSellers.insert(0, seller);
          _logger.log('❤️ Seller followed from UI: $sellerId');
        } else {
          _logger.log('⚠️ Seller not found: $sellerId');
          _pendingUpdates.remove('seller_$sellerId');
          return;
        }
      }
      
      notifyListeners();
      
      unawaited(
        (isCurrentlyFollowed
            ? _repository.removeSellerFromFavorites(sellerId)
            : _repository.addSellerToFavorites(sellerId))
            .then((_) {
              _logger.log('✅ Seller favorite updated on server: $sellerId');
              _pendingUpdates.remove('seller_$sellerId');
            })
            .catchError((e) {
              _logger.error('❌ Failed to update seller favorite on server, reverting...', e);
              if (isCurrentlyFollowed) {
                _loadSellerAndAddToFavorites(sellerId);
              } else {
                _favoriteSellers.removeWhere((s) => s.id == sellerId);
              }
              notifyListeners();
              _pendingUpdates.remove('seller_$sellerId');
              errorMessage = 'فشل تحديث حالة المتابعة';
            })
      );
      
      if (_homeViewModel != null) {
        unawaited(_homeViewModel!.refreshFavoritesCache());
      }
      
    } catch (e) {
      _logger.error('❌ Failed to toggle seller follow', e);
      errorMessage = 'فشل تحديث حالة المتابعة';
      _pendingUpdates.remove('seller_$sellerId');
    }
  }
  
  Future<void> _loadSellerAndAddToFavorites(String sellerId) async {
    final seller = await _getSellerDetails(sellerId);
    if (seller != null && !_favoriteSellers.any((s) => s.id == sellerId)) {
      _favoriteSellers.insert(0, seller);
      _logger.log('🔄 Seller re-added to favorites: $sellerId');
    }
  }

  void setActiveTab(FavoritesTab tab) {
    if (activeTab != tab) {
      activeTab = tab;
      _logger.log('Tab → ${tab.label}');
      notifyListeners();
    }
  }

  void onProductTap(FavoriteProduct product) {
    _logger.log('Product tapped: ${product.title}');
  }

  void onSellerTap(FavoriteSeller seller) {
    _logger.log('Seller tapped: ${seller.name}');
    Navigator.pushNamed(
      navigatorKey.currentContext!,
      AppRoutes.sellerView,
      arguments: seller.id,
    );
  }

  Future<void> refreshFavorites() async {
    _logger.log('🔄 Manual refresh requested');
    _productExistsCache.clear();
    await Future.wait([
      loadFavoriteProducts(),
      loadFavoriteSellers(),
    ]);
  }
  
  // ✅ ✅ ✅ دوال إدارة المستخدم (تسجيل الدخول/الخروج) ✅ ✅ ✅
  
  /// ✅ إعادة تهيئة عند تغيير المستخدم
  Future<void> onUserChanged() async {
    _logger.log('👤 User changed, reinitializing FavoritesViewModel...');
    
    // إلغاء الاشتراك من الـ Streams القديمة
    _favoritesStreamSubscription?.cancel();
    _favoriteSellersStreamSubscription?.cancel();
    
    // مسح البيانات
    _favoriteProducts.clear();
    _favoriteSellers.clear();
    _productExistsCache.clear();
    _pendingUpdates.clear();
    
    // إعادة تعيين المتغيرات
    activeTab = FavoritesTab.products;
    isLoading = true;
    isInitialLoad = true;
    errorMessage = null;
    
    notifyListeners();
    
    // إعادة تحميل البيانات
    await _initialize();
    
    _logger.log('✅ FavoritesViewModel reinitialized successfully');
  }

  /// ✅ تنظيف البيانات (عند تسجيل الخروج)
  void clearAllData() {
    _logger.log('🗑️ Clearing all FavoritesViewModel data...');
    
    _favoriteProducts.clear();
    _favoriteSellers.clear();
    _productExistsCache.clear();
    _pendingUpdates.clear();
    
    isLoading = false;
    isInitialLoad = false;
    errorMessage = null;
    
    notifyListeners();
  }
  
  bool _areFavoriteListsEqual(List<FavoriteProduct> a, List<FavoriteProduct> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
  
  bool _areSellerListsEqual(List<FavoriteSeller> a, List<FavoriteSeller> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
  
  @override
  void dispose() {
    _favoritesStreamSubscription?.cancel();
    _favoriteSellersStreamSubscription?.cancel();
    
    if (_homeViewModel != null) {
      _homeViewModel!.removeFavoriteListener(_onHomeViewModelFavoriteChanged);
      _homeViewModel!.removeFavoritesViewModelListener(_onHomeViewModelFavoriteChanged);
      _homeViewModel!.removeListener(_onHomeViewModelGeneralChanged);
    }
    
    super.dispose();
  }
}