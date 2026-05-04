// lib/features/categories/data/models/category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';

class CategoryModel {
  final String id;
  final String name;
  final String nameEn;
  final String iconPath;
  final int order;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.iconPath,
    required this.order,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      nameEn: data['nameEn'] ?? '',
      iconPath: data['iconPath'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'nameEn': nameEn,
      'iconPath': iconPath,
      'order': order,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// ✅ تحويل إلى ProductCategory Enum (للتوافق مع الكود القديم)
  ProductCategory toProductCategory() {
    switch (id) {
      case 'electronics':
        return ProductCategory.electronics;
      case 'clothes':
        return ProductCategory.clothes;
      case 'furniture':
        return ProductCategory.furniture;
      case 'realEstate':
        return ProductCategory.realEstate;
      case 'food':
        return ProductCategory.food;
      case 'handicrafts':
        return ProductCategory.handicrafts;
      case 'donation':
        return ProductCategory.donation;
      case 'cooking':
        return ProductCategory.cooking;
      case 'cosmetics':
        return ProductCategory.cosmetics;
      case 'shoes':
        return ProductCategory.shoes;
      case 'perfumes':
        return ProductCategory.perfumes;
      case 'bag':
        return ProductCategory.bag;
      default:
        return ProductCategory.all;
    }
  }

  /// ✅ إنشاء نسخة جديدة مع تحديث بعض الحقول
  CategoryModel copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? iconPath,
    int? order,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      iconPath: iconPath ?? this.iconPath,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}