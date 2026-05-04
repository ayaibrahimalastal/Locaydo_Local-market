// lib/core/utils/validators.dart
import 'package:locaydo_app/core/constants/app_strings.dart';

class AppValidators {
  // ── Auth ──────────────────────────────────────────────
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) return AppStrings.usernameRequired;
    if (value.length < 3) return AppStrings.usernameMinLength;
    if (value.length > 20) return AppStrings.usernameMaxLength;
    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$').hasMatch(value))
      return AppStrings.usernameInvalid;
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return AppStrings.emailRequired;
    
    // ✅ صيغة أكثر صرامة للبريد الإلكتروني
    // - يجب أن يحتوي على @
    // - بعد @ يجب أن يكون هناك دومين صحيح
    // - النطاق (TLD) يجب أن يكون 2-4 أحرف فقط (مثل com, net, org, etc.)
    // - منع النطاقات غير الصحيحة مثل .cm, .c, .coo (غير مسموح)
    
    // تحقق من وجود @
    if (!value.contains('@')) {
      return 'البريد الإلكتروني يجب أن يحتوي على @';
    }
    
    // تقسيم البريد إلى اسم المستخدم والنطاق
    final parts = value.split('@');
    if (parts.length != 2) {
      return 'البريد الإلكتروني غير صالح';
    }
    
    final username = parts[0];
    final domain = parts[1];
    
    // التحقق من اسم المستخدم (يجب ألا يكون فارغاً)
    if (username.isEmpty) {
      return 'البريد الإلكتروني غير صالح: لا يمكن أن يكون اسم المستخدم فارغاً';
    }
    
    // التحقق من اسم المستخدم (يسمح بحروف وأرقام ونقاط وشرطات وعلامة +)
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+$').hasMatch(username)) {
      return 'البريد الإلكتروني غير صالح: اسم المستخدم يحتوي على أحرف غير مسموحة';
    }
    
    // التحقق من النطاق (يجب ألا يكون فارغاً)
    if (domain.isEmpty) {
      return 'البريد الإلكتروني غير صالح: لا يمكن أن يكون النطاق فارغاً';
    }
    
    // التحقق من وجود نقطة في النطاق
    if (!domain.contains('.')) {
      return 'البريد الإلكتروني غير صالح: النطاق يجب أن يحتوي على نقطة (مثل: gmail.com)';
    }
    
    // تقسيم النطاق إلى اسم النطاق والنطاق العلوي (TLD)
    final domainParts = domain.split('.');
    if (domainParts.length < 2) {
      return 'البريد الإلكتروني غير صالح: صيغة النطاق غير صحيحة';
    }
    
    // التحقق من النطاق العلوي (TLD) - يجب أن يكون 2-4 أحرف
    final tld = domainParts.last;
    if (tld.length < 2 || tld.length > 4) {
      return 'البريد الإلكتروني غير صالح: نطاق البريد يجب أن يكون 2-4 أحرف (مثل: .com, .net, .org)';
    }
    
    // ✅ منع النطاقات العلوية غير الصحيحة (قائمة سوداء)
    final invalidTlds = ['cm', 'c', 'co', 'o', 'om'];
    if (invalidTlds.contains(tld.toLowerCase())) {
      return 'البريد الإلكتروني غير صالح: نطاق البريد غير معروف (مثال صحيح: .com, .net, .org, .ps)';
    }
    
    // التحقق من اسم النطاق (يجب أن يكون 1-50 حرفاً)
    final domainName = domainParts[domainParts.length - 2];
    if (domainName.length < 1 || domainName.length > 50) {
      return 'البريد الإلكتروني غير صالح: اسم النطاق طويل جداً';
    }
    
    // ✅ منع البريد الطويل جداً (حد أقصى 100 حرف)
    if (value.length > 100) {
      return 'البريد الإلكتروني طويل جداً (حد أقصى 100 حرف)';
    }
    
    return null;
  }

  /// ✅ شروط كلمة المرور المتوافقة مع Firebase (6 أحرف على الأقل)
  /// مع إضافة شروط أمان إضافية
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.passwordRequired;
    
    // 1. الحد الأدنى 6 أحرف (متطلبات Firebase)
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    
    // 2. الحد الأقصى 50 حرف (للتطبيق)
    if (value.length > 50) {
      return 'كلمة المرور طويلة جداً (حد أقصى 50 حرف)';
    }
    
    // 3. تحتوي على حرف كبير واحد على الأقل (أمان إضافي)
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل';
    }
    
    // 4. تحتوي على حرف صغير واحد على الأقل (أمان إضافي)
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل';
    }
    
    // 5. تحتوي على رقم واحد على الأقل (أمان إضافي)
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل';
    }
    
    // 6. لا تحتوي على مسافات
    if (value.contains(' ')) {
      return 'كلمة المرور لا يمكن أن تحتوي على مسافات';
    }
    
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return AppStrings.confirmPasswordRequired;
    if (value != password) return AppStrings.passwordsNotMatch;
    return null;
  }

  // ── Product ───────────────────────────────────────────
  static String? validateProductName(String? value) {
    if (value == null || value.isEmpty) return AppStrings.productNameRequired;
    if (value.trim().length < 3) return AppStrings.productNameShort;
    if (value.length > 50) return AppStrings.productNameLong;
    return null;
  }

  static String? validateProductDescription(String? value) {
    if (value == null || value.isEmpty) return AppStrings.descriptionRequired;
    if (value.trim().length < 10) return AppStrings.descriptionShort;
    if (value.length > 500) return AppStrings.descriptionLong;
    return null;
  }

  static String? validateProductPrice(String? value) {
    if (value == null || value.isEmpty) return AppStrings.priceRequired;
    String clean = value.replaceAll(' ', '').replaceAll('٫', '.');
    if (clean.startsWith('-')) return AppStrings.priceNegative;
    if (!RegExp(r'^\d*\.?\d+$').hasMatch(clean)) return AppStrings.priceInvalid;
    final price = double.tryParse(clean);
    if (price == null) return AppStrings.priceInvalid;
    if (price <= 0) return AppStrings.priceNegative;
    if (price > 1000000) return AppStrings.priceTooHigh;
    if (clean.contains('.') && clean.split('.').last.length > 2)
      return AppStrings.priceDecimalLimit;
    return null;
  }

  static String? validatePaymentMethods(List<String>? methods) {
    if (methods == null || methods.isEmpty) return AppStrings.paymentMethodRequired;
    return null;
  }

  static String? validateProductImage(bool hasImage) =>
      hasImage ? null : AppStrings.imageRequired;

  static String? validateCategory(String? value) =>
      (value == null || value.isEmpty) ? AppStrings.categoryRequired : null;

  static String? validateLocation(String? value) =>
      (value == null || value.isEmpty) ? AppStrings.locationRequired : null;

  static String? validateCondition(String? value) =>
      (value == null || value.isEmpty) ? AppStrings.conditionRequired : null;

  // ── Seller ────────────────────────────────────────────
  static String? validateSellerName(String? value) {
    if (value == null || value.isEmpty) return AppStrings.sellerNameRequired;
    if (value.trim().length < 3) return AppStrings.sellerNameShort;
    if (value.length > 50) return 'الاسم طويل جداً (حد أقصى 50 حرف)';
    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$').hasMatch(value))
      return 'الاسم يجب أن يحتوي على حروف فقط';
    return null;
  }

  static String? validateSellerPhone(String? value) {
    if (value == null || value.isEmpty) return AppStrings.sellerPhoneRequired;
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
    if (clean.length != 9) return 'رقم الهاتف يجب أن يكون 9 أرقام بالضبط';
    if (clean.startsWith('00')) return 'رقم الهاتف لا يمكن أن يبدأ بصفرين';
    return null;
  }

  static String? validateSellerImage(bool hasImage) =>
      hasImage ? null : AppStrings.sellerImageRequired;

  // ── Helpers ───────────────────────────────────────────
  static double? parsePrice(String value) {
    final clean = value.replaceAll(' ', '').replaceAll('٫', '.');
    return double.tryParse(clean);
  }

  static String formatPriceForDisplay(String value) {
    final price = parsePrice(value);
    return price == null ? value : price.toStringAsFixed(2);
  }
}