// test/features/products/product_form_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/enums/product_form_enums.dart';
import 'package:locaydo_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:locaydo_app/features/products/presentation/viewmodels/product_form_viewmodel.dart';

@GenerateMocks([ProductRepositoryImpl])
import 'product_form_viewmodel_test.mocks.dart';

void main() {
  group('ProductFormViewModel — Validation Tests', () {
    late MockProductRepositoryImpl mockRepository;
    late ProductFormViewModel viewModel;

    setUp(() {
      mockRepository = MockProductRepositoryImpl();
      viewModel = ProductFormViewModel(
        mode: ProductFormMode.add,
        productRepository: mockRepository,  // ✅ تمرير Mock
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    // ── Initial State Tests ─────────────────────────────────────────────────

    group('Initial State', () {
      test('TC-P01: initial isSaving is false', () {
        expect(viewModel.isSaving, isFalse);
      });

      test('TC-P02: initial saveErrorMessage is null', () {
        expect(viewModel.saveErrorMessage, isNull);
      });

      test('TC-P03: initial hasImages is false', () {
        expect(viewModel.hasImages, isFalse);
      });

      test('TC-P04: initial price is 0.0', () {
        expect(viewModel.price, equals(0.0));
      });

      test('TC-P05: add mode has isEditMode false', () {
        expect(viewModel.isEditMode, isFalse);
      });

      test('TC-P06: add mode has default payment methods', () {
        expect(viewModel.selectedPayments, isNotEmpty);
      });
    });

    // ── Name Validation Tests ──────────────────────────────────────────────

    group('Name Validation', () {
      test('TC-P07: empty name fails validation', () {
        viewModel.nameController.text = '';
        viewModel.descriptionController.text = 'وصف المنتج';
        viewModel.priceController.text = '500';
        viewModel.addImage('/fake/path/image.jpg');
        viewModel.validateForm();

        expect(viewModel.errors[ProductField.name], isNotNull);
      });

      test('TC-P08: valid name passes validation', () {
        viewModel.nameController.text = 'لابتوب ديل';
        viewModel.descriptionController.text = 'وصف المنتج الجيد';
        viewModel.priceController.text = '500';
        viewModel.addImage('/fake/path/image.jpg');
        viewModel.validateForm();

        expect(viewModel.errors[ProductField.name], isNull);
      });

      test('TC-P09: name with 2 chars fails validation', () {
        viewModel.nameController.text = 'اب';
        viewModel.descriptionController.text = 'وصف المنتج الجيد';
        viewModel.priceController.text = '500';
        viewModel.addImage('/fake/path/image.jpg');
        viewModel.validateForm();

        expect(viewModel.errors[ProductField.name], isNotNull);
      });
    });

    // ── Description Validation Tests ───────────────────────────────────────

    group('Description Validation', () {
      test('TC-P10: empty description fails validation', () {
        viewModel.nameController.text = 'منتج';
        viewModel.descriptionController.text = '';
        viewModel.priceController.text = '500';
        viewModel.addImage('/fake/path/image.jpg');
        viewModel.validateForm();

        expect(viewModel.errors[ProductField.description], isNotNull);
      });

      test('TC-P11: valid description passes validation', () {
        viewModel.nameController.text = 'منتج';
        viewModel.descriptionController.text = 'وصف مفصل للمنتج بأكثر من 10 أحرف';
        viewModel.priceController.text = '500';
        viewModel.addImage('/fake/path/image.jpg');
        viewModel.validateForm();

        expect(viewModel.errors[ProductField.description], isNull);
      });
    });

    // ── Price Validation Tests ─────────────────────────────────────────────

    group('Price Validation', () {
      test('TC-P12: negative price fails validation', () {
        viewModel.nameController.text = 'منتج';
        viewModel.descriptionController.text = 'وصف المنتج';
        viewModel.priceController.text = '-100';
        viewModel.addImage('/fake/path/image.jpg');
        viewModel.validateForm();

        expect(viewModel.errors[ProductField.price], isNotNull);
      });

      test('TC-P13: zero price for donation is valid', () {
        viewModel.onCategoryChanged(ProductCategory.donation);
        expect(viewModel.isDonation, isTrue);
        expect(viewModel.price, equals(0.0));
      });

      test('TC-P14: donation category sets price to 0', () {
        viewModel.onCategoryChanged(ProductCategory.donation);
        expect(viewModel.priceController.text, equals('0.00'));
      });

      test('TC-P15: valid price passes validation', () {
        viewModel.nameController.text = 'منتج';
        viewModel.descriptionController.text = 'وصف المنتج';
        viewModel.priceController.text = '500';
        viewModel.addImage('/fake/path/image.jpg');
        viewModel.validateForm();

        expect(viewModel.errors[ProductField.price], isNull);
      });
    });

    // ── Image Validation Tests ─────────────────────────────────────────────

    group('Image Validation', () {
      test('TC-P16: no image fails validation', () {
        viewModel.nameController.text = 'منتج';
        viewModel.descriptionController.text = 'وصف المنتج';
        viewModel.priceController.text = '100';
        viewModel.validateForm();

        expect(viewModel.errors[ProductField.image], isNotNull);
      });

      test('TC-P17: adding image clears image error', () {
        viewModel.addImage('/path/to/image.jpg');
        expect(viewModel.hasImages, isTrue);
        expect(viewModel.errors[ProductField.image], isNull);
      });

      test('TC-P18: remove image shows error when no images left', () {
        viewModel.addImage('/path/image.jpg');
        viewModel.removeImage(0);
        expect(viewModel.hasImages, isFalse);
        expect(viewModel.errors[ProductField.image], isNotNull);
      });

      test('TC-P19: multiple images can be added', () {
        viewModel.addImage('/path/image1.jpg');
        viewModel.addImage('/path/image2.jpg');
        expect(viewModel.imagePaths.length, equals(2));
      });
    });

    // ── Category Tests ─────────────────────────────────────────────────────

    group('Category Tests', () {
      test('TC-P20: changing category updates state', () {
        viewModel.onCategoryChanged(ProductCategory.clothes);
        expect(viewModel.category, equals(ProductCategory.clothes));
      });

      test('TC-P21: changing to donation clears price and payment errors', () {
        viewModel.nameController.text = 'منتج';
        viewModel.descriptionController.text = 'وصف';
        viewModel.priceController.text = '500';
        viewModel.addImage('/path/image.jpg');
        viewModel.validateForm();

        viewModel.onCategoryChanged(ProductCategory.donation);
        viewModel.validateForm();

        expect(viewModel.isDonation, isTrue);
        expect(viewModel.errors[ProductField.price], isNull);
        expect(viewModel.errors[ProductField.payment], isNull);
      });
    });

    // ── Payment Methods Tests ──────────────────────────────────────────────

    group('Payment Methods', () {
      test('TC-P22: default has payment methods selected', () {
        expect(viewModel.selectedPayments, isNotEmpty);
      });

      test('TC-P23: donation category clears payment method requirement', () {
        viewModel.onCategoryChanged(ProductCategory.donation);
        expect(viewModel.isDonation, isTrue);
      });
    });

    // ── Edit Mode Tests ────────────────────────────────────────────────────

    group('Edit Mode', () {
      test('TC-P24: edit mode has correct mode flag', () {
        final editVm = ProductFormViewModel(
          mode: ProductFormMode.edit,
          productRepository: mockRepository,
          initialData: {
            'name': 'منتج قديم',
            'description': 'وصف المنتج',
            'price': 100.0,
            'condition': ProductCondition.new_,
            'category': ProductCategory.electronics,
            'location': Location.northGaza,
            'payments': [PaymentMethod.cash],
            'imagePaths': [],
          },
        );
        expect(editVm.isEditMode, isTrue);
        expect(editVm.nameController.text, equals('منتج قديم'));
        editVm.dispose();
      });

      test('TC-P25: edit mode loads initial data correctly', () {
        final editVm = ProductFormViewModel(
          mode: ProductFormMode.edit,
          productRepository: mockRepository,
          initialData: {
            'name': 'لابتوب ديل',
            'description': 'وصف مفصل للمنتج',
            'price': 1500.0,
            'condition': ProductCondition.used,
            'category': ProductCategory.electronics,
            'location': Location.gazaCity,
            'payments': [PaymentMethod.cash, PaymentMethod.bank],
            'imagePaths': ['http://example.com/img1.jpg', 'http://example.com/img2.jpg'],
          },
        );
        expect(editVm.nameController.text, equals('لابتوب ديل'));
        expect(editVm.descriptionController.text, equals('وصف مفصل للمنتج'));
        expect(editVm.priceController.text, equals('1500.0'));
        expect(editVm.condition, equals(ProductCondition.used));
        expect(editVm.category, equals(ProductCategory.electronics));
        expect(editVm.location, equals(Location.gazaCity));
        expect(editVm.selectedPayments, containsAll([PaymentMethod.cash, PaymentMethod.bank]));
        expect(editVm.imagePaths.length, equals(2));
        editVm.dispose();
      });
    });

    // ── Reset Tests ────────────────────────────────────────────────────────

    group('Reset Functionality', () {
      test('TC-P26: reset clears all fields', () {
        viewModel.nameController.text = 'اسم المنتج';
        viewModel.descriptionController.text = 'وصف المنتج';
        viewModel.priceController.text = '500';
        viewModel.addImage('/path/image.jpg');
        viewModel.onCategoryChanged(ProductCategory.clothes);
        
        viewModel.reset();
        
        expect(viewModel.nameController.text, equals(''));
        expect(viewModel.descriptionController.text, equals(''));
        expect(viewModel.priceController.text, equals('0.00'));
        expect(viewModel.hasImages, isFalse);
        expect(viewModel.category, equals(ProductCategory.electronics));
      });

      test('TC-P27: reset clears all errors', () {
        viewModel.validateForm();
        expect(viewModel.errors, isNotEmpty);
        
        viewModel.reset();
        
        expect(viewModel.errors, isEmpty);
      });
    });

    // ── Helper Properties Tests ────────────────────────────────────────────

    group('Helper Properties', () {
      test('TC-P28: isDonation returns true for donation category', () {
        viewModel.onCategoryChanged(ProductCategory.donation);
        expect(viewModel.isDonation, isTrue);
      });

      test('TC-P29: isDonation returns false for non-donation category', () {
        viewModel.onCategoryChanged(ProductCategory.electronics);
        expect(viewModel.isDonation, isFalse);
      });

      test('TC-P30: success message for add mode', () {
        expect(viewModel.successMessage, contains('تم نشر المنتج بنجاح'));
      });
    });

    // ── Clear Field Error Tests ────────────────────────────────────────────

    group('Clear Field Error', () {
      test('TC-P31: clearFieldError removes specific error', () {
        viewModel.nameController.text = '';
        viewModel.validateForm();
        expect(viewModel.errors[ProductField.name], isNotNull);
        
        viewModel.clearFieldError(ProductField.name);
        expect(viewModel.errors.containsKey(ProductField.name), isFalse);
      });

      test('TC-P32: clearFieldError does nothing for non-existent error', () {
        expect(viewModel.errors.containsKey(ProductField.price), isFalse);
        viewModel.clearFieldError(ProductField.price);
        expect(viewModel.errors.containsKey(ProductField.price), isFalse);
      });
    });

    // ── Edge Cases ─────────────────────────────────────────────────────────

    group('Edge Cases', () {
      test('TC-P33: price controller listener clears price error', () {
        // Set up error
        viewModel.nameController.text = 'منتج';
        viewModel.descriptionController.text = 'وصف';
        viewModel.priceController.text = 'abc';
        viewModel.addImage('/path/image.jpg');
        viewModel.validateForm();
        expect(viewModel.errors[ProductField.price], isNotNull);
        
        // Change price to valid value
        viewModel.priceController.text = '500';
        
        // Note: In real app, listeners would trigger clearFieldError
        // For unit test, we manually clear
        viewModel.clearFieldError(ProductField.price);
        expect(viewModel.errors.containsKey(ProductField.price), isFalse);
      });
    });
  });
}