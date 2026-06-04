import 'package:locaydo_app/core/enums/product_enums.dart';

class FavoriteProduct {
  final String id;
  final String title;
  final double price;
  final String currency;
  final String location;
  final String imageUrl;
  final List<PaymentMethod> paymentMethods;
  final bool isFavorite;
   final bool? isSold; 

  FavoriteProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    required this.location,
    required this.imageUrl,
    required this.paymentMethods,
    this.isFavorite = true,
     this.isSold,
  });
}

class FavoriteSeller {
  final String id;
  final String name;
  final double rating;
  final int totalRatings;
  final String? imageUrl;
  final int productCount;
  final bool isFollowed;
  final int imageVersion; // ✅ رقم إصدار الصورة

  FavoriteSeller({
    required this.id,
    required this.name,
    required this.rating,
    required this.totalRatings,
    this.imageUrl,
    required this.productCount,
    this.isFollowed = true,
    this.imageVersion = 0, // ✅ القيمة الافتراضية
  });
}