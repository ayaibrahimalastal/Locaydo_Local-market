// test/features/search/search_viewmodel_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/enums/search_enums.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/search/data/models/search_result_model.dart';
import 'package:locaydo_app/features/search/presentation/viewmodels/search_viewmodel.dart';

@GenerateMocks([Logger, FirebaseFirestore, CollectionReference, DocumentReference, DocumentSnapshot, QuerySnapshot])
import 'search_viewmodel_test.mocks.dart';

void main() {
  group('SearchViewModel — Unit Tests', () {
    late MockLogger mockLogger;
    late SearchViewModel viewModel;

    setUp(() {
      mockLogger = MockLogger();
      viewModel = SearchViewModel(
        logger: mockLogger,
        searchType: SearchType.products,
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    // ── Initial State Tests ─────────────────────────────────────────────────

    group('Initial State', () {
      test('TC-SV01: initial searchQuery is empty', () {
        expect(viewModel.searchQuery, isEmpty);
      });

      test('TC-SV02: initial isSearching is false', () {
        expect(viewModel.isSearching, isFalse);
      });

      test('TC-SV03: initial isLoading is false', () {
        expect(viewModel.isLoading, isFalse);
      });

      test('TC-SV04: initial hasResults is false', () {
        expect(viewModel.hasResults, isFalse);
      });

      test('TC-SV05: initial filteredUserResults is empty', () {
        expect(viewModel.filteredUserResults, isEmpty);
      });

      test('TC-SV06: initial filteredProductResults is empty', () {
        expect(viewModel.filteredProductResults, isEmpty);
      });
    });

    // ── Search Query Tests ─────────────────────────────────────────────────

    group('Search Query', () {
      test('TC-SV07: setSearchQuery updates query and performs search for products', () {
        viewModel.setSearchQuery('لابتوب');
        
        expect(viewModel.searchQuery, equals('لابتوب'));
        expect(viewModel.isSearching, isTrue);
      });

      test('TC-SV08: setSearchQuery with same query does not trigger duplicate search', () {
        viewModel.setSearchQuery('لابتوب');
        viewModel.setSearchQuery('لابتوب');
        
        expect(viewModel.searchQuery, equals('لابتوب'));
      });

      test('TC-SV09: clearSearch resets all state', () {
        viewModel.setSearchQuery('لابتوب');
        viewModel.clearSearch();
        
        expect(viewModel.searchQuery, isEmpty);
        expect(viewModel.isSearching, isFalse);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.hasResults, isFalse);
        expect(viewModel.filteredProductResults, isEmpty);
        expect(viewModel.filteredUserResults, isEmpty);
      });

      test('TC-SV10: setSearchQuery with empty string clears results', () {
        viewModel.setSearchQuery('');
        
        expect(viewModel.filteredProductResults, isEmpty);
        expect(viewModel.filteredUserResults, isEmpty);
        expect(viewModel.isSearching, isFalse);
      });
    });

    // ── Search Type Tests ──────────────────────────────────────────────────

    group('Search Type', () {
      test('TC-SV11: products search type is set correctly', () {
        final productsViewModel = SearchViewModel(
          logger: mockLogger,
          searchType: SearchType.products,
        );
        
        expect(productsViewModel.searchType, equals(SearchType.products));
        productsViewModel.dispose();
      });

      test('TC-SV12: users search type is set correctly', () {
        final usersViewModel = SearchViewModel(
          logger: mockLogger,
          searchType: SearchType.users,
        );
        
        expect(usersViewModel.searchType, equals(SearchType.users));
        usersViewModel.dispose();
      });
    });

    // ── Favorite Toggle Tests ──────────────────────────────────────────────

    group('Toggle Favorite', () {
      test('TC-SV13: toggleFavorite does not crash on error', () async {
        // Since toggleFavorite uses Firebase directly, we just verify it doesn't crash
        expect(() => viewModel.toggleFavorite('prod1'), returnsNormally);
      });
    });

    // ── Navigation Tests ───────────────────────────────────────────────────

    group('Navigation', () {
      test('TC-SV14: onProductTap does not crash without context', () {
        final product = ProductSearchResult(
          id: 'prod1',
          title: 'منتج',
          price: 100,
          currency: '₪',
          imageUrl: null,
          location: 'غزة',
          area: 'الوسطى',
          paymentMethods: [],
          sellerName: 'بائع',
        );
        
        expect(() => viewModel.onProductTap(product), returnsNormally);
      });

      test('TC-SV15: onUserTap does not crash without context', () {
        final user = UserSearchResult(
          id: 'user1',
          name: 'مستخدم',
          imageUrl: null,
          rating: 0.0,
          type: SearchResultType.seller,
        );
        
        expect(() => viewModel.onUserTap(user), returnsNormally);
      });
    });

    // ── Search Result Model Tests ──────────────────────────────────────────

    group('ProductSearchResult Model', () {
      test('TC-SV16: ProductSearchResult constructor works correctly', () {
        final result = ProductSearchResult(
          id: 'prod123',
          title: 'لابتوب ديل',
          price: 500.0,
          currency: '₪',
          imageUrl: 'https://example.com/img.jpg',
          location: 'غزة',
          area: 'الشمال',
          paymentMethods: [PaymentMethod.cash],
          isFavorite: false,
          sellerName: 'أحمد محمد',
          sellerAvatarUrl: null,
          sellerId: 'user123',
        );

        expect(result.id, equals('prod123'));
        expect(result.title, equals('لابتوب ديل'));
        expect(result.price, equals(500.0));
        expect(result.location, equals('غزة'));
        expect(result.paymentMethods, contains(PaymentMethod.cash));
        expect(result.isFavorite, isFalse);
      });

      test('TC-SV17: isFavorite defaults to false', () {
        final result = ProductSearchResult(
          id: 'prod1',
          title: 'منتج',
          price: 100,
          currency: '₪',
          imageUrl: null,
          location: 'غزة',
          area: 'وسط',
          paymentMethods: [],
          sellerName: 'بائع',
        );

        expect(result.isFavorite, isFalse);
      });
    });

    group('UserSearchResult Model', () {
      test('TC-SV18: UserSearchResult constructor works correctly', () {
        final result = UserSearchResult(
          id: 'user123',
          name: 'أحمد محمد',
          imageUrl: 'https://example.com/avatar.jpg',
          rating: 4.5,
          type: SearchResultType.seller,
        );

        expect(result.id, equals('user123'));
        expect(result.name, equals('أحمد محمد'));
        expect(result.rating, equals(4.5));
        expect(result.type, equals(SearchResultType.seller));
      });

      test('TC-SV19: imageUrl can be null', () {
        final result = UserSearchResult(
          id: 'user1',
          name: 'مستخدم',
          imageUrl: null,
          rating: 0.0,
          type: SearchResultType.seller,
        );

        expect(result.imageUrl, isNull);
      });
    });

    // ── Enums and Extensions Tests ─────────────────────────────────────────

    group('SearchType Extension', () {
      test('TC-SV20: SearchType.users title is correct', () {
        expect(SearchType.users.title, equals('البحث عن بائعين'));
      });

      test('TC-SV21: SearchType.products title is correct', () {
        expect(SearchType.products.title, equals('البحث عن منتجات'));
      });

      test('TC-SV22: SearchType.users hintText is correct', () {
        expect(SearchType.users.hintText, equals('ابحث عن بائع...'));
      });

      test('TC-SV23: SearchType.products hintText is correct', () {
        expect(SearchType.products.hintText, equals('ابحث عن منتج...'));
      });
    });

    group('SearchResultType', () {
      test('TC-SV24: SearchResultType.user label is correct', () {
        expect(SearchResultType.user.label, equals('مستخدم'));
      });

      test('TC-SV25: SearchResultType.seller label is correct', () {
        expect(SearchResultType.seller.label, equals('بائع'));
      });

      test('TC-SV26: SearchResultType.product label is correct', () {
        expect(SearchResultType.product.label, equals('منتج'));
      });

      test('TC-SV27: SearchResultType.user icon is Icons.person_rounded', () {
        expect(SearchResultType.user.icon, equals(Icons.person_rounded));
      });

      test('TC-SV28: SearchResultType.seller icon is Icons.store_rounded', () {
        expect(SearchResultType.seller.icon, equals(Icons.store_rounded));
      });

      test('TC-SV29: SearchResultType.product icon is Icons.shopping_bag_rounded', () {
        expect(SearchResultType.product.icon, equals(Icons.shopping_bag_rounded));
      });
    });
  });
}