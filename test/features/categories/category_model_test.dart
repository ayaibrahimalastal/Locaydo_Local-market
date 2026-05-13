// test/features/categories/category_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/features/categories/data/models/category_model.dart';

void main() {
  group('CategoryModel — fromFirestore / toFirestore', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('TC-C01: fromFirestore parses all fields correctly', () async {
      await firestore.collection('categories').doc('electronics').set({
        'name': 'إلكترونيات',
        'nameEn': 'Electronics',
        'iconPath': 'assets/icons/electronics.svg',
        'order': 1,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final doc = await firestore.collection('categories').doc('electronics').get();
      final model = CategoryModel.fromFirestore(doc);

      expect(model.id, equals('electronics'));
      expect(model.name, equals('إلكترونيات'));
      expect(model.nameEn, equals('Electronics'));
      expect(model.iconPath, equals('assets/icons/electronics.svg'));
      expect(model.order, equals(1));
      expect(model.isActive, isTrue);
    });

    test('TC-C02: fromFirestore uses default values for missing fields', () async {
      await firestore.collection('categories').doc('test').set({
        'name': 'اختبار',
        // Missing nameEn, iconPath, order, isActive, createdAt
      });

      final doc = await firestore.collection('categories').doc('test').get();
      final model = CategoryModel.fromFirestore(doc);

      expect(model.id, equals('test'));
      expect(model.name, equals('اختبار'));
      expect(model.nameEn, equals(''));
      expect(model.iconPath, equals(''));
      expect(model.order, equals(0));
      expect(model.isActive, isTrue); // default is true
      expect(model.createdAt, isNotNull);
    });

    test('TC-C03: toFirestore returns correct map', () async {
      final model = CategoryModel(
        id: 'electronics',
        name: 'إلكترونيات',
        nameEn: 'Electronics',
        iconPath: 'assets/icons/electronics.svg',
        order: 1,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final map = model.toFirestore();

      expect(map['name'], equals('إلكترونيات'));
      expect(map['nameEn'], equals('Electronics'));
      expect(map['iconPath'], equals('assets/icons/electronics.svg'));
      expect(map['order'], equals(1));
      expect(map['isActive'], isTrue);
      expect(map['createdAt'], isA<FieldValue>());
      expect(map['updatedAt'], isA<FieldValue>());
    });

    test('TC-C04: toProductCategory converts electronics correctly', () async {
      await firestore.collection('categories').doc('electronics').set({
        'name': 'إلكترونيات',
        'nameEn': 'Electronics',
        'iconPath': '',
        'order': 0,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('electronics').get();
      final model = CategoryModel.fromFirestore(doc);
      final category = model.toProductCategory();

      expect(category, equals(ProductCategory.electronics));
    });

    test('TC-C05: toProductCategory converts clothes correctly', () async {
      await firestore.collection('categories').doc('clothes').set({
        'name': 'ملابس',
        'nameEn': 'Clothes',
        'iconPath': '',
        'order': 0,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('clothes').get();
      final model = CategoryModel.fromFirestore(doc);
      final category = model.toProductCategory();

      expect(category, equals(ProductCategory.clothes));
    });

    test('TC-C06: toProductCategory converts furniture correctly', () async {
      await firestore.collection('categories').doc('furniture').set({
        'name': 'أثاث',
        'nameEn': 'Furniture',
        'iconPath': '',
        'order': 0,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('furniture').get();
      final model = CategoryModel.fromFirestore(doc);
      final category = model.toProductCategory();

      expect(category, equals(ProductCategory.furniture));
    });

    test('TC-C07: toProductCategory converts realEstate correctly', () async {
      await firestore.collection('categories').doc('realEstate').set({
        'name': 'عقارات',
        'nameEn': 'Real Estate',
        'iconPath': '',
        'order': 0,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('realEstate').get();
      final model = CategoryModel.fromFirestore(doc);
      final category = model.toProductCategory();

      expect(category, equals(ProductCategory.realEstate));
    });

    test('TC-C08: toProductCategory converts food correctly', () async {
      await firestore.collection('categories').doc('food').set({
        'name': 'أغذية',
        'nameEn': 'Food',
        'iconPath': '',
        'order': 0,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('food').get();
      final model = CategoryModel.fromFirestore(doc);
      final category = model.toProductCategory();

      expect(category, equals(ProductCategory.food));
    });

    test('TC-C09: toProductCategory converts handicrafts correctly', () async {
      await firestore.collection('categories').doc('handicrafts').set({
        'name': 'حرف يدوية',
        'nameEn': 'Handicrafts',
        'iconPath': '',
        'order': 0,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('handicrafts').get();
      final model = CategoryModel.fromFirestore(doc);
      final category = model.toProductCategory();

      expect(category, equals(ProductCategory.handicrafts));
    });

    test('TC-C10: toProductCategory converts donation correctly', () async {
      await firestore.collection('categories').doc('donation').set({
        'name': 'تبرعات',
        'nameEn': 'Donation',
        'iconPath': '',
        'order': 0,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('donation').get();
      final model = CategoryModel.fromFirestore(doc);
      final category = model.toProductCategory();

      expect(category, equals(ProductCategory.donation));
    });

    test('TC-C11: toProductCategory converts cooking correctly', () async {
      await firestore.collection('categories').doc('cooking').set({
        'name': 'أدوات طبخ',
        'nameEn': 'Cooking Utensils',
        'iconPath': '',
        'order': 0,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('cooking').get();
      final model = CategoryModel.fromFirestore(doc);
      final category = model.toProductCategory();

      expect(category, equals(ProductCategory.cooking));
    });

    test('TC-C12: toProductCategory converts cosmetics correctly', () async {
      await firestore.collection('categories').doc('cosmetics').set({
        'name': 'مستحضرات تجميل',
        'nameEn': 'Cosmetics',
        'iconPath': '',
        'order': 0,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('cosmetics').get();
      final model = CategoryModel.fromFirestore(doc);
      final category = model.toProductCategory();

      expect(category, equals(ProductCategory.cosmetics));
    });

    test('TC-C13: toProductCategory converts bag correctly', () async {
      await firestore.collection('categories').doc('bag').set({
        'name': 'شنط',
        'nameEn': 'Bags',
        'iconPath': '',
        'order': 0,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('bag').get();
      final model = CategoryModel.fromFirestore(doc);
      final category = model.toProductCategory();

      expect(category, equals(ProductCategory.bag));
    });

    test('TC-C14: toProductCategory converts perfumes correctly', () async {
      await firestore.collection('categories').doc('perfumes').set({
        'name': 'عطور',
        'nameEn': 'Perfumes',
        'iconPath': '',
        'order': 0,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('perfumes').get();
      final model = CategoryModel.fromFirestore(doc);
      final category = model.toProductCategory();

      expect(category, equals(ProductCategory.perfumes));
    });

    test('TC-C15: toProductCategory converts shoes correctly', () async {
      await firestore.collection('categories').doc('shoes').set({
        'name': 'أحذية',
        'nameEn': 'Shoes',
        'iconPath': '',
        'order': 0,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('shoes').get();
      final model = CategoryModel.fromFirestore(doc);
      final category = model.toProductCategory();

      expect(category, equals(ProductCategory.shoes));
    });

    test('TC-C16: unknown id returns ProductCategory.all', () async {
      await firestore.collection('categories').doc('unknown_xyz').set({
        'name': 'غير معروف',
        'nameEn': 'Unknown',
        'iconPath': '',
        'order': 0,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('unknown_xyz').get();
      final model = CategoryModel.fromFirestore(doc);
      final category = model.toProductCategory();

      expect(category, equals(ProductCategory.all));
    });

    test('TC-C17: copyWith updates only specified fields', () async {
      await firestore.collection('categories').doc('clothes').set({
        'name': 'ملابس',
        'nameEn': 'Clothes',
        'iconPath': 'assets/icons/clothes.svg',
        'order': 2,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('clothes').get();
      final model = CategoryModel.fromFirestore(doc);
      final updated = model.copyWith(
        name: 'أزياء',
        order: 3,
      );

      expect(updated.id, equals('clothes'));
      expect(updated.name, equals('أزياء'));
      expect(updated.nameEn, equals('Clothes'));
      expect(updated.iconPath, equals('assets/icons/clothes.svg'));
      expect(updated.order, equals(3));
      expect(updated.isActive, isTrue);
    });

    test('TC-C18: copyWith with null values keeps original', () async {
      await firestore.collection('categories').doc('test').set({
        'name': 'اختبار',
        'nameEn': 'Test',
        'iconPath': 'icon.svg',
        'order': 5,
        'isActive': true,
      });

      final doc = await firestore.collection('categories').doc('test').get();
      final model = CategoryModel.fromFirestore(doc);
      final updated = model.copyWith();

      expect(updated.name, equals(model.name));
      expect(updated.nameEn, equals(model.nameEn));
      expect(updated.order, equals(model.order));
      expect(updated.isActive, equals(model.isActive));
    });

    test('TC-C19: all product categories are covered in toProductCategory', () {
      // List all category IDs that should be recognized
      final recognizedIds = [
        'electronics',
        'clothes',
        'furniture',
        'realEstate',
        'food',
        'handicrafts',
        'donation',
        'cooking',
        'cosmetics',
        'bag',
        'perfumes',
        'shoes',
      ];

      for (final id in recognizedIds) {
        expect(
          () => CategoryModel(
            id: id,
            name: 'Test',
            nameEn: 'Test',
            iconPath: '',
            order: 0,
            isActive: true,
            createdAt: DateTime.now(),
          ).toProductCategory(),
          returnsNormally,
          reason: 'Category $id should be recognized',
        );
      }
    });

    test('TC-C20: createdAt is parsed correctly from Timestamp', () async {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);

      await firestore.collection('categories').doc('test').set({
        'name': 'اختبار',
        'nameEn': 'Test',
        'iconPath': '',
        'order': 0,
        'isActive': true,
        'createdAt': timestamp,
      });

      final doc = await firestore.collection('categories').doc('test').get();
      final model = CategoryModel.fromFirestore(doc);

      expect(model.createdAt.year, equals(now.year));
      expect(model.createdAt.month, equals(now.month));
      expect(model.createdAt.day, equals(now.day));
    });
  });
}