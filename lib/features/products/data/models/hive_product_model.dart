import 'package:hive/hive.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/features/products/data/models/seller_product_model.dart';
import 'product_model.dart';

part 'hive_product_model.g.dart';

@HiveType(typeId: 0)
class HiveProductModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final double price;
  
  @HiveField(4)
  final String currency;
  
  @HiveField(5)
  final String location;
  
  @HiveField(6)
  final String imageUrl;
  
  @HiveField(7)
  final List<String> additionalImages;
  
  @HiveField(8)
  final String category;
  
  @HiveField(9)
  final String condition;
  
  @HiveField(10)
  final List<String> paymentMethods;
  
  @HiveField(11)
  final String sellerId;
  
  @HiveField(12)
  final String sellerName;
  
  @HiveField(13)
  final DateTime createdAt;
  
  @HiveField(14)
  final String status;

  HiveProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.location,
    required this.imageUrl,
    required this.additionalImages,
    required this.category,
    required this.condition,
    required this.paymentMethods,
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,
    required this.status,
  });

  // تحويل من ProductModel إلى HiveProductModel
  factory HiveProductModel.fromProduct(ProductModel product) {
    return HiveProductModel(
      id: product.id,
      title: product.title,
      description: product.description,
      price: product.price,
      currency: product.currency,
      location: product.location,
      imageUrl: product.imageUrl,
      additionalImages: product.additionalImages,
      category: product.category.name,
      condition: product.condition.name,
      paymentMethods: product.paymentMethods.map((e) => e.name).toList(),
      sellerId: product.sellerId,
      sellerName: product.sellerName,
      createdAt: product.createdAt,
      status: product.status.name,
    );
  }

  // تحويل إلى ProductModel
  ProductModel toProductModel() {
    return ProductModel(
      id: id,
      title: title,
      description: description,
      price: price,
      currency: currency,
      location: location,
      imageUrl: imageUrl,
      additionalImages: additionalImages,
      category: _getCategoryFromString(category),
      condition: _getConditionFromString(condition),
      paymentMethods: paymentMethods.map((e) => _getPaymentMethodFromString(e)).toList(),
      sellerId: sellerId,
      sellerName: sellerName,
      createdAt: createdAt,
      status: status == 'sold' ? ProductStatus.sold : ProductStatus.available,
    );
  }

  ProductCategory _getCategoryFromString(String categoryName) {
    return ProductCategory.values.firstWhere(
      (e) => e.name == categoryName,
      orElse: () => ProductCategory.all,
    );
  }

  ProductCondition _getConditionFromString(String conditionName) {
    return ProductCondition.values.firstWhere(
      (e) => e.name == conditionName,
      orElse: () => ProductCondition.new_,
    );
  }

  PaymentMethod _getPaymentMethodFromString(String methodName) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == methodName,
      orElse: () => PaymentMethod.cash,
    );
  }
}