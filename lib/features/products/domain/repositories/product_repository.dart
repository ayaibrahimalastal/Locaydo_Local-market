// lib/features/products/domain/repositories/product_repository.dart
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/features/products/data/models/seller_product_model.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getAllProducts();
  Future<List<ProductModel>> getProductsByCategory(String category);
  Future<List<ProductModel>> getProductsBySeller(String sellerId);
  Future<ProductModel?> getProductById(String id);
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Future<List<SellerProduct>> getSellerProducts(String sellerId);
  Future<void> markAsSold(String productId);
}