// lib/features/search/domain/repositories/search_repository.dart

import 'package:locaydo_app/features/search/data/models/search_result_model.dart';

abstract class SearchRepository {
  Future<List<UserSearchResult>> searchUsers(String query);
  Future<List<ProductSearchResult>> searchProducts(String query);
}