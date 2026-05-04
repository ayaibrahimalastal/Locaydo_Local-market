// lib/core/utils/product_helper.dart

import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';

import 'validators.dart';

class ProductHelper {
  static bool isDonation(ProductCategory category) =>
      category == ProductCategory.donation;

  static ({
    ProductCategory category,
    String priceText,
    List<PaymentMethod> payments,
  }) handleCategoryChange({
    required ProductCategory newCategory,
    required String currentPrice,
    required List<PaymentMethod> currentPayments,
    List<PaymentMethod>? defaultPayments,
  }) {
    final defaults = defaultPayments ?? [PaymentMethod.bank, PaymentMethod.cash];

    if (newCategory == ProductCategory.donation) {
      return (category: newCategory, priceText: '0.00', payments: []);
    }
    return (
      category: newCategory,
      priceText: currentPrice,
      payments: currentPayments.isEmpty ? defaults : currentPayments,
    );
  }

  static String? getDonationMessage(ProductCategory category) =>
      category == ProductCategory.donation ? 'لا يوجد، المنتج مجاني' : null;

  static String? validatePriceByCategory(String? price, ProductCategory category) {
    if (category == ProductCategory.donation) return null;
    return AppValidators.validateProductPrice(price);
  }

  static String? validatePaymentMethodsByCategory(
      List<PaymentMethod>? payments, ProductCategory category) {
    if (category == ProductCategory.donation) return null;
    if (payments == null || payments.isEmpty) return AppStrings.paymentMethodRequired;
    return null;
  }

  static List<PaymentMethod> getDefaultPayments() =>
      [PaymentMethod.bank, PaymentMethod.cash];
}