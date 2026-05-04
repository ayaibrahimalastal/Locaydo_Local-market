// lib/features/favorites/domain/repositories/favorites_repository.dart

import 'package:locaydo_app/features/favorites/data/models/favorites_model.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';

abstract class FavoritesRepository {
  // ✅ دوال المنتجات المفضلة
  Future<List<FavoriteProduct>> getFavoriteProducts();
  Future<void> toggleProductFavorite(ProductModel product);
  Future<void> toggleProductFavoriteById(String productId);
  Future<void> addToFavorites(ProductModel product);
  Future<void> removeFromFavorites(String productId);
  Future<bool> isFavorite(String productId);
  
  // ✅ دالة جديدة للتحقق من وجود المنتج
  Future<bool> isProductExists(String productId);
  
  // ✅ دوال البائعين المفضلين
  Future<List<FavoriteSeller>> getFavoriteSellers();
  Future<void> toggleSellerFollow(String sellerId);
  Future<bool> isFollowingSeller(String sellerId);
  
  // ✅ دالة لتنظيف المفضلات (حذف المنتجات غير الموجودة)
  Future<int> cleanupInvalidFavorites();
}