// test/features/search/search_result_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/enums/search_enums.dart';
import 'package:locaydo_app/features/search/data/models/search_result_model.dart';

void main() {
  group('ProductSearchResult — Model Tests', () {
    test('TC-PSR01: constructor creates valid object with all fields', () {
      final result = ProductSearchResult(
        id: 'prod123',
        title: 'لابتوب ديل',
        price: 500.0,
        currency: '₪',
        imageUrl: 'https://example.com/image.jpg',
        location: 'غزة',
        area: 'الشمال',
        paymentMethods: [PaymentMethod.cash, PaymentMethod.bank],
        isFavorite: true,
        sellerName: 'أحمد محمد',
        sellerAvatarUrl: 'https://example.com/avatar.jpg',
        sellerId: 'seller123',
      );

      expect(result.id, equals('prod123'));
      expect(result.title, equals('لابتوب ديل'));
      expect(result.price, equals(500.0));
      expect(result.currency, equals('₪'));
      expect(result.imageUrl, equals('https://example.com/image.jpg'));
      expect(result.location, equals('غزة'));
      expect(result.area, equals('الشمال'));
      expect(result.paymentMethods.length, equals(2));
      expect(result.paymentMethods, contains(PaymentMethod.cash));
      expect(result.paymentMethods, contains(PaymentMethod.bank));
      expect(result.isFavorite, isTrue);
      expect(result.sellerName, equals('أحمد محمد'));
      expect(result.sellerAvatarUrl, equals('https://example.com/avatar.jpg'));
      expect(result.sellerId, equals('seller123'));
    });

    test('TC-PSR02: isFavorite defaults to false', () {
      final result = ProductSearchResult(
        id: 'prod123',
        title: 'منتج',
        price: 100,
        currency: '₪',
        imageUrl: null,
        location: 'غزة',
        area: 'الوسطى',
        paymentMethods: [],
        sellerName: 'بائع',
      );

      expect(result.isFavorite, isFalse);
    });

    test('TC-PSR03: optional fields can be null', () {
      final result = ProductSearchResult(
        id: 'prod123',
        title: 'منتج',
        price: 100,
        currency: '₪',
        imageUrl: null,
        location: 'غزة',
        area: 'الوسطى',
        paymentMethods: [],
        sellerName: 'بائع',
        sellerAvatarUrl: null,
        sellerId: null,
      );

      expect(result.imageUrl, isNull);
      expect(result.sellerAvatarUrl, isNull);
      expect(result.sellerId, isNull);
    });

    test('TC-PSR04: payment methods can be empty list', () {
      final result = ProductSearchResult(
        id: 'prod123',
        title: 'منتج',
        price: 100,
        currency: '₪',
        imageUrl: null,
        location: 'غزة',
        area: 'الوسطى',
        paymentMethods: [],
        sellerName: 'بائع',
      );

      expect(result.paymentMethods, isEmpty);
    });

    test('TC-PSR05: price can be zero', () {
      final result = ProductSearchResult(
        id: 'prod1',
        title: 'منتج مجاني',
        price: 0.0,
        currency: '₪',
        imageUrl: null,
        location: 'غزة',
        area: 'وسط',
        paymentMethods: [],
        sellerName: 'بائع',
      );

      expect(result.price, equals(0.0));
    });
  });

  group('UserSearchResult — Model Tests', () {
    test('TC-USR01: constructor creates valid object with all fields', () {
      final result = UserSearchResult(
        id: 'user123',
        name: 'أحمد محمد',
        imageUrl: 'https://example.com/avatar.jpg',
        rating: 4.5,
        type: SearchResultType.seller,
      );

      expect(result.id, equals('user123'));
      expect(result.name, equals('أحمد محمد'));
      expect(result.imageUrl, equals('https://example.com/avatar.jpg'));
      expect(result.rating, equals(4.5));
      expect(result.type, equals(SearchResultType.seller));
    });

    test('TC-USR02: imageUrl can be null', () {
      final result = UserSearchResult(
        id: 'user123',
        name: 'أحمد محمد',
        imageUrl: null,
        rating: 0.0,
        type: SearchResultType.user,
      );

      expect(result.imageUrl, isNull);
    });

    test('TC-USR03: rating can be zero', () {
      final result = UserSearchResult(
        id: 'user123',
        name: 'مستخدم جديد',
        imageUrl: null,
        rating: 0.0,
        type: SearchResultType.user,
      );

      expect(result.rating, equals(0.0));
    });

    test('TC-USR04: type can be user or seller', () {
      final userResult = UserSearchResult(
        id: 'user1',
        name: 'مستخدم',
        imageUrl: null,
        rating: 0.0,
        type: SearchResultType.user,
      );
      final sellerResult = UserSearchResult(
        id: 'seller1',
        name: 'بائع',
        imageUrl: null,
        rating: 4.0,
        type: SearchResultType.seller,
      );

      expect(userResult.type, equals(SearchResultType.user));
      expect(sellerResult.type, equals(SearchResultType.seller));
    });

    test('TC-USR05: rating is double but can be integer', () {
      final result = UserSearchResult(
        id: 'user1',
        name: 'مستخدم',
        imageUrl: null,
        rating: 4,
        type: SearchResultType.user,
      );

      expect(result.rating, equals(4.0));
    });
  });
}