import 'package:flutter/foundation.dart';

/// واجهة مجردة للتسجيل (Logging)
abstract class Logger {
  void log(String message);
  void error(String message, [dynamic error]);
  void warning(String message);
}

/// تطبيق الـ Logger لوضع التطوير (Debug)
class DebugLogger implements Logger {
  @override
  void log(String message) {
    if (kDebugMode) {
      print('📝 [LOG]: $message');
    }
  }

  @override
  void error(String message, [dynamic error]) {
    if (kDebugMode) {
      print('❌ [ERROR]: $message');
      if (error != null) {
        print('   Details: $error');
      }
    }
  }

  @override
  void warning(String message) {
    if (kDebugMode) {
      print('⚠️ [WARNING]: $message');
    }
  }
}

/// تطبيق الـ Logger لوضع الإنتاج (Production)
class ProductionLogger implements Logger {
  @override
  void log(String message) {
    // هنا يمكنك إرسال logs إلى خدمة تحليلات مثل Firebase Analytics
    // مثال: AnalyticsService().logEvent(name: message);
    if (kDebugMode) {
      print('📝 [PROD LOG]: $message');
    }
  }

  @override
  void error(String message, [dynamic error]) {
    // هنا يمكنك إرسال الأخطاء إلى خدمة تتبع الأخطاء مثل Sentry
    // مثال: Sentry.captureException(error, hint: message);
    if (kDebugMode) {
      print('❌ [PROD ERROR]: $message');
      if (error != null) {
        print('   Details: $error');
      }
    }
  }

  @override
  void warning(String message) {
    // هنا يمكنك تسجيل التحذيرات
    if (kDebugMode) {
      print('⚠️ [PROD WARNING]: $message');
    }
  }
}

/// تطبيق الـ Logger للاختبارات (Testing)
class TestLogger implements Logger {
  final List<String> logs = [];
  final List<String> errors = [];
  final List<String> warnings = [];

  @override
  void log(String message) {
    logs.add(message);
  }

  @override
  void error(String message, [dynamic error]) {
    errors.add('$message${error != null ? ': $error' : ''}');
  }

  @override
  void warning(String message) {
    warnings.add(message);
  }

  void clear() {
    logs.clear();
    errors.clear();
    warnings.clear();
  }

  bool get hasLogs => logs.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  
  @override
  String toString() {
    return 'TestLogger(logs: ${logs.length}, errors: ${errors.length}, warnings: ${warnings.length})';
  }
}