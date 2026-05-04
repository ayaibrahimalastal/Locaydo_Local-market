import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';

enum ProductStatus { available, sold }

class SellerProduct {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String location;
  final String imageUrl;
  final List<String> additionalImages;
  final List<PaymentMethod> paymentMethods;
  final ProductCategory category;
  final ProductCondition condition;
  final ProductStatus status;
  final DateTime createdAt;
  final DateTime? soldAt;
  
  // ✅ ✅ ✅ أضفنا حقل sellerId (معرف البائع من sellers collection)
  final String sellerId;

  SellerProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.location,
    required this.imageUrl,
    required this.additionalImages,
    required this.paymentMethods,
    required this.category,
    required this.condition,
    required this.status,
    required this.createdAt,
    this.soldAt,
    required this.sellerId,  // ✅ أضفنا هذا الحقل
  });

  // ✅ Factory constructor من DocumentSnapshot
  factory SellerProduct.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellerProduct.fromMap(data, doc.id);
  }

  // ✅ Factory constructor من Map مع docId
  factory SellerProduct.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return SellerProduct(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? '₪',
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      additionalImages: List<String>.from(map['additionalImages'] ?? []),
      paymentMethods: (map['paymentMethods'] as List? ?? [])
          .map((e) => PaymentMethod.fromString(e.toString()))
          .toList(),
      category: ProductCategory.fromString(map['category'] ?? ''),
      condition: ProductCondition.fromString(map['condition'] ?? ''),
      status: map['status'] == 'sold' ? ProductStatus.sold : ProductStatus.available,
      createdAt: parseDate(map['createdAt']),
      soldAt: map['soldAt'] != null ? parseDate(map['soldAt']) : null,
      sellerId: map['sellerId'] ?? map['userId'] ?? '',  // ✅ قراءة sellerId من Firebase
    );
  }

  // ✅ للتوافق مع الكود القديم
  factory SellerProduct.fromJson(Map<String, dynamic> json, {String? docId}) {
    return SellerProduct.fromMap(json, docId ?? json['id'] ?? '');
  }

  // ✅ تحويل إلى Map للتخزين في Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'location': location,
      'imageUrl': imageUrl,
      'additionalImages': additionalImages,
      'paymentMethods': paymentMethods.map((e) => e.name).toList(),
      'category': category.name,
      'condition': condition.name,
      'status': status == ProductStatus.sold ? 'sold' : 'available',
      'createdAt': FieldValue.serverTimestamp(),
      'soldAt': soldAt != null ? Timestamp.fromDate(soldAt!) : null,
      'sellerId': sellerId,  // ✅ حفظ sellerId في Firebase
    };
  }

  // ✅ للتوافق مع الكود القديم
  Map<String, dynamic> toJson() => toMap();

  // ✅ دالة copyWith المعدلة
  SellerProduct copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? currency,
    String? location,
    String? imageUrl,
    List<String>? additionalImages,
    List<PaymentMethod>? paymentMethods,
    ProductCategory? category,
    ProductCondition? condition,
    ProductStatus? status,
    DateTime? createdAt,
    DateTime? soldAt,
    String? sellerId,  // ✅ أضفنا هذا
  }) {
    return SellerProduct(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      soldAt: soldAt ?? this.soldAt,
      sellerId: sellerId ?? this.sellerId,  // ✅ أضفنا هذا
    );
  }

  // ✅ دالة للتحقق من المساواة
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SellerProduct && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // ✅ دالة toString للتسهيل في التصحيح
  @override
  String toString() {
    return 'SellerProduct(id: $id, title: $title, price: $price, status: ${status.name}, sellerId: $sellerId)';
  }

  // ✅ دالة مساعدة لمعرفة إذا كان المنتج مباعاً
  bool get isSold => status == ProductStatus.sold;

  // ✅ دالة مساعدة لمعرفة إذا كان المنتج متاحاً
  bool get isAvailable => status == ProductStatus.available;

  // ✅ ✅ ✅ تحويل إلى ProductModel مع تمرير sellerId ✅ ✅ ✅
  ProductModel toProductModel({required String sellerName}) {
    return ProductModel(
      id: id,
      title: title,
      description: description,
      price: price,
      currency: currency,
      location: location,
      imageUrl: imageUrl,
      additionalImages: additionalImages,
      category: category,
      condition: condition,
      paymentMethods: paymentMethods,
      sellerId: sellerId,  // ✅ استخدام sellerId المخزن
      sellerName: sellerName,
      createdAt: createdAt,
      status: status,
    );
  }
}

// ✅ إضافة extension لتسهيل التعامل مع ProductStatus
extension ProductStatusExtension on ProductStatus {
  String get displayName {
    switch (this) {
      case ProductStatus.available:
        return 'متاح';
      case ProductStatus.sold:
        return 'مباع';
    }
  }

  Color get color {
    switch (this) {
      case ProductStatus.available:
        return Colors.green;
      case ProductStatus.sold:
        return Colors.grey;
    }
  }
}