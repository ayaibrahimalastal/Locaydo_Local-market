// lib/core/error/exceptions.dart

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'حدث خطأ في الخادم']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'خطأ في الاتصال بالإنترنت']);
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'خطأ في المصادقة']);
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException([this.message = 'البيانات غير موجودة']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'خطأ في التخزين المحلي']);
}