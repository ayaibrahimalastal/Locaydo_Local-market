// lib/core/enums/product_enums.dart

import 'package:locaydo_app/core/constants/app_assets.dart';

enum ProductCategory {
  all('الكل', 'all', AppAssets.all),
  electronics('أجهزة', 'electronics', AppAssets.devices),
  clothes('ملابس', 'clothes', AppAssets.clothes),
  furniture('أثاث', 'furniture', AppAssets.furniture),
  realEstate('عقارات', 'realEstate', AppAssets.realEstate),
  food('أغذية', 'food', AppAssets.food),
  handicrafts('حرف يدوية', 'handicrafts', AppAssets.handicrafts),
  donation('تبرعات', 'donation', AppAssets.donations),
  cooking('أدوات طبخ', 'cooking', AppAssets.cookingUtensils),
  cosmetics('مستحضرات تجميل', 'cosmetics', AppAssets.makeup),
  bag('شنط', 'bag', AppAssets.bag),
  perfumes('عطور', 'perfumes', AppAssets.perfumes),
  shoes('أحذية', 'shoes', AppAssets.shoes);

  final String label;
  final String name;
  final String svgPath;
  
  const ProductCategory(this.label, this.name, this.svgPath);

  static List<ProductCategory> get allCategories => values;

  static ProductCategory fromString(String value) {
    for (final category in values) {
      if (category.name == value || category.label == value) {
        return category;
      }
    }
    return ProductCategory.all;
  }
}

enum ProductCondition {
  new_('جديد', 'new'),
  used('مستعمل', 'used');

  final String label;
  final String name;
  
  const ProductCondition(this.label, this.name);
  
  static ProductCondition fromString(String value) {
    for (final condition in values) {
      if (condition.name == value || condition.label == value) {
        return condition;
      }
    }
    return ProductCondition.new_;
  }
}

enum Location {
  northGaza('شمال غزة', 'northGaza'),
  gazaCity('غزة المدينة', 'gazaCity'),
  khanYounis('خان يونس', 'khanYounis'),
  middleArea('الوسطى', 'middleArea'),
  rafah('رفح', 'rafah'),
  derBalah('دير البلح', 'derBalah');

  final String label;
  final String name;
  
  const Location(this.label, this.name);
  
  static Location fromString(String value) {
    for (final location in values) {
      if (location.name == value || location.label == value) {
        return location;
      }
    }
    return Location.northGaza;
  }
}

enum PaymentMethod {
  cash('كاش', 'cash'),
  bank('بنكي', 'bank');

  final String label;
  final String name;
  
  const PaymentMethod(this.label, this.name);
  
  static PaymentMethod fromString(String value) {
    for (final method in values) {
      if (method.name == value || method.label == value) {
        return method;
      }
    }
    return PaymentMethod.cash;
  }
}

enum CountryCode {
  palestine('فلسطين', '+970', '🇵🇸'),
  palestine48('فلسطين 48', '+972', '🇵🇸');

  final String countryName;
  final String code;
  final String flag;
  const CountryCode(this.countryName, this.code, this.flag);
}

extension CountryCodeExtension on CountryCode {
  static CountryCode fromCode(String code) => CountryCode.values.firstWhere(
        (e) => e.code == code,
        orElse: () => CountryCode.palestine,
      );

  static CountryCode fromCountryName(String name) =>
      CountryCode.values.firstWhere(
        (e) => e.countryName == name,
        orElse: () => CountryCode.palestine,
      );

  String get displayString => '$flag $code';
}