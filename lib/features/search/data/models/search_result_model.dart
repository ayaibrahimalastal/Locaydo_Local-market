// lib/features/search/data/models/search_result_model.dart

import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/enums/search_enums.dart';

class UserSearchResult {
  final String id;
  final String name;
  final String? imageUrl;
  final double rating;
  final SearchResultType type;

  UserSearchResult({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.rating,
    required this.type,
  });
}

class ProductSearchResult {
  final String id;
  final String title;
  final double price;
  final String currency;
  final String? imageUrl;
  final String location;
  final String area;
  final List<PaymentMethod> paymentMethods;
  final bool isFavorite;
  final String sellerName;
  final String? sellerAvatarUrl; // ✅ إضافة صورة البائع
  final String? sellerId; // ✅ إضافة معرف البائع

  ProductSearchResult({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    this.imageUrl,
    required this.location,
    required this.area,
    required this.paymentMethods,
    this.isFavorite = false,
    required this.sellerName,
    this.sellerAvatarUrl, // ✅ إضافة صورة البائع
    this.sellerId, // ✅ إضافة معرف البائع
  });
}