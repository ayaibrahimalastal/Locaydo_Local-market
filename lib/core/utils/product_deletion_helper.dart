// lib/core/utils/product_deletion_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/utils/logger.dart';

class ProductDeletionHelper {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Logger _logger;

  ProductDeletionHelper({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required Logger logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _logger = logger;

  Future<void> deleteProductWithCascade(String productId) async {
    _logger.log('🔄 Starting cascade delete for product: $productId');
    
    try {
      await _deleteFromProductsCollection(productId);
      await _deleteFromAllUsersFavorites(productId);
      await _deleteFromOtherCollections(productId);
      
      _logger.log('✅ Cascade delete completed for product: $productId');
    } catch (e) {
      _logger.error('❌ Cascade delete failed for product: $productId', e);
      rethrow;
    }
  }

  Future<void> _deleteFromProductsCollection(String productId) async {
    try {
      final productQuery = await _firestore
          .collection('products')
          .where('id', isEqualTo: productId)
          .limit(1)
          .get();

      if (productQuery.docs.isNotEmpty) {
        await productQuery.docs.first.reference.delete();
        _logger.log('✅ Product deleted from products collection');
      } else {
        _logger.log('⚠️ Product not found in products collection');
      }
    } catch (e) {
      _logger.error('❌ Failed to delete from products collection', e);
      rethrow;
    }
  }

  Future<void> _deleteFromAllUsersFavorites(String productId) async {
    try {
      final favoritesQuery = await _firestore
          .collectionGroup('favoriteProducts')
          .where('productId', isEqualTo: productId)
          .get();

      if (favoritesQuery.docs.isEmpty) {
        _logger.log('📭 Product not found in any user favorites');
        return;
      }

      _logger.log('🗑️ Removing product from ${favoritesQuery.docs.length} users favorites');
      
      final batch = _firestore.batch();
      for (final doc in favoritesQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      _logger.log('✅ Product removed from all users favorites');
    } catch (e) {
      _logger.error('❌ Failed to delete from favorites', e);
    }
  }

  Future<void> _deleteFromOtherCollections(String productId) async {
    try {
      final cartsQuery = await _firestore
          .collectionGroup('cartItems')
          .where('productId', isEqualTo: productId)
          .get();

      if (cartsQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in cartsQuery.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        _logger.log('✅ Product removed from ${cartsQuery.docs.length} carts');
      }

      final ordersQuery = await _firestore
          .collectionGroup('orderItems')
          .where('productId', isEqualTo: productId)
          .get();

      if (ordersQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in ordersQuery.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        _logger.log('✅ Product removed from ${ordersQuery.docs.length} orders');
      }

    } catch (e) {
      _logger.error('❌ Failed to delete from other collections', e);
    }
  }

  Future<bool> isProductInAnyFavorites(String productId) async {
    try {
      final favoritesQuery = await _firestore
          .collectionGroup('favoriteProducts')
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();
      
      return favoritesQuery.docs.isNotEmpty;
    } catch (e) {
      _logger.error('❌ Failed to check favorites', e);
      return false;
    }
  }
}