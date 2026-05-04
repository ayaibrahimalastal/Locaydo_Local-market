// lib/features/categories/domain/repositories/category_repository.dart
import 'package:locaydo_app/features/categories/data/models/category_model.dart';

/// واجهة مستودع الفئات
/// 
/// مسؤول عن جلب بيانات الفئات من مصدر البيانات (Firebase)
abstract class CategoryRepository {
  /// جلب جميع الفئات من قاعدة البيانات
  /// 
  /// يعيد قائمة بجميع الفئات مرتبة حسب الترتيب (order)
  Future<List<CategoryModel>> getAllCategories();
  
  /// جلب فئة محددة بواسطة ID
  /// 
  /// [id] - معرف الفئة (مثل: 'electronics', 'clothes', 'bag')
  /// يعيد كائن CategoryModel إذا وجد، وإلا يعيد null
  Future<CategoryModel?> getCategoryById(String id);
  
  /// جلب الفئات النشطة فقط
  /// 
  /// يعيد قائمة الفئات التي isActive == true
  Future<List<CategoryModel>> getActiveCategories();
  
  /// إضافة فئة جديدة (للاستخدام الإداري)
  /// 
  /// [category] - كائن الفئة المراد إضافتها
  Future<void> addCategory(CategoryModel category);
  
  /// تحديث فئة موجودة (للاستخدام الإداري)
  /// 
  /// [category] - كائن الفئة المراد تحديثها
  Future<void> updateCategory(CategoryModel category);
  
  /// حذف فئة (للاستخدام الإداري)
  /// 
  /// [id] - معرف الفئة المراد حذفها
  Future<void> deleteCategory(String id);
}