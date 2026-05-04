// lib/core/enums/favorites_enums.dart

import 'package:flutter/material.dart';

enum FavoritesTab {
  products('المنتجات', Icons.shopping_bag_rounded),
  sellers('البائعين', Icons.people_rounded);

  final String label;
  final IconData icon;
  const FavoritesTab(this.label, this.icon);
}