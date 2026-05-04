// lib/features/products/domain/entities/product_entity.dart

import 'package:locaydo_app/core/enums/product_enums.dart';

class ProductEntity {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String location;
  final String area;
  final String imageUrl;
  final List<String> additionalImages;
  final ProductCategory category;
  final ProductCondition condition;
  final List<PaymentMethod> paymentMethods;
  final bool isFavorite;
  final String sellerId;
  final String sellerName;
  final DateTime createdAt;

  const ProductEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.location,
    required this.area,
    required this.imageUrl,
    this.additionalImages = const [],
    required this.category,
    required this.condition,
    required this.paymentMethods,
    this.isFavorite = false,
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,
  });
}