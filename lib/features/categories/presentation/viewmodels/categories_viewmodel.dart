// lib/features/categories/presentation/viewmodels/categories_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/categories/data/models/category_model.dart';
import 'package:locaydo_app/features/categories/domain/repositories/category_repository.dart';

class CategoriesViewModel extends ChangeNotifier {
  final Logger _logger;
  final CategoryRepository _categoryRepository;

  List<CategoryModel> _categories = [];
  bool isLoading = false;
  String? errorMessage;

  CategoriesViewModel({
    required Logger logger,
    required CategoryRepository categoryRepository,
  })  : _logger = logger,
        _categoryRepository = categoryRepository {
    loadCategories();
  }

  List<CategoryModel> get categories => _categories;

  Future<void> loadCategories() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _categories = await _categoryRepository.getAllCategories();
      _logger.log('✅ Categories loaded: ${_categories.length}');
    } catch (e) {
      errorMessage = 'فشل تحميل الفئات';
      _logger.error('❌ Failed to load categories', e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}