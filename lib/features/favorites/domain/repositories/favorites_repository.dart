// lib/features/favorites/domain/repositories/favorites_repository.dart

import 'package:locaydo_app/features/favorites/data/models/favorites_model.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';

abstract class FavoritesRepository {
  // Existing methods
  Future<List<FavoriteProduct>> getFavoriteProducts();
  Future<void> toggleProductFavorite(ProductModel product);
  Future<void> toggleProductFavoriteById(String productId);
  Future<void> addToFavorites(ProductModel product);
  Future<void> removeFromFavorites(String productId);
  Future<bool> isFavorite(String productId);
  Future<bool> isProductExists(String productId);
  Future<List<FavoriteSeller>> getFavoriteSellers();
  Future<void> toggleSellerFollow(String sellerId);
  Future<bool> isFollowingSeller(String sellerId);
  Future<int> cleanupInvalidFavorites();
  
  // ✅ NEW: Stream methods for real-time favorites
  Stream<Map<String, bool>> watchAllFavorites();
  Stream<List<String>> watchFavoriteProductIds();
  Stream<List<String>> watchFavoriteSellerIds();
  Future<void> addSellerToFavorites(String sellerId);
  Future<void> removeSellerFromFavorites(String sellerId);
}