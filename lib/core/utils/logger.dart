// lib/core/utils/logger.dart

import 'package:flutter/foundation.dart';

abstract class Logger {
  void log(String message);
  void error(String message, [dynamic error]);
}

class DebugLogger implements Logger {
  @override
  void log(String message) => debugPrint('📝 $message');

  @override
  void error(String message, [dynamic error]) =>
      debugPrint('❌ $message${error != null ? ': $error' : ''}');
}

class TestLogger implements Logger {
  final List<String> logs   = [];
  final List<String> errors = [];

  @override
  void log(String message) => logs.add(message);

  @override
  void error(String message, [dynamic error]) =>
      errors.add('$message${error != null ? ': $error' : ''}');

  void clear() { logs.clear(); errors.clear(); }
}