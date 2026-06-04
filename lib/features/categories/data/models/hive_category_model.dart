// lib/features/categories/data/models/hive_category_model.dart

import 'package:hive/hive.dart';
import 'category_model.dart';

part 'hive_category_model.g.dart';

@HiveType(typeId: 1)
class HiveCategoryModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String nameEn;  // ✅ إضافة الحقل المفقود
  
  @HiveField(3)
  final String iconPath;
  
  @HiveField(4)
  final int order;
  
  @HiveField(5)
  final DateTime createdAt;  // ✅ إضافة الحقل المفقود

  HiveCategoryModel({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.iconPath,
    required this.order,
    required this.createdAt,
  });

  factory HiveCategoryModel.fromCategory(CategoryModel category) {
    return HiveCategoryModel(
      id: category.id,
      name: category.name,
      nameEn: category.nameEn,
      iconPath: category.iconPath,
      order: category.order,
      createdAt: category.createdAt,
    );
  }

  CategoryModel toCategoryModel() {
    return CategoryModel(
      id: id,
      name: name,
      nameEn: nameEn,
      iconPath: iconPath,
      order: order,
      createdAt: createdAt,
    );
  }
}