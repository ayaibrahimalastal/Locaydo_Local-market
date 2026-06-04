// lib/features/favorites/data/repositories/favorites_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/favorites/data/models/favorites_model.dart';
import 'package:locaydo_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final Logger _logger;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FavoritesRepositoryImpl({
    required Logger logger,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _logger = logger,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  CollectionReference get _favoriteProductsCollection {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('favoriteProducts');
  }

  CollectionReference get _favoriteSellersCollection {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('favoriteSellers');
  }

  // ==================== PRODUCT FAVORITES ====================

  @override
  Future<List<FavoriteProduct>> getFavoriteProducts() async {
    try {
      if (_currentUserId.isEmpty) {
        _logger.log('⚠️ No user logged in');
        return [];
      }

      _logger.log('📦 Fetching favorite products for user: $_currentUserId');
      
      final snapshot = await _favoriteProductsCollection
          .orderBy('addedAt', descending: true)
          .get();

      final products = <FavoriteProduct>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        final productExists = await isProductExists(doc.id);
        
        if (productExists) {
          products.add(FavoriteProduct(
            id: doc.id,
            title: data['title'] ?? '',
            price: (data['price'] ?? 0).toDouble(),
            currency: data['currency'] ?? '₪',
            location: data['location'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
            paymentMethods: (data['paymentMethods'] as List? ?? [])
                .map((e) => PaymentMethod.fromString(e.toString()))
                .toList(),
            isFavorite: true,
          ));
        } else {
          _logger.log('🗑️ Auto-cleaning invalid favorite: ${doc.id}');
          await doc.reference.delete();
        }
      }

      _logger.log('✅ Loaded ${products.length} valid favorite products');
      return products;
    } catch (e) {
      _logger.error('❌ Failed to load favorite products', e);
      return [];
    }
  }

  @override
  Future<void> toggleProductFavorite(ProductModel product) async {
    try {
      if (_currentUserId.isEmpty) {
        _logger.log('⚠️ No user logged in');
        return;
      }

      final docRef = _favoriteProductsCollection.doc(product.id);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.delete();
        _logger.log('🗑️ Product removed from favorites: ${product.title}');
      } else {
        await docRef.set({
          'productId': product.id,
          'title': product.title,
          'price': product.price,
          'currency': product.currency,
          'location': product.location,
          'imageUrl': product.imageUrl,
          'paymentMethods': product.paymentMethods.map((e) => e.name).toList(),
          'addedAt': FieldValue.serverTimestamp(),
        });
        _logger.log('❤️ Product added to favorites: ${product.title}');
      }
    } catch (e) {
      _logger.error('❌ Failed to toggle favorite', e);
      rethrow;
    }
  }

  @override
  Future<void> toggleProductFavoriteById(String productId) async {
    try {
      if (_currentUserId.isEmpty) {
        _logger.log('⚠️ No user logged in');
        return;
      }

      final docRef = _favoriteProductsCollection.doc(productId);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.delete();
        _logger.log('🗑️ Product removed from favorites: $productId');
      } else {
        final productExists = await isProductExists(productId);
        
        if (!productExists) {
          _logger.log('⚠️ Cannot add to favorites: Product not found: $productId');
          throw Exception('Product not found');
        }
        
        final productDoc = await _firestore
            .collection('products')
            .doc(productId)
            .get();
        
        if (productDoc.exists) {
          final data = productDoc.data()!;
          await docRef.set({
            'productId': productId,
            'title': data['title'] ?? '',
            'price': data['price'] ?? 0,
            'currency': data['currency'] ?? '₪',
            'location': data['location'] ?? '',
            'imageUrl': data['imageUrl'] ?? '',
            'paymentMethods': data['paymentMethods'] ?? [],
            'addedAt': FieldValue.serverTimestamp(),
          });
          _logger.log('❤️ Product added to favorites: $productId');
        } else {
          _logger.log('⚠️ Product not found: $productId');
          throw Exception('Product not found');
        }
      }
    } catch (e) {
      _logger.error('❌ Failed to toggle favorite by id', e);
      rethrow;
    }
  }

  @override
  Future<void> addToFavorites(ProductModel product) async {
    try {
      if (_currentUserId.isEmpty) {
        _logger.log('⚠️ No user logged in');
        throw Exception('User not logged in');
      }
      
      if (product.id.isEmpty) {
        _logger.error('❌ Cannot add to favorites: Product ID is empty');
        throw Exception('Product ID is empty');
      }
      
      if (product.title.isEmpty) {
        _logger.error('❌ Cannot add to favorites: Product title is empty for ID: ${product.id}');
        throw Exception('Product title is empty');
      }
      
      final productExists = await isProductExists(product.id);
      if (!productExists) {
        _logger.error('❌ Cannot add to favorites: Product does not exist: ${product.id}');
        throw Exception('Product does not exist');
      }
      
      _logger.log('❤️ Adding product to favorites: ${product.title} (ID: ${product.id})');
      
      final docRef = _favoriteProductsCollection.doc(product.id);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'productId': product.id,
          'title': product.title,
          'price': product.price,
          'currency': product.currency,
          'location': product.location,
          'imageUrl': product.imageUrl,
          'paymentMethods': product.paymentMethods.map((e) => e.name).toList(),
          'addedAt': FieldValue.serverTimestamp(),
        });
        _logger.log('✅ Product added to favorites successfully: ${product.title}');
      } else {
        _logger.log('⚠️ Product already in favorites: ${product.title}');
      }
    } catch (e) {
      _logger.error('❌ Failed to add to favorites: ${product.title}', e);
      rethrow;
    }
  }

  @override
  Future<void> removeFromFavorites(String productId) async {
    try {
      if (_currentUserId.isEmpty) {
        _logger.log('⚠️ No user logged in');
        return;
      }

      _logger.log('🗑️ Removing product from favorites: $productId');
      final docRef = _favoriteProductsCollection.doc(productId);
      await docRef.delete();
      _logger.log('✅ Product removed from favorites: $productId');
    } catch (e) {
      _logger.error('❌ Failed to remove from favorites', e);
      rethrow;
    }
  }

  @override
  Future<bool> isFavorite(String productId) async {
    try {
      if (_currentUserId.isEmpty) return false;
      
      final doc = await _favoriteProductsCollection.doc(productId).get();
      return doc.exists;
    } catch (e) {
      _logger.error('❌ Failed to check favorite status', e);
      return false;
    }
  }

  @override
  Future<bool> isProductExists(String productId) async {
    try {
      if (productId.isEmpty) return false;
      
      final doc = await _firestore.collection('products').doc(productId).get();
      return doc.exists;
    } catch (e) {
      _logger.error('❌ Failed to check if product exists: $productId', e);
      return false;
    }
  }

  @override
  Future<int> cleanupInvalidFavorites() async {
    try {
      if (_currentUserId.isEmpty) {
        _logger.log('⚠️ No user logged in');
        return 0;
      }

      _logger.log('🧹 Cleaning up invalid favorites for user: $_currentUserId');
      
      final snapshot = await _favoriteProductsCollection.get();
      int deletedCount = 0;
      
      for (final doc in snapshot.docs) {
        final productExists = await isProductExists(doc.id);
        if (!productExists) {
          _logger.log('🗑️ Deleting invalid favorite: ${doc.id}');
          await doc.reference.delete();
          deletedCount++;
        }
      }
      
      _logger.log('✅ Cleaned up $deletedCount invalid favorites');
      return deletedCount;
    } catch (e) {
      _logger.error('❌ Failed to cleanup invalid favorites', e);
      return 0;
    }
  }

  // ==================== SELLER FAVORITES ====================

  @override
  Future<void> addSellerToFavorites(String sellerId) async {
    try {
      if (_currentUserId.isEmpty) {
        _logger.log('⚠️ No user logged in');
        throw Exception('User not logged in');
      }

      _logger.log('❤️ Adding seller to favorites: $sellerId');
      
      final sellerDoc = await _firestore.collection('sellers').doc(sellerId).get();
      if (!sellerDoc.exists) {
        _logger.log('⚠️ Seller not found: $sellerId');
        throw Exception('Seller not found');
      }
      
      final data = sellerDoc.data()!;
      final productsCount = await _getSellerProductsCount(sellerId);
      
      final docRef = _favoriteSellersCollection.doc(sellerId);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'sellerId': sellerId,
          'name': data['name'] ?? '',
          'rating': (data['rating'] ?? 0).toDouble(),
          'totalRatings': data['totalRatings'] ?? 0,
          'imageUrl': data['avatarUrl'] ?? '',
          'productCount': productsCount,
          'imageVersion': data['imageVersion'] ?? 0,
          'addedAt': FieldValue.serverTimestamp(),
        });
        _logger.log('✅ Seller added to favorites successfully: ${data['name']}');
      } else {
        _logger.log('⚠️ Seller already in favorites: $sellerId');
      }
    } catch (e) {
      _logger.error('❌ Failed to add seller to favorites: $sellerId', e);
      rethrow;
    }
  }

  @override
  Future<void> removeSellerFromFavorites(String sellerId) async {
    try {
      if (_currentUserId.isEmpty) {
        _logger.log('⚠️ No user logged in');
        return;
      }

      _logger.log('🗑️ Removing seller from favorites: $sellerId');
      final docRef = _favoriteSellersCollection.doc(sellerId);
      await docRef.delete();
      _logger.log('✅ Seller removed from favorites: $sellerId');
    } catch (e) {
      _logger.error('❌ Failed to remove seller from favorites', e);
      rethrow;
    }
  }

  @override
  Future<List<FavoriteSeller>> getFavoriteSellers() async {
    try {
      if (_currentUserId.isEmpty) {
        _logger.log('⚠️ No user logged in');
        return [];
      }

      _logger.log('📦 Fetching favorite sellers for user: $_currentUserId');
      
      final snapshot = await _favoriteSellersCollection
          .orderBy('addedAt', descending: true)
          .get();

      final sellers = <FavoriteSeller>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        final sellerExists = await _isSellerExists(doc.id);
        
        if (sellerExists) {
          sellers.add(FavoriteSeller(
            id: doc.id,
            name: data['name'] ?? '',
            rating: (data['rating'] ?? 0).toDouble(),
            totalRatings: data['totalRatings'] ?? 0,
            imageUrl: data['imageUrl'],
            productCount: data['productCount'] ?? 0,
            isFollowed: true,
            imageVersion: data['imageVersion'] ?? 0,
          ));
        } else {
          _logger.log('🗑️ Auto-cleaning invalid favorite seller: ${doc.id}');
          await doc.reference.delete();
        }
      }

      _logger.log('✅ Loaded ${sellers.length} favorite sellers');
      return sellers;
    } catch (e) {
      _logger.error('❌ Failed to load favorite sellers', e);
      return [];
    }
  }

  @override
  Future<bool> isFollowingSeller(String sellerId) async {
    try {
      if (_currentUserId.isEmpty) return false;
      
      final doc = await _favoriteSellersCollection.doc(sellerId).get();
      return doc.exists;
    } catch (e) {
      _logger.error('❌ Failed to check following status', e);
      return false;
    }
  }

  @override
  Future<void> toggleSellerFollow(String sellerId) async {
    try {
      if (_currentUserId.isEmpty) {
        _logger.log('⚠️ No user logged in');
        return;
      }

      final docRef = _favoriteSellersCollection.doc(sellerId);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.delete();
        _logger.log('🗑️ Seller unfollowed: $sellerId');
      } else {
        final sellerDoc = await _firestore.collection('sellers').doc(sellerId).get();
        if (sellerDoc.exists) {
          final data = sellerDoc.data()!;
          final productsCount = await _getSellerProductsCount(sellerId);
          
          await docRef.set({
            'sellerId': sellerId,
            'name': data['name'] ?? '',
            'rating': (data['rating'] ?? 0).toDouble(),
            'totalRatings': data['totalRatings'] ?? 0,
            'imageUrl': data['avatarUrl'] ?? '',
            'productCount': productsCount,
            'imageVersion': data['imageVersion'] ?? 0,
            'addedAt': FieldValue.serverTimestamp(),
          });
          _logger.log('❤️ Seller followed: $sellerId');
        } else {
          _logger.log('⚠️ Seller not found: $sellerId');
          throw Exception('Seller not found');
        }
      }
    } catch (e) {
      _logger.error('❌ Failed to toggle seller follow', e);
      rethrow;
    }
  }

  // ==================== STREAMS FOR REAL-TIME UPDATES ====================

  @override
  Stream<Map<String, bool>> watchAllFavorites() {
    try {
      if (_currentUserId.isEmpty) {
        _logger.log('⚠️ No user logged in for favorites stream');
        return Stream.value({});
      }
      
      _logger.log('📡 Setting up real-time stream for all favorites');
      return _favoriteProductsCollection.snapshots().map((snapshot) {
        final favorites = <String, bool>{};
        for (final doc in snapshot.docs) {
          favorites[doc.id] = true;
        }
        _logger.log('📡 Favorites stream update: ${favorites.length} items');
        return favorites;
      });
    } catch (e) {
      _logger.error('❌ Failed to watch favorites', e);
      return Stream.error(e);
    }
  }

  @override
  Stream<List<String>> watchFavoriteProductIds() {
    try {
      if (_currentUserId.isEmpty) {
        _logger.log('⚠️ No user logged in for favorite product IDs stream');
        return Stream.value([]);
      }
      
      _logger.log('📡 Setting up real-time stream for favorite product IDs');
      return _favoriteProductsCollection.snapshots().map((snapshot) {
        final ids = snapshot.docs.map((doc) => doc.id).toList();
        _logger.log('📡 Favorite product IDs stream update: ${ids.length} items');
        return ids;
      });
    } catch (e) {
      _logger.error('❌ Failed to watch favorite product IDs', e);
      return Stream.error(e);
    }
  }

  @override
  Stream<List<String>> watchFavoriteSellerIds() {
    try {
      if (_currentUserId.isEmpty) {
        _logger.log('⚠️ No user logged in for favorite seller IDs stream');
        return Stream.value([]);
      }
      
      _logger.log('📡 Setting up real-time stream for favorite seller IDs');
      return _favoriteSellersCollection.snapshots().map((snapshot) {
        final ids = snapshot.docs.map((doc) => doc.id).toList();
        _logger.log('📡 Favorite seller IDs stream update: ${ids.length} items');
        return ids;
      });
    } catch (e) {
      _logger.error('❌ Failed to watch favorite seller IDs', e);
      return Stream.error(e);
    }
  }

  // ==================== PRIVATE HELPERS ====================

  Future<bool> _isSellerExists(String sellerId) async {
    try {
      final doc = await _firestore.collection('sellers').doc(sellerId).get();
      return doc.exists;
    } catch (e) {
      _logger.error('❌ Failed to check if seller exists: $sellerId', e);
      return false;
    }
  }

  Future<int> _getSellerProductsCount(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      _logger.error('❌ Failed to get products count for seller: $sellerId', e);
      return 0;
    }
  }
}