// lib/core/error/failures.dart

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ في الخادم']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'خطأ في الاتصال بالإنترنت']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'خطأ في المصادقة']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'البيانات غير موجودة']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'بيانات غير صالحة']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'خطأ في التخزين المحلي']);
}