// lib/core/enums/search_enums.dart

import 'package:flutter/material.dart';

enum SearchType { users, products }

enum SearchResultType {
  user('مستخدم', Icons.person_rounded),
  seller('بائع', Icons.store_rounded),
  product('منتج', Icons.shopping_bag_rounded);

  final String label;
  final IconData icon;
  const SearchResultType(this.label, this.icon);
}

extension SearchTypeExtension on SearchType {
  String get title {
    switch (this) {
      case SearchType.users:    return 'البحث عن بائعين';
      case SearchType.products: return 'البحث عن منتجات';
    }
  }

  String get hintText {
    switch (this) {
      case SearchType.users:    return 'ابحث عن بائع...';
      case SearchType.products: return 'ابحث عن منتج...';
    }
  }
}