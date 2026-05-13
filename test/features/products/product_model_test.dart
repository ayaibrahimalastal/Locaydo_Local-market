// test/features/products/product_model_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/features/products/data/models/product_model.dart';
import 'package:locaydo_app/features/products/data/models/seller_product_model.dart';

void main() {
  group('ProductModel — fromMap / toMap', () {
    final Map<String, dynamic> validMap = {
      'title': 'لابتوب ديل',
      'description': 'لابتوب بحالة ممتازة',
      'price': 500.0,
      'currency': '₪',
      'location': 'شمال غزة',
      'imageUrl': 'https://cloudinary.com/img.jpg',
      'additionalImages': [],
      'category': 'electronics',
      'condition': 'new',
      'paymentMethods': ['cash'],
      'sellerId': 'user123',
      'sellerName': 'أيا الأسطل',
      'createdAt': null,
      'status': 'available',
    };

    test('TC-M01: fromMap parses category correctly', () {
      final product = ProductModel.fromMap(validMap, 'doc123');
      expect(product.category, equals(ProductCategory.electronics));
    });

    test('TC-M02: fromMap parses condition correctly', () {
      final product = ProductModel.fromMap(validMap, 'doc123');
      expect(product.condition, equals(ProductCondition.new_));
    });

    test('TC-M03: fromMap parses payment methods correctly', () {
      final product = ProductModel.fromMap(validMap, 'doc123');
      expect(product.paymentMethods, contains(PaymentMethod.cash));
    });

    test('TC-M04: fromMap parses available status correctly', () {
      final product = ProductModel.fromMap(validMap, 'doc123');
      expect(product.status, equals(ProductStatus.available));
    });

    test('TC-M05: fromMap parses sold status correctly', () {
      final soldMap = Map<String, dynamic>.from(validMap)
        ..['status'] = 'sold';
      final product = ProductModel.fromMap(soldMap, 'doc123');
      expect(product.status, equals(ProductStatus.sold));
    });

    test('TC-M06: toMap uses .name for category', () {
      final product = ProductModel.fromMap(validMap, 'doc123');
      final map = product.toMap();
      expect(map['category'], equals('electronics'));
    });

    test('TC-M07: toMap uses .name for condition', () {
      final product = ProductModel.fromMap(validMap, 'doc123');
      final map = product.toMap();
      expect(map['condition'], equals('new'));
    });

    test('TC-M08: toMap uses .name for payment methods', () {
      final product = ProductModel.fromMap(validMap, 'doc123');
      final map = product.toMap();
      expect(map['paymentMethods'], contains('cash'));
    });

    test('TC-M09: toMap uses .name for status', () {
      final product = ProductModel.fromMap(validMap, 'doc123');
      final map = product.toMap();
      expect(map['status'], equals('available'));
    });

    test('TC-M10: isSold returns true for sold products', () {
      final soldMap = Map<String, dynamic>.from(validMap)
        ..['status'] = 'sold';
      final product = ProductModel.fromMap(soldMap, 'doc123');
      expect(product.isSold, isTrue);
    });

    test('TC-M11: isAvailable returns true for available products', () {
      final product = ProductModel.fromMap(validMap, 'doc123');
      expect(product.isAvailable, isTrue);
    });

    test('TC-M12: copyWith updates only specified fields', () {
      final product = ProductModel.fromMap(validMap, 'doc123');
      final updated = product.copyWith(title: 'اسم جديد');
      expect(updated.title, equals('اسم جديد'));
      expect(updated.price, equals(product.price));
      expect(updated.category, equals(product.category));
    });

    test('TC-M13: copyWith with null values keeps original', () {
      final product = ProductModel.fromMap(validMap, 'doc123');
      final updated = product.copyWith();
      expect(updated.title, equals(product.title));
      expect(updated.price, equals(product.price));
    });

    test('TC-M14: equality by id', () {
      final p1 = ProductModel.fromMap(validMap, 'doc123');
      final p2 = ProductModel.fromMap(validMap, 'doc123');
      final p3 = ProductModel.fromMap(validMap, 'doc999');
      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });

    test('TC-M15: hashCode is based on id', () {
      final p1 = ProductModel.fromMap(validMap, 'doc123');
      final p2 = ProductModel.fromMap(validMap, 'doc123');
      expect(p1.hashCode, equals(p2.hashCode));
    });

    test('TC-M16: toString returns formatted string', () {
      final product = ProductModel.fromMap(validMap, 'doc123');
      final str = product.toString();
      expect(str, contains('ProductModel'));
      expect(str, contains('doc123'));
      expect(str, contains('لابتوب ديل'));
    });
  });

  group('SellerProduct — fromMap / toMap', () {
    final Map<String, dynamic> validMap = {
      'title': 'لابتوب ديل',
      'description': 'لابتوب بحالة ممتازة',
      'price': 500.0,
      'currency': '₪',
      'location': 'شمال غزة',
      'imageUrl': 'https://cloudinary.com/img.jpg',
      'additionalImages': [],
      'paymentMethods': ['cash'],
      'category': 'electronics',
      'condition': 'new',
      'status': 'available',
      'createdAt': null,
      'soldAt': null,
      'sellerId': 'seller123',
      'userId': 'user123',
    };

    test('TC-S01: fromMap parses category correctly', () {
      final product = SellerProduct.fromMap(validMap, 'doc123');
      expect(product.category, equals(ProductCategory.electronics));
    });

    test('TC-S02: fromMap parses condition correctly', () {
      final product = SellerProduct.fromMap(validMap, 'doc123');
      expect(product.condition, equals(ProductCondition.new_));
    });

    test('TC-S03: fromMap parses payment methods correctly', () {
      final product = SellerProduct.fromMap(validMap, 'doc123');
      expect(product.paymentMethods, contains(PaymentMethod.cash));
    });

    test('TC-S04: fromMap parses available status correctly', () {
      final product = SellerProduct.fromMap(validMap, 'doc123');
      expect(product.status, equals(ProductStatus.available));
    });

    test('TC-S05: fromMap parses sellerId correctly', () {
      final product = SellerProduct.fromMap(validMap, 'doc123');
      expect(product.sellerId, equals('seller123'));
    });

    test('TC-S06: fromMap uses userId as fallback for sellerId', () {
      final mapWithoutSellerId = Map<String, dynamic>.from(validMap)
        ..remove('sellerId');
      final product = SellerProduct.fromMap(mapWithoutSellerId, 'doc123');
      expect(product.sellerId, equals('user123'));
    });

    test('TC-S07: toMap uses .name for category', () {
      final product = SellerProduct.fromMap(validMap, 'doc123');
      final map = product.toMap();
      expect(map['category'], equals('electronics'));
    });

    test('TC-S08: toMap uses .name for condition', () {
      final product = SellerProduct.fromMap(validMap, 'doc123');
      final map = product.toMap();
      expect(map['condition'], equals('new'));
    });

    test('TC-S09: toMap uses .name for payment methods', () {
      final product = SellerProduct.fromMap(validMap, 'doc123');
      final map = product.toMap();
      expect(map['paymentMethods'], contains('cash'));
    });

    test('TC-S10: toMap uses correct status string', () {
      final product = SellerProduct.fromMap(validMap, 'doc123');
      final map = product.toMap();
      expect(map['status'], equals('available'));
    });

    test('TC-S11: isSold returns true for sold products', () {
      final soldMap = Map<String, dynamic>.from(validMap)
        ..['status'] = 'sold';
      final product = SellerProduct.fromMap(soldMap, 'doc123');
      expect(product.isSold, isTrue);
    });

    test('TC-S12: isAvailable returns true for available products', () {
      final product = SellerProduct.fromMap(validMap, 'doc123');
      expect(product.isAvailable, isTrue);
    });

    test('TC-S13: copyWith updates only specified fields', () {
      final product = SellerProduct.fromMap(validMap, 'doc123');
      final updated = product.copyWith(title: 'اسم جديد');
      expect(updated.title, equals('اسم جديد'));
      expect(updated.price, equals(product.price));
    });

    test('TC-S14: copyWith with null values keeps original', () {
      final product = SellerProduct.fromMap(validMap, 'doc123');
      final updated = product.copyWith();
      expect(updated.title, equals(product.title));
      expect(updated.price, equals(product.price));
    });

    test('TC-S15: equality by id', () {
      final p1 = SellerProduct.fromMap(validMap, 'doc123');
      final p2 = SellerProduct.fromMap(validMap, 'doc123');
      final p3 = SellerProduct.fromMap(validMap, 'doc999');
      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });

    test('TC-S16: toString returns formatted string', () {
      final product = SellerProduct.fromMap(validMap, 'doc123');
      final str = product.toString();
      expect(str, contains('SellerProduct'));
      expect(str, contains('doc123'));
      expect(str, contains('seller123'));
    });
  });

  group('SellerProduct — toProductModel', () {
    final Map<String, dynamic> validMap = {
      'title': 'لابتوب ديل',
      'description': 'لابتوب بحالة ممتازة',
      'price': 500.0,
      'currency': '₪',
      'location': 'شمال غزة',
      'imageUrl': 'https://cloudinary.com/img.jpg',
      'additionalImages': [],
      'paymentMethods': ['cash'],
      'category': 'electronics',
      'condition': 'new',
      'status': 'available',
      'createdAt': null,
      'soldAt': null,
      'sellerId': 'seller123',
    };

    test('TC-P01: toProductModel converts SellerProduct to ProductModel correctly', () {
      final sellerProduct = SellerProduct.fromMap(validMap, 'doc123');
      final productModel = sellerProduct.toProductModel(sellerName: 'أيا الأسطل');
      
      expect(productModel.id, equals(sellerProduct.id));
      expect(productModel.title, equals(sellerProduct.title));
      expect(productModel.price, equals(sellerProduct.price));
      expect(productModel.category, equals(sellerProduct.category));
      expect(productModel.condition, equals(sellerProduct.condition));
      expect(productModel.sellerId, equals(sellerProduct.sellerId));
      expect(productModel.sellerName, equals('أيا الأسطل'));
      expect(productModel.status, equals(sellerProduct.status));
    });

    test('TC-P02: toProductModel preserves all fields', () {
      final sellerProduct = SellerProduct.fromMap(validMap, 'doc123');
      final productModel = sellerProduct.toProductModel(sellerName: 'أيا الأسطل');
      
      expect(productModel.description, equals(sellerProduct.description));
      expect(productModel.currency, equals(sellerProduct.currency));
      expect(productModel.location, equals(sellerProduct.location));
      expect(productModel.imageUrl, equals(sellerProduct.imageUrl));
      expect(productModel.additionalImages, equals(sellerProduct.additionalImages));
      expect(productModel.paymentMethods, equals(sellerProduct.paymentMethods));
      expect(productModel.createdAt, equals(sellerProduct.createdAt));
    });
  });

  group('ProductCategory — fromString', () {
    test('TC-C01: fromString returns correct enum value from name', () {
      expect(ProductCategory.fromString('electronics'), equals(ProductCategory.electronics));
      expect(ProductCategory.fromString('clothes'), equals(ProductCategory.clothes));
      expect(ProductCategory.fromString('donation'), equals(ProductCategory.donation));
    });

    test('TC-C02: fromString returns correct enum value from label', () {
      expect(ProductCategory.fromString('أجهزة'), equals(ProductCategory.electronics));
      expect(ProductCategory.fromString('ملابس'), equals(ProductCategory.clothes));
      expect(ProductCategory.fromString('تبرعات'), equals(ProductCategory.donation));
    });

    test('TC-C03: fromString returns ProductCategory.all for unknown value', () {
      expect(ProductCategory.fromString('unknown_xyz'), equals(ProductCategory.all));
    });
  });

  group('ProductCondition — fromString', () {
    test('TC-C04: fromString parses new_ correctly from name', () {
      expect(ProductCondition.fromString('new'), equals(ProductCondition.new_));
    });

    test('TC-C05: fromString parses new_ correctly from label', () {
      expect(ProductCondition.fromString('جديد'), equals(ProductCondition.new_));
    });

    test('TC-C06: fromString parses used correctly', () {
      expect(ProductCondition.fromString('used'), equals(ProductCondition.used));
      expect(ProductCondition.fromString('مستعمل'), equals(ProductCondition.used));
    });

    test('TC-C07: new_ name is "new" (not "newItem")', () {
      expect(ProductCondition.new_.name, equals('new'));
    });
  });

  group('PaymentMethod — fromString', () {
    test('TC-C08: fromString cash from name', () {
      expect(PaymentMethod.fromString('cash'), equals(PaymentMethod.cash));
    });

    test('TC-C09: fromString cash from label', () {
      expect(PaymentMethod.fromString('كاش'), equals(PaymentMethod.cash));
    });

    test('TC-C10: fromString bank from name', () {
      expect(PaymentMethod.fromString('bank'), equals(PaymentMethod.bank));
    });

    test('TC-C11: fromString bank from label', () {
      expect(PaymentMethod.fromString('بنكي'), equals(PaymentMethod.bank));
    });
  });

  group('ProductStatus Extension', () {
    test('TC-E01: displayName for available is "متاح"', () {
      expect(ProductStatus.available.displayName, equals('متاح'));
    });

    test('TC-E02: displayName for sold is "مباع"', () {
      expect(ProductStatus.sold.displayName, equals('مباع'));
    });

    // ✅ التصحيح: مقارنة القيم الرقمية
    test('TC-E03: color for available is green', () {
      expect(ProductStatus.available.color.value, equals(Colors.green.value));
    });

    // ✅ التصحيح: مقارنة القيم الرقمية
    test('TC-E04: color for sold is grey', () {
      expect(ProductStatus.sold.color.value, equals(Colors.grey.value));
    });
  });
}