// lib/features/categories/data/repositories/category_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/categories/data/models/category_model.dart';
import 'package:locaydo_app/features/categories/domain/repositories/category_repository.dart';

/// تنفيذ مستودع الفئات باستخدام Firebase Firestore
class CategoryRepositoryImpl implements CategoryRepository {
  final FirebaseFirestore _firestore;
  final Logger _logger;

  CategoryRepositoryImpl({
    required Logger logger,
    FirebaseFirestore? firestore,
  })  : _logger = logger,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      _logger.log('📂 Fetching all categories from Firestore...');
      
      final snapshot = await _firestore
          .collection('categories')
          .orderBy('order', descending: false)
          .get();

      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();

      _logger.log('✅ Successfully loaded ${categories.length} categories');
      return categories;
    } catch (e) {
      _logger.error('❌ Failed to load categories', e);
      return [];
    }
  }

  @override
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      _logger.log('🔍 Fetching category by id: $id');
      
      final doc = await _firestore.collection('categories').doc(id).get();
      
      if (doc.exists) {
        _logger.log('✅ Category found: ${doc.id}');
        return CategoryModel.fromFirestore(doc);
      } else {
        _logger.log('⚠️ Category not found: $id');
        return null;
      }
    } catch (e) {
      _logger.error('❌ Failed to get category by id: $id', e);
      return null;
    }
  }

  @override
  Future<List<CategoryModel>> getActiveCategories() async {
    try {
      _logger.log('📂 Fetching active categories from Firestore...');
      
      final snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order', descending: false)
          .get();

      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();

      _logger.log('✅ Successfully loaded ${categories.length} active categories');
      return categories;
    } catch (e) {
      _logger.error('❌ Failed to load active categories', e);
      return [];
    }
  }

  @override
  Future<void> addCategory(CategoryModel category) async {
    try {
      _logger.log('➕ Adding new category: ${category.name}');
      
      await _firestore
          .collection('categories')
          .doc(category.id)
          .set(category.toFirestore());
      
      _logger.log('✅ Category added successfully: ${category.id}');
    } catch (e) {
      _logger.error('❌ Failed to add category: ${category.name}', e);
      rethrow;
    }
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    try {
      _logger.log('✏️ Updating category: ${category.id}');
      
      await _firestore
          .collection('categories')
          .doc(category.id)
          .update(category.toFirestore());
      
      _logger.log('✅ Category updated successfully: ${category.id}');
    } catch (e) {
      _logger.error('❌ Failed to update category: ${category.id}', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      _logger.log('🗑️ Deleting category: $id');
      
      await _firestore.collection('categories').doc(id).delete();
      
      _logger.log('✅ Category deleted successfully: $id');
    } catch (e) {
      _logger.error('❌ Failed to delete category: $id', e);
      rethrow;
    }
  }
}