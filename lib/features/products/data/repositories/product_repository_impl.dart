import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/features/products/data/models/seller_product_model.dart';
import 'package:locaydo_app/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final Logger _logger;
  final FirebaseFirestore _firestore;

  ProductRepositoryImpl({
    required Logger logger,
    FirebaseFirestore? firestore,
  })  : _logger = logger,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ProductModel>> getAllProducts() async {
    try {
      _logger.log('📦 Getting all products from Firebase...');
      final snapshot = await _firestore.collection('products').get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        return ProductModel.fromMap(data, doc.id);
      }).toList();

      _logger.log('✅ Retrieved ${products.length} products');
      return products;
    } catch (e) {
      _logger.error('❌ Failed to get all products', e);
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      _logger.log('📦 Getting products for category: $categoryId');
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: categoryId)
          .get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        return ProductModel.fromMap(data, doc.id);
      }).toList();

      _logger.log('✅ Retrieved ${products.length} products for category: $categoryId');
      return products;
    } catch (e) {
      _logger.error('❌ Failed to get products by category', e);
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> getProductsBySeller(String sellerId) async {
    try {
      _logger.log('📦 Getting products for seller: $sellerId');
      
      // ✅ تصحيح: البحث باستخدام sellerId
      final snapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        return ProductModel.fromMap(data, doc.id);
      }).toList();

      _logger.log('✅ Retrieved ${products.length} products for seller: $sellerId');
      return products;
    } catch (e) {
      _logger.error('❌ Failed to get products by seller', e);
      rethrow;
    }
  }

  @override
  Future<List<SellerProduct>> getSellerProducts(String sellerId) async {
    try {
      _logger.log('📦 Getting seller products for: $sellerId');
      
      // ✅ تصحيح: البحث باستخدام sellerId بدلاً من userId
      final snapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)  // ✅ استخدام sellerId
          .get();

      _logger.log('📦 Found ${snapshot.docs.length} documents');

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        _logger.log('📦 Product doc: id=${doc.id}, sellerId=${data['sellerId']}, userId=${data['userId']}');
        return SellerProduct.fromMap(data, doc.id);
      }).toList();

      _logger.log('✅ Retrieved ${products.length} seller products');
      return products;
    } catch (e) {
      _logger.error('❌ Failed to get seller products', e);
      rethrow;
    }
  }

  @override
  Future<void> markAsSold(String productId) async {
    try {
      _logger.log('💰 Marking product as sold: $productId');

      await _firestore.collection('products').doc(productId).update({
        'status': ProductStatus.sold.name,
        'soldAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _removeProductFromAllFavorites(productId);

      _logger.log('✅ Product marked as sold and removed from favorites');
    } catch (e) {
      _logger.error('❌ Failed to mark product as sold', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      _logger.log('🗑️ Deleting product: $productId from products collection');

      await _firestore.collection('products').doc(productId).delete();
      await _removeProductFromAllFavorites(productId);

      _logger.log('✅ Product and its references deleted successfully');
    } catch (e) {
      _logger.error('❌ Failed to delete product', e);
      rethrow;
    }
  }

  Future<void> _removeProductFromAllFavorites(String productId) async {
    try {
      _logger.log('🧹 Cleaning up product from all users favorites...');

      final usersSnapshot = await _firestore
          .collectionGroup('favoriteProducts')
          .where('productId', isEqualTo: productId)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        _logger.log('ℹ️ Product $productId not found in any favorites');
        return;
      }

      _logger.log('📦 Found ${usersSnapshot.docs.length} favorite entries to delete');

      final batch = _firestore.batch();
      for (final doc in usersSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _logger.log('✅ Removed product $productId from all users favorites');
    } catch (e) {
      _logger.error('❌ Failed to clean up favorites', e);
    }
  }

  @override
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      _logger.error('❌ Failed to get product by id', e);
      return null;
    }
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    try {
      await _firestore.collection('products').doc(product.id).set(product.toMap());
      _logger.log('✅ Product added successfully: ${product.title}');
    } catch (e) {
      _logger.error('❌ Failed to add product', e);
      rethrow;
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore.collection('products').doc(product.id).update(product.toMap());
      _logger.log('✅ Product updated successfully: ${product.title}');
    } catch (e) {
      _logger.error('❌ Failed to update product', e);
      rethrow;
    }
  }
}