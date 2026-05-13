// test/features/seller/seller_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/features/products/data/models/seller_product_model.dart';
import 'package:locaydo_app/features/seller/data/models/seller_model.dart';
import 'package:locaydo_app/features/seller/presentation/screens/seller_profile_screen.dart';
import 'package:locaydo_app/features/seller/presentation/views/seller_all_products_view.dart';

void main() {
  group('SellerModel — fromFirestore / toFirestore', () {
    
    test('TC-SM01: toFirestore returns correct map structure', () {
      final now = DateTime.now();
      final model = SellerModel(
        id: 'seller123',
        userId: 'user123',
        name: 'أحمد محمد',
        phone: '0599123456',
        avatarUrl: 'https://example.com/avatar.jpg',
        countryCode: '+970',
        createdAt: now,
        updatedAt: now,
      );

      final map = model.toFirestore();

      expect(map['userId'], equals('user123'));
      expect(map['name'], equals('أحمد محمد'));
      expect(map['phone'], equals('0599123456'));
      expect(map['avatarUrl'], equals('https://example.com/avatar.jpg'));
      expect(map['countryCode'], equals('+970'));
      expect(map.containsKey('createdAt'), isTrue);
      expect(map.containsKey('updatedAt'), isTrue);
    });

    test('TC-SM02: optional fields can be null', () {
      final now = DateTime.now();
      final model = SellerModel(
        id: 'seller123',
        userId: 'user123',
        name: 'أحمد محمد',
        phone: '0599123456',
        avatarUrl: null,
        countryCode: null,
        createdAt: now,
        updatedAt: now,
      );

      expect(model.avatarUrl, isNull);
      expect(model.countryCode, isNull);
    });
  });

  group('SellerData — Model Tests', () {
    
    test('TC-SD01: constructor creates valid object with all fields', () {
      final now = DateTime.now();
      final mockProduct = ProductModel(
        id: 'prod1',
        title: 'لابتوب ديل',
        description: 'لابتوب بحالة ممتازة',
        price: 500.0,
        currency: '₪',
        location: 'غزة',
        imageUrl: '',
        additionalImages: [],
        category: ProductCategory.electronics,
        condition: ProductCondition.new_,
        paymentMethods: [],
        sellerId: 'seller1',
        sellerName: 'أحمد محمد',
        createdAt: now,
        status: ProductStatus.available,
      );

      final sellerData = SellerData(
        id: 'seller123',
        name: 'أحمد محمد',
        rating: 4.5,
        totalRatings: 128,
        imageUrl: 'https://example.com/avatar.jpg',
        phoneNumber: '0599123456',
        whatsappNumber: '0599123456',
        availableProducts: [mockProduct],
        soldProducts: [],
        userId: 'user123',
        countryCode: '+970',
      );

      expect(sellerData.id, equals('seller123'));
      expect(sellerData.name, equals('أحمد محمد'));
      expect(sellerData.rating, equals(4.5));
      expect(sellerData.totalRatings, equals(128));
      expect(sellerData.availableProducts.length, equals(1));
      expect(sellerData.soldProducts, isEmpty);
      expect(sellerData.userId, equals('user123'));
    });

    test('TC-SD02: empty factory creates default values', () {
      final emptyData = SellerData.empty();

      expect(emptyData.id, isEmpty);
      expect(emptyData.name, isEmpty);
      expect(emptyData.rating, equals(0));
      expect(emptyData.totalRatings, equals(0));
      expect(emptyData.availableProducts, isEmpty);
      expect(emptyData.soldProducts, isEmpty);
      expect(emptyData.countryCode, equals('+970'));
    });
  });

  group('Seller Helpers — Phone Formatting', () {
    
    test('TC-SH01: cleanNumber removes non-digit characters', () {
      String cleanNumber(String number) {
        return number.replaceAll(RegExp(r'[^0-9]'), '');
      }
      
      expect(cleanNumber('0599-123-456'), equals('0599123456'));
      expect(cleanNumber('(0599) 123456'), equals('0599123456'));
      expect(cleanNumber('+970599123456'), equals('970599123456'));
    });

    test('TC-SH02: removeLeadingZero removes zero from start', () {
      String removeLeadingZero(String number) {
        var clean = number.replaceAll(RegExp(r'[^0-9]'), '');
        if (clean.startsWith('0')) clean = clean.substring(1);
        return clean;
      }
      
      expect(removeLeadingZero('0599123456'), equals('599123456'));
      expect(removeLeadingZero('599123456'), equals('599123456'));
    });

    test('TC-SH03: buildFullNumber combines country code and number', () {
      String buildFullNumber(String countryCode, String number) {
        var cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanNumber.startsWith('0')) cleanNumber = cleanNumber.substring(1);
        return '$countryCode$cleanNumber';
      }
      
      expect(buildFullNumber('+970', '0599123456'), equals('+970599123456'));
      expect(buildFullNumber('+972', '599123456'), equals('+972599123456'));
    });
  });

  group('Seller Helpers — Date Formatting', () {
    
    String formatDate(DateTime date) {
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays > 365) return '${(difference.inDays / 365).floor()} سنة';
      if (difference.inDays > 30) return '${(difference.inDays / 30).floor()} شهر';
      if (difference.inDays > 0) return '${difference.inDays} يوم';
      if (difference.inHours > 0) return '${difference.inHours} ساعة';
      if (difference.inMinutes > 0) return '${difference.inMinutes} دقيقة';
      return 'الآن';
    }

    test('TC-SH04: formatDate returns "الآن" for current time', () {
      final now = DateTime.now();
      expect(formatDate(now), equals('الآن'));
    });

    test('TC-SH05: formatDate returns minutes ago', () {
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      expect(formatDate(fiveMinutesAgo), equals('5 دقيقة'));
    });

    test('TC-SH06: formatDate returns hours ago', () {
      final now = DateTime.now();
      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      expect(formatDate(twoHoursAgo), equals('2 ساعة'));
    });

    test('TC-SH07: formatDate returns days ago', () {
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      expect(formatDate(threeDaysAgo), equals('3 يوم'));
    });
  });

  group('Seller Helpers — Product Filtering', () {
    
    test('TC-SH08: filter available products returns only available', () {
      final now = DateTime.now();
      
      final availableProduct = ProductModel(
        id: 'prod1',
        title: 'لابتوب متاح',
        description: 'وصف',
        price: 500,
        currency: '₪',
        location: 'غزة',
        imageUrl: '',
        additionalImages: [],
        category: ProductCategory.electronics,
        condition: ProductCondition.new_,
        paymentMethods: [],
        sellerId: 'seller1',
        sellerName: 'بائع',
        createdAt: now,
        status: ProductStatus.available,
      );

      final soldProduct = ProductModel(
        id: 'prod2',
        title: 'لابتوب مباع',
        description: 'وصف',
        price: 300,
        currency: '₪',
        location: 'غزة',
        imageUrl: '',
        additionalImages: [],
        category: ProductCategory.electronics,
        condition: ProductCondition.used,
        paymentMethods: [],
        sellerId: 'seller1',
        sellerName: 'بائع',
        createdAt: now,
        status: ProductStatus.sold,
      );

      final available = [availableProduct, soldProduct]
          .where((p) => p.status == ProductStatus.available)
          .toList();
      
      expect(available.length, equals(1));
      expect(available[0].title, equals('لابتوب متاح'));
    });

    test('TC-SH09: filter sold products returns only sold', () {
      final now = DateTime.now();
      
      final availableProduct = ProductModel(
        id: 'prod1',
        title: 'لابتوب متاح',
        description: 'وصف',
        price: 500,
        currency: '₪',
        location: 'غزة',
        imageUrl: '',
        additionalImages: [],
        category: ProductCategory.electronics,
        condition: ProductCondition.new_,
        paymentMethods: [],
        sellerId: 'seller1',
        sellerName: 'بائع',
        createdAt: now,
        status: ProductStatus.available,
      );

      final soldProduct = ProductModel(
        id: 'prod2',
        title: 'لابتوب مباع',
        description: 'وصف',
        price: 300,
        currency: '₪',
        location: 'غزة',
        imageUrl: '',
        additionalImages: [],
        category: ProductCategory.electronics,
        condition: ProductCondition.used,
        paymentMethods: [],
        sellerId: 'seller1',
        sellerName: 'بائع',
        createdAt: now,
        status: ProductStatus.sold,
      );

      final sold = [availableProduct, soldProduct]
          .where((p) => p.status == ProductStatus.sold)
          .toList();
      
      expect(sold.length, equals(1));
      expect(sold[0].title, equals('لابتوب مباع'));
    });
  });

  group('SellerAllProductsType — Enum Tests', () {
    
    test('TC-SE01: available type value is correct', () {
      expect(SellerAllProductsType.available.toString(), contains('available'));
    });

    test('TC-SE02: sold type value is correct', () {
      expect(SellerAllProductsType.sold.toString(), contains('sold'));
    });

    test('TC-SE03: both enum values exist', () {
      expect(SellerAllProductsType.values.length, equals(2));
    });
  });

  group('Star Rating — Display Logic', () {
    
    test('TC-SR01: calculate full stars correctly for rating 4.5', () {
      final rating = 4.5;
      final fullStars = rating.floor();
      final hasHalfStar = (rating - fullStars) >= 0.5;
      
      expect(fullStars, equals(4));
      expect(hasHalfStar, isTrue);
    });

    test('TC-SR02: calculate full stars correctly for rating 4.0', () {
      final rating = 4.0;
      final fullStars = rating.floor();
      final hasHalfStar = (rating - fullStars) >= 0.5;
      
      expect(fullStars, equals(4));
      expect(hasHalfStar, isFalse);
    });

    test('TC-SR03: calculate full stars correctly for rating 5.0', () {
      final rating = 5.0;
      final fullStars = rating.floor();
      
      expect(fullStars, equals(5));
    });

    test('TC-SR04: calculate full stars correctly for rating 0.0', () {
      final rating = 0.0;
      final fullStars = rating.floor();
      
      expect(fullStars, equals(0));
    });

    test('TC-SR05: star colors are correct', () {
      expect(AppColors.warning, equals(const Color(0xFFFFA726)));
      expect(AppColors.textPlaceholder, equals(const Color(0xFF969696)));
    });
  });
}