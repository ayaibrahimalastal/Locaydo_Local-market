// lib/features/products/data/models/product_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/features/products/data/models/seller_product_model.dart';

class ProductModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String location;
  final String imageUrl;
  final List<String> additionalImages;
  final ProductCategory category;
  final ProductCondition condition;
  final List<PaymentMethod> paymentMethods;
  final String sellerId;
  final String sellerName;
  final DateTime createdAt;
  
  // ✅ أضف هذا الحقل الجديد
  final ProductStatus status;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.location,
    required this.imageUrl,
    this.additionalImages = const [],
    required this.category,
    required this.condition,
    required this.paymentMethods,
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,
    required this.status,
  });

  // ✅ Factory constructor من Firebase DocumentSnapshot
  factory ProductModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel.fromMap(data, doc.id);
  }

  // ✅ Factory constructor من Map مع docId
  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseCreatedAt(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return ProductModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? '₪',
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      additionalImages: List<String>.from(map['additionalImages'] ?? []),
      category: ProductCategory.fromString(map['category'] ?? ''),
      condition: ProductCondition.fromString(map['condition'] ?? ''),
      paymentMethods: (map['paymentMethods'] as List? ?? [])
          .map((e) => PaymentMethod.fromString(e.toString()))
          .toList(),
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      createdAt: parseCreatedAt(map['createdAt']),
      status: map['status'] == 'sold' ? ProductStatus.sold : ProductStatus.available,
    );
  }

  // ✅ للتوافق مع الكود القديم
  factory ProductModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return ProductModel.fromMap(json, docId ?? json['id'] ?? '');
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
      'category': category.name,
      'condition': condition.name,
      'paymentMethods': paymentMethods.map((e) => e.name).toList(),
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status.name,
    };
  }

  // ✅ للتوافق مع الكود القديم
  Map<String, dynamic> toJson() => toMap();

  // ✅ دالة مساعدة لمعرفة إذا كان المنتج مباعاً
  bool get isSold => status == ProductStatus.sold;
  bool get isAvailable => status == ProductStatus.available;

  // ✅ دالة copyWith
  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? currency,
    String? location,
    String? imageUrl,
    List<String>? additionalImages,
    ProductCategory? category,
    ProductCondition? condition,
    List<PaymentMethod>? paymentMethods,
    double? rating,
    int? reviewCount,
    String? sellerId,
    String? sellerName,
    DateTime? createdAt,
    ProductStatus? status,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  // ✅ دالة للتحقق من المساواة
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // ✅ دالة toString للتسهيل في التصحيح
  @override
  String toString() {
    return 'ProductModel(id: $id, title: $title, price: $price, status: ${status.name})';
  }
}