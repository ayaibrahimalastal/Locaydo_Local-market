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
  String? errorMessage;
  
  final Set<String> _pendingUpdates = {};

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
      _homeViewModel!.addFavoriteListener(() {
        _logger.log('🔄 Favorite changed in HomeViewModel, syncing...');
        _syncFavoriteFromHomeViewModel();
      });
      
      _homeViewModel!.addFavoritesViewModelListener(() {
        _logger.log('🔄 Immediate favorite update from HomeViewModel');
        _syncFavoriteFromHomeViewModel();
      });
      
      _homeViewModel!.addListener(_onHomeViewModelChanged);
    }
    
    loadFavoriteProducts();
    loadFavoriteSellers();
  }
  
  void _onHomeViewModelChanged() {
    _logger.log('🔄 HomeViewModel general change detected, refreshing favorites...');
    _syncFavoriteFromHomeViewModel();
  }
  
  Future<void> _syncFavoriteFromHomeViewModel() async {
    if (_homeViewModel == null) return;
    
    final allProducts = _homeViewModel!.allProducts;
    final newFavoriteProducts = <FavoriteProduct>[];
    
    for (final product in allProducts) {
      if (_pendingUpdates.contains(product.id)) {
        _logger.log('⚠️ Skipping sync for product with pending update: ${product.id}');
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
        ));
      }
    }
    
    if (!_areFavoriteListsEqual(_favoriteProducts, newFavoriteProducts)) {
      _favoriteProducts = newFavoriteProducts;
      notifyListeners();
      _logger.log('✅ Synced ${_favoriteProducts.length} favorites from HomeViewModel');
    }
  }
  
  bool _areFavoriteListsEqual(List<FavoriteProduct> a, List<FavoriteProduct> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  /// ✅ تحميل المنتجات المفضلة
  Future<void> loadFavoriteProducts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.log('⚠️ No user logged in!');
        errorMessage = 'الرجاء تسجيل الدخول أولاً';
        isLoading = false;
        notifyListeners();
        return;
      }
      
      _logger.log('👤 User: ${user.email}');
      _favoriteProducts = await _repository.getFavoriteProducts();
      _logger.log('✅ Loaded ${_favoriteProducts.length} favorite products');
      
      await _validateFavoriteProducts();
      
    } catch (e) {
      errorMessage = 'فشل تحميل المفضلة';
      _logger.error('❌ Failed to load favorites', e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ تحميل البائعين المفضلين (مع جلب أحدث البيانات من sellers collection)
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
        final data = doc.data() as Map<String, dynamic>;
        final sellerId = doc.id;
        
        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(sellerId)
            .get();
        
        if (sellerDoc.exists) {
          final sellerData = sellerDoc.data()!;
          sellers.add(FavoriteSeller(
            id: sellerId,
            name: sellerData['name'] ?? data['name'] ?? '',
            rating: (sellerData['rating'] ?? data['rating'] ?? 0).toDouble(),
            totalRatings: sellerData['totalRatings'] ?? data['totalRatings'] ?? 0,
            imageUrl: sellerData['avatarUrl'] ?? data['imageUrl'],
            productCount: sellerData['productCount'] ?? data['productCount'] ?? 0,
            isFollowed: true,
            imageVersion: sellerData['imageVersion'] ?? data['imageVersion'] ?? 0,
          ));
        } else {
          _logger.log('🗑️ Cleaning invalid favorite seller: $sellerId');
          await doc.reference.delete();
        }
      }
      
      _favoriteSellers = sellers;
      _logger.log('✅ Loaded ${_favoriteSellers.length} favorite sellers (with latest data)');
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
        _logger.log('🗑️ Removing invalid favorite: ${product.title} (ID: ${product.id})');
        await _repository.removeFromFavorites(product.id);
      }
    }
    
    if (validProducts.length != _favoriteProducts.length) {
      _favoriteProducts = validProducts;
      _logger.log('✅ Validated favorites: ${_favoriteProducts.length} valid products');
      notifyListeners();
    }
  }

  /// ✅ إزالة منتج من المفضلة
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

  /// ✅ إضافة منتج إلى المفضلة
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
    );
    
    _favoriteProducts.insert(0, newFavorite);
    notifyListeners();
    
    unawaited(
      _repository.addToFavorites(product).then((_) {
        _logger.log('✅ Product added to favorites server: ${product.title}');
        _pendingUpdates.remove(product.id);
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

  /// ✅ متابعة/إلغاء متابعة بائع مع تحديث HomeViewModel
  Future<void> toggleSellerFollow(String sellerId) async {
    if (_pendingUpdates.contains('seller_$sellerId')) {
      _logger.log('⚠️ Update already pending for seller $sellerId, skipping');
      return;
    }
    _pendingUpdates.add('seller_$sellerId');
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.log('⚠️ No user logged in');
        _pendingUpdates.remove('seller_$sellerId');
        return;
      }
      
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favoriteSellers')
          .doc(sellerId);
      
      final doc = await docRef.get();
      final isCurrentlyFollowed = doc.exists;
      
      // ✅ تحديث الواجهة فوراً
      if (isCurrentlyFollowed) {
        // إلغاء المتابعة
        _favoriteSellers.removeWhere((s) => s.id == sellerId);
        _logger.log('🗑️ Seller unfollowed from UI: $sellerId');
      } else {
        // متابعة
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
          
          final newSeller = FavoriteSeller(
            id: sellerId,
            name: data['name'] ?? '',
            rating: (data['rating'] ?? 0).toDouble(),
            totalRatings: data['totalRatings'] ?? 0,
            imageUrl: data['avatarUrl'],
            productCount: productsSnapshot.docs.length,
            isFollowed: true,
            imageVersion: data['imageVersion'] ?? 1,
          );
          
          _favoriteSellers.insert(0, newSeller);
          _logger.log('❤️ Seller followed from UI: $sellerId');
        } else {
          _logger.log('⚠️ Seller not found: $sellerId');
          _pendingUpdates.remove('seller_$sellerId');
          return;
        }
      }
      
      notifyListeners();
      
      // ✅ تحديث قاعدة البيانات في الخلفية
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
              // التراجع عن التغيير
              if (isCurrentlyFollowed) {
                // إعادة إضافة البائع
                _loadSellerAndAddToFavorites(sellerId);
              } else {
                // إزالة البائع
                _favoriteSellers.removeWhere((s) => s.id == sellerId);
              }
              notifyListeners();
              _pendingUpdates.remove('seller_$sellerId');
              errorMessage = 'فشل تحديث حالة المتابعة';
            })
      );
      
      // ✅ تحديث HomeViewModel
      if (_homeViewModel != null) {
        unawaited(_homeViewModel!.refreshFavoritesCache());
      }
      
    } catch (e) {
      _logger.error('❌ Failed to toggle seller follow', e);
      errorMessage = 'فشل تحديث حالة المتابعة';
      _pendingUpdates.remove('seller_$sellerId');
    }
  }
  
  /// ✅ مساعدة: تحميل البائع وإضافته إلى المفضلة
  Future<void> _loadSellerAndAddToFavorites(String sellerId) async {
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
        
        final newSeller = FavoriteSeller(
          id: sellerId,
          name: data['name'] ?? '',
          rating: (data['rating'] ?? 0).toDouble(),
          totalRatings: data['totalRatings'] ?? 0,
          imageUrl: data['avatarUrl'],
          productCount: productsSnapshot.docs.length,
          isFollowed: true,
          imageVersion: data['imageVersion'] ?? 1,
        );
        
        _favoriteSellers.insert(0, newSeller);
        _logger.log('🔄 Seller re-added to favorites: $sellerId');
      }
    } catch (e) {
      _logger.error('❌ Failed to reload seller: $sellerId', e);
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
    await Future.wait([
      loadFavoriteProducts(),
      loadFavoriteSellers(),
    ]);
  }
  
  @override
  void dispose() {
    if (_homeViewModel != null) {
      _homeViewModel!.removeFavoriteListener(() {});
      _homeViewModel!.removeFavoritesViewModelListener(() {});
      _homeViewModel!.removeListener(_onHomeViewModelChanged);
    }
    super.dispose();
  }
}