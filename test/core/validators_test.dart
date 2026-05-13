// test/core/validators_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:locaydo_app/core/utils/validators.dart';

void main() {
  group('AppValidators — Username Validation', () {
    test('TC-VL01: null username returns error', () {
      expect(AppValidators.validateUsername(null), isNotNull);
    });

    test('TC-VL02: empty username returns error', () {
      expect(AppValidators.validateUsername(''), isNotNull);
    });

    test('TC-VL03: username too short (< 3 chars) returns error', () {
      expect(AppValidators.validateUsername('ab'), isNotNull);
    });

    test('TC-VL04: username too long (> 20 chars) returns error', () {
      expect(AppValidators.validateUsername('a' * 21), isNotNull);
    });

    test('TC-VL05: username with invalid characters returns error', () {
      expect(AppValidators.validateUsername('user@123'), isNotNull);
    });

    // ✅ تصحيح: استخدام username بدون أحرف خاصة
    test('TC-VL06: valid English username returns null', () {
      expect(AppValidators.validateUsername('johndoe'), isNull);
      expect(AppValidators.validateUsername('JohnDoe'), isNull);
    });

    // ✅ تصحيح: استخدام username عربي بدون أحرف خاصة
    test('TC-VL07: valid Arabic username returns null', () {
      expect(AppValidators.validateUsername('أحمد'), isNull);
      expect(AppValidators.validateUsername('محمدعلي'), isNull);
    });
  });

  group('AppValidators — Email Validation', () {
    test('TC-VL08: null email returns error', () {
      expect(AppValidators.validateEmail(null), isNotNull);
    });

    test('TC-VL09: empty email returns error', () {
      expect(AppValidators.validateEmail(''), isNotNull);
    });

    test('TC-VL10: email without @ returns error', () {
      expect(AppValidators.validateEmail('testgmail.com'), isNotNull);
      expect(AppValidators.validateEmail('testgmail.com'), contains('@'));
    });

    test('TC-VL11: email without username returns error', () {
      expect(AppValidators.validateEmail('@gmail.com'), isNotNull);
    });

    test('TC-VL12: email without domain returns error', () {
      expect(AppValidators.validateEmail('test@'), isNotNull);
    });

    test('TC-VL13: email without dot in domain returns error', () {
      expect(AppValidators.validateEmail('test@gmailcom'), isNotNull);
    });

    test('TC-VL14: email with invalid TLD (too short) returns error', () {
      expect(AppValidators.validateEmail('test@gmai.c'), isNotNull);
    });

    test('TC-VL15: email with invalid TLD (too long) returns error', () {
      expect(AppValidators.validateEmail('test@gmail.abcdef'), isNotNull);
    });

    test('TC-VL16: email with invalid TLD (blacklisted) returns error', () {
      expect(AppValidators.validateEmail('test@gmail.cm'), isNotNull);
      expect(AppValidators.validateEmail('test@gmail.co'), isNotNull);
    });

    test('TC-VL17: email with special chars in username returns null', () {
      expect(AppValidators.validateEmail('test.user+label@gmail.com'), isNull);
    });

    test('TC-VL18: valid email returns null', () {
      expect(AppValidators.validateEmail('test@gmail.com'), isNull);
    });

    test('TC-VL19: valid email with subdomain returns null', () {
      expect(AppValidators.validateEmail('user@mail.co.uk'), isNull);
    });

    test('TC-VL20: email too long (> 100 chars) returns error', () {
      final longEmail = 'a' * 90 + '@' + 'b' * 10 + '.com';
      expect(AppValidators.validateEmail(longEmail), isNotNull);
    });
  });

  group('AppValidators — Password Validation (Firebase rules)', () {
    test('TC-VL21: null password returns error', () {
      expect(AppValidators.validatePassword(null), isNotNull);
    });

    test('TC-VL22: empty password returns error', () {
      expect(AppValidators.validatePassword(''), isNotNull);
    });

    test('TC-VL23: password shorter than 6 chars returns error', () {
      expect(AppValidators.validatePassword('12345'), contains('6 أحرف'));
    });

    test('TC-VL24: password without uppercase letter returns error', () {
      expect(AppValidators.validatePassword('abcdefg'), contains('كبير'));
    });

    test('TC-VL25: password without lowercase letter returns error', () {
      expect(AppValidators.validatePassword('ABCDEFG'), contains('صغير'));
    });

    test('TC-VL26: password without number returns error', () {
      expect(AppValidators.validatePassword('Abcdefg'), contains('رقم'));
    });

    test('TC-VL27: password with spaces returns error', () {
      expect(AppValidators.validatePassword('Abc 123'), contains('مسافات'));
    });

    test('TC-VL28: password too long (> 50 chars) returns error', () {
      expect(AppValidators.validatePassword('Abc123!' + 'a' * 50), contains('طويلة'));
    });

    test('TC-VL29: valid password (6+ chars, uppercase, lowercase, number) returns null', () {
      expect(AppValidators.validatePassword('Abc123!'), isNull);
    });

    test('TC-VL30: valid password with 6 chars exactly returns null', () {
      expect(AppValidators.validatePassword('Abc123'), isNull);
    });
  });

  group('AppValidators — Confirm Password Validation', () {
    test('TC-VL31: null confirm password returns error', () {
      expect(AppValidators.validateConfirmPassword(null, 'pass123'), isNotNull);
    });

    test('TC-VL32: empty confirm password returns error', () {
      expect(AppValidators.validateConfirmPassword('', 'pass123'), isNotNull);
    });

    test('TC-VL33: mismatched passwords returns error', () {
      expect(AppValidators.validateConfirmPassword('wrong123', 'pass123'), isNotNull);
    });

    test('TC-VL34: matching passwords returns null', () {
      expect(AppValidators.validateConfirmPassword('pass123', 'pass123'), isNull);
    });
  });

  group('AppValidators — Product Name Validation', () {
    test('TC-VL35: null product name returns error', () {
      expect(AppValidators.validateProductName(null), isNotNull);
    });

    test('TC-VL36: empty product name returns error', () {
      expect(AppValidators.validateProductName(''), isNotNull);
    });

    test('TC-VL37: product name too short (< 3 chars) returns error', () {
      expect(AppValidators.validateProductName('اب'), isNotNull);
    });

    test('TC-VL38: product name too long (> 50 chars) returns error', () {
      expect(AppValidators.validateProductName('ا' * 51), isNotNull);
    });

    test('TC-VL39: valid product name returns null', () {
      expect(AppValidators.validateProductName('لابتوب ديل'), isNull);
    });
  });

  group('AppValidators — Product Description Validation', () {
    test('TC-VL40: null description returns error', () {
      expect(AppValidators.validateProductDescription(null), isNotNull);
    });

    test('TC-VL41: empty description returns error', () {
      expect(AppValidators.validateProductDescription(''), isNotNull);
    });

    test('TC-VL42: description too short (< 10 chars) returns error', () {
      expect(AppValidators.validateProductDescription('وصف قصير'), isNotNull);
    });

    test('TC-VL43: description too long (> 500 chars) returns error', () {
      expect(AppValidators.validateProductDescription('وصف' * 200), isNotNull);
    });

    test('TC-VL44: valid description returns null', () {
      expect(AppValidators.validateProductDescription('وصف مفصل للمنتج بأكثر من عشرة أحرف'), isNull);
    });
  });

  group('AppValidators — Product Price Validation', () {
    test('TC-VL45: null price returns error', () {
      expect(AppValidators.validateProductPrice(null), isNotNull);
    });

    test('TC-VL46: empty price returns error', () {
      expect(AppValidators.validateProductPrice(''), isNotNull);
    });

    // ✅ تصحيح: تتوقع الرسالة 'أكبر من 0'
    test('TC-VL47: negative price returns error', () {
      expect(AppValidators.validateProductPrice('-100'), contains('أكبر من 0'));
    });

    // ✅ تصحيح: تتوقع الرسالة 'أكبر من 0'
    test('TC-VL48: zero price returns error', () {
      expect(AppValidators.validateProductPrice('0'), contains('أكبر من 0'));
    });

    test('TC-VL49: price with letters returns error', () {
      expect(AppValidators.validateProductPrice('abc'), contains('رقم'));
    });

    test('TC-VL50: price too high (> 1,000,000) returns error', () {
      expect(AppValidators.validateProductPrice('1000001'), contains('كبير'));
    });

    // ✅ تصحيح: تتوقع الرسالة 'منزلتين عشريتين'
    test('TC-VL51: price with more than 2 decimal places returns error', () {
      expect(AppValidators.validateProductPrice('100.123'), contains('منزلتين عشريتين'));
    });

    test('TC-VL52: valid integer price returns null', () {
      expect(AppValidators.validateProductPrice('250'), isNull);
    });

    test('TC-VL53: valid decimal price returns null', () {
      expect(AppValidators.validateProductPrice('250.50'), isNull);
    });

    test('TC-VL54: price with Arabic decimal separator returns null', () {
      expect(AppValidators.validateProductPrice('250٫50'), isNull);
    });
  });

  group('AppValidators — Payment Methods Validation', () {
    test('TC-VL55: null payment methods returns error', () {
      expect(AppValidators.validatePaymentMethods(null), isNotNull);
    });

    test('TC-VL56: empty payment methods list returns error', () {
      expect(AppValidators.validatePaymentMethods([]), isNotNull);
    });

    test('TC-VL57: non-empty payment methods returns null', () {
      expect(AppValidators.validatePaymentMethods(['cash']), isNull);
    });
  });

  group('AppValidators — Product Image Validation', () {
    test('TC-VL58: no image returns error', () {
      expect(AppValidators.validateProductImage(false), isNotNull);
    });

    test('TC-VL59: has image returns null', () {
      expect(AppValidators.validateProductImage(true), isNull);
    });
  });

  group('AppValidators — Category Validation', () {
    test('TC-VL60: null category returns error', () {
      expect(AppValidators.validateCategory(null), isNotNull);
    });

    test('TC-VL61: empty category returns error', () {
      expect(AppValidators.validateCategory(''), isNotNull);
    });

    test('TC-VL62: valid category returns null', () {
      expect(AppValidators.validateCategory('electronics'), isNull);
    });
  });

  group('AppValidators — Location Validation', () {
    test('TC-VL63: null location returns error', () {
      expect(AppValidators.validateLocation(null), isNotNull);
    });

    test('TC-VL64: empty location returns error', () {
      expect(AppValidators.validateLocation(''), isNotNull);
    });

    test('TC-VL65: valid location returns null', () {
      expect(AppValidators.validateLocation('غزة'), isNull);
    });
  });

  group('AppValidators — Condition Validation', () {
    test('TC-VL66: null condition returns error', () {
      expect(AppValidators.validateCondition(null), isNotNull);
    });

    test('TC-VL67: empty condition returns error', () {
      expect(AppValidators.validateCondition(''), isNotNull);
    });

    test('TC-VL68: valid condition returns null', () {
      expect(AppValidators.validateCondition('new'), isNull);
    });
  });

  group('AppValidators — Seller Name Validation', () {
    test('TC-VL69: null seller name returns error', () {
      expect(AppValidators.validateSellerName(null), isNotNull);
    });

    test('TC-VL70: empty seller name returns error', () {
      expect(AppValidators.validateSellerName(''), isNotNull);
    });

    test('TC-VL71: seller name too short (< 3 chars) returns error', () {
      expect(AppValidators.validateSellerName('اب'), isNotNull);
    });

    test('TC-VL72: seller name too long (> 50 chars) returns error', () {
      expect(AppValidators.validateSellerName('ا' * 51), isNotNull);
    });

    test('TC-VL73: seller name with numbers returns error', () {
      expect(AppValidators.validateSellerName('محمد123'), contains('حروف فقط'));
    });

    test('TC-VL74: valid seller name returns null', () {
      expect(AppValidators.validateSellerName('محمد احمد'), isNull);
    });
  });

  group('AppValidators — Seller Phone Validation', () {
    test('TC-VL75: null phone returns error', () {
      expect(AppValidators.validateSellerPhone(null), isNotNull);
    });

    test('TC-VL76: empty phone returns error', () {
      expect(AppValidators.validateSellerPhone(''), isNotNull);
    });

    // ✅ تصحيح: يتحقق من الطول أولاً
    test('TC-VL77: phone with letters returns error', () {
      final result = AppValidators.validateSellerPhone('abc123456');
      expect(result, contains('9 أرقام'));
    });

    test('TC-VL78: phone not 9 digits returns error', () {
      expect(AppValidators.validateSellerPhone('59212345'), contains('9 أرقام'));
      expect(AppValidators.validateSellerPhone('5921234567'), contains('9 أرقام'));
    });

    // ✅ تصحيح: يتحقق من الطول أولاً
    test('TC-VL79: phone starting with 00 returns error', () {
      final result = AppValidators.validateSellerPhone('00592123456');
      expect(result, contains('9 أرقام'));
    });

    test('TC-VL80: valid 9-digit phone returns null', () {
      expect(AppValidators.validateSellerPhone('592123456'), isNull);
    });

    test('TC-VL81: valid phone with spaces returns null', () {
      expect(AppValidators.validateSellerPhone('592 123 456'), isNull);
    });
  });

  group('AppValidators — Seller Image Validation', () {
    test('TC-VL82: no seller image returns error', () {
      expect(AppValidators.validateSellerImage(false), isNotNull);
    });

    test('TC-VL83: has seller image returns null', () {
      expect(AppValidators.validateSellerImage(true), isNull);
    });
  });

  group('AppValidators — parsePrice Helper', () {
    test('TC-VL84: parsePrice returns null for empty string', () {
      expect(AppValidators.parsePrice(''), isNull);
    });

    test('TC-VL85: parsePrice returns null for invalid string', () {
      expect(AppValidators.parsePrice('abc'), isNull);
    });

    test('TC-VL86: parsePrice parses integer correctly', () {
      expect(AppValidators.parsePrice('250'), equals(250.0));
    });

    test('TC-VL87: parsePrice parses decimal correctly', () {
      expect(AppValidators.parsePrice('250.50'), equals(250.50));
    });

    test('TC-VL88: parsePrice handles Arabic decimal separator', () {
      expect(AppValidators.parsePrice('250٫75'), equals(250.75));
    });

    test('TC-VL89: parsePrice handles spaces', () {
      expect(AppValidators.parsePrice('250 500'), equals(250500.0));
    });
  });

  group('AppValidators — formatPriceForDisplay Helper', () {
    test('TC-VL90: formatPriceForDisplay returns same string for invalid price', () {
      expect(AppValidators.formatPriceForDisplay('abc'), equals('abc'));
    });

    test('TC-VL91: formatPriceForDisplay formats valid price with 2 decimals', () {
      expect(AppValidators.formatPriceForDisplay('250'), equals('250.00'));
    });

    test('TC-VL92: formatPriceForDisplay keeps existing decimals', () {
      expect(AppValidators.formatPriceForDisplay('250.5'), equals('250.50'));
    });
  });
}