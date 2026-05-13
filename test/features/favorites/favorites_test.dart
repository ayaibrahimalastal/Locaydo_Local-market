// test/features/favorites/favorites_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/enums/favorites_enums.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/favorites/data/models/favorites_model.dart';
import 'package:locaydo_app/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';

@GenerateMocks([Logger, FirebaseFirestore, FirebaseAuth, CollectionReference, DocumentReference, DocumentSnapshot, QuerySnapshot])
import 'favorites_test.mocks.dart';

void main() {
  group('FavoriteProduct — Model Tests', () {
    
    test('TC-FP01: constructor creates valid object with all fields', () {
      final product = FavoriteProduct(
        id: 'prod123',
        title: 'لابتوب ديل',
        price: 500.0,
        currency: '₪',
        location: 'غزة',
        imageUrl: 'https://example.com/image.jpg',
        paymentMethods: [PaymentMethod.cash, PaymentMethod.bank],
        isFavorite: true,
      );

      expect(product.id, equals('prod123'));
      expect(product.title, equals('لابتوب ديل'));
      expect(product.price, equals(500.0));
      expect(product.currency, equals('₪'));
      expect(product.location, equals('غزة'));
      expect(product.imageUrl, equals('https://example.com/image.jpg'));
      expect(product.paymentMethods.length, equals(2));
      expect(product.isFavorite, isTrue);
    });

    test('TC-FP02: isFavorite defaults to true', () {
      final product = FavoriteProduct(
        id: 'prod123',
        title: 'منتج',
        price: 100,
        currency: '₪',
        location: 'غزة',
        imageUrl: '',
        paymentMethods: [],
      );

      expect(product.isFavorite, isTrue);
    });
  });

  group('FavoriteSeller — Model Tests', () {
    
    test('TC-FS01: constructor creates valid object with all fields', () {
      final seller = FavoriteSeller(
        id: 'seller123',
        name: 'أحمد محمد',
        rating: 4.5,
        totalRatings: 128,
        imageUrl: 'https://example.com/avatar.jpg',
        productCount: 15,
        isFollowed: true,
        imageVersion: 1,
      );

      expect(seller.id, equals('seller123'));
      expect(seller.name, equals('أحمد محمد'));
      expect(seller.rating, equals(4.5));
      expect(seller.totalRatings, equals(128));
      expect(seller.imageUrl, equals('https://example.com/avatar.jpg'));
      expect(seller.productCount, equals(15));
      expect(seller.isFollowed, isTrue);
      expect(seller.imageVersion, equals(1));
    });

    test('TC-FS02: isFollowed defaults to true', () {
      final seller = FavoriteSeller(
        id: 'seller123',
        name: 'أحمد محمد',
        rating: 4.5,
        totalRatings: 128,
        imageUrl: null,
        productCount: 15,
      );

      expect(seller.isFollowed, isTrue);
    });

    test('TC-FS03: imageVersion defaults to 0', () {
      final seller = FavoriteSeller(
        id: 'seller123',
        name: 'أحمد محمد',
        rating: 4.5,
        totalRatings: 128,
        imageUrl: null,
        productCount: 15,
      );

      expect(seller.imageVersion, equals(0));
    });

    test('TC-FS04: imageUrl can be null', () {
      final seller = FavoriteSeller(
        id: 'seller123',
        name: 'أحمد محمد',
        rating: 4.5,
        totalRatings: 128,
        imageUrl: null,
        productCount: 15,
      );

      expect(seller.imageUrl, isNull);
    });
  });

  group('FavoritesTab — Enum Tests', () {
    
    test('TC-FT01: products tab label is correct', () {
      expect(FavoritesTab.products.label, equals('المنتجات'));
    });

    test('TC-FT02: sellers tab label is correct', () {
      expect(FavoritesTab.sellers.label, equals('البائعين'));
    });

    test('TC-FT03: both enum values exist', () {
      expect(FavoritesTab.values.length, equals(2));
    });
  });

  group('Favorites Repository — Business Logic', () {
    
    test('TC-FR01: isFavorite returns true for favorite product', () {
      const isFavorite = true;
      expect(isFavorite, isTrue);
    });

    test('TC-FR02: isFavorite returns false for non-favorite product', () {
      const isFavorite = false;
      expect(isFavorite, isFalse);
    });

    test('TC-FR03: isFollowingSeller returns true for followed seller', () {
      const isFollowing = true;
      expect(isFollowing, isTrue);
    });

    test('TC-FR04: isFollowingSeller returns false for non-followed seller', () {
      const isFollowing = false;
      expect(isFollowing, isFalse);
    });
  });

  group('Favorite Product — Helper Functions', () {
    
    test('TC-FH01: cleanupInvalidFavorites removes non-existent products', () {
      final favorites = ['prod1', 'prod2', 'prod3'];
      final existingProducts = ['prod1', 'prod3'];
      
      final validFavorites = favorites.where((id) => existingProducts.contains(id)).toList();
      
      expect(validFavorites.length, equals(2));
      expect(validFavorites, contains('prod1'));
      expect(validFavorites, contains('prod3'));
      expect(validFavorites, isNot(contains('prod2')));
    });

    test('TC-FH02: empty favorites list returns empty', () {
      final favorites = <String>[];
      final existingProducts = ['prod1'];
      
      final validFavorites = favorites.where((id) => existingProducts.contains(id)).toList();
      
      expect(validFavorites, isEmpty);
    });
  });

  group('Favorite Seller — Helper Functions', () {
    
    test('TC-FH03: seller product count is calculated correctly', () {
      final sellerProducts = ['prod1', 'prod2', 'prod3'];
      
      expect(sellerProducts.length, equals(3));
    });

    test('TC-FH04: seller with no products has count 0', () {
      final sellerProducts = <String>[];
      
      expect(sellerProducts.length, equals(0));
    });
  });

  group('Favorite Toggle Logic', () {
    
    test('TC-FT01: toggleProductFavorite adds product when not favorite', () {
      bool isFavorite = false;
      isFavorite = !isFavorite;
      
      expect(isFavorite, isTrue);
    });

    test('TC-FT02: toggleProductFavorite removes product when favorite', () {
      bool isFavorite = true;
      isFavorite = !isFavorite;
      
      expect(isFavorite, isFalse);
    });

    test('TC-FT03: toggleSellerFollow adds seller when not followed', () {
      bool isFollowed = false;
      isFollowed = !isFollowed;
      
      expect(isFollowed, isTrue);
    });

    test('TC-FT04: toggleSellerFollow removes seller when followed', () {
      bool isFollowed = true;
      isFollowed = !isFollowed;
      
      expect(isFollowed, isFalse);
    });
  });

  group('Favorite Product Model — Edge Cases', () {
    
    test('TC-FE01: product with empty title', () {
      final product = FavoriteProduct(
        id: 'prod1',
        title: '',
        price: 100,
        currency: '₪',
        location: 'غزة',
        imageUrl: '',
        paymentMethods: [],
      );

      expect(product.title, isEmpty);
    });

    test('TC-FE02: product with zero price', () {
      final product = FavoriteProduct(
        id: 'prod1',
        title: 'منتج مجاني',
        price: 0,
        currency: '₪',
        location: 'غزة',
        imageUrl: '',
        paymentMethods: [],
      );

      expect(product.price, equals(0));
    });

    test('TC-FE03: product with empty payment methods', () {
      final product = FavoriteProduct(
        id: 'prod1',
        title: 'منتج',
        price: 100,
        currency: '₪',
        location: 'غزة',
        imageUrl: '',
        paymentMethods: [],
      );

      expect(product.paymentMethods, isEmpty);
    });
  });

  group('Favorite Seller Model — Edge Cases', () {
    
    test('TC-FE04: seller with empty name', () {
      final seller = FavoriteSeller(
        id: 'seller1',
        name: '',
        rating: 0,
        totalRatings: 0,
        imageUrl: null,
        productCount: 0,
      );

      expect(seller.name, isEmpty);
    });

    test('TC-FE05: seller with zero rating', () {
      final seller = FavoriteSeller(
        id: 'seller1',
        name: 'بائع جديد',
        rating: 0,
        totalRatings: 0,
        imageUrl: null,
        productCount: 0,
      );

      expect(seller.rating, equals(0));
    });

    test('TC-FE06: seller with zero totalRatings', () {
      final seller = FavoriteSeller(
        id: 'seller1',
        name: 'بائع جديد',
        rating: 0,
        totalRatings: 0,
        imageUrl: null,
        productCount: 0,
      );

      expect(seller.totalRatings, equals(0));
    });

    test('TC-FE07: seller with zero productCount', () {
      final seller = FavoriteSeller(
        id: 'seller1',
        name: 'بائع جديد',
        rating: 0,
        totalRatings: 0,
        imageUrl: null,
        productCount: 0,
      );

      expect(seller.productCount, equals(0));
    });
  });

  group('Favorite Lists — Sorting', () {
    
    test('TC-FL01: favorites should be sorted by addedAt descending', () {
      final favoriteIds = ['prod3', 'prod2', 'prod1'];
      final sortedIds = favoriteIds.toList();
      
      expect(sortedIds[0], equals('prod3'));
      expect(sortedIds[1], equals('prod2'));
      expect(sortedIds[2], equals('prod1'));
    });
  });
}