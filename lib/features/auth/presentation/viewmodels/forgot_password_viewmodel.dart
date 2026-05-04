// lib/features/auth/presentation/viewmodels/forgot_password_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/utils/validators.dart';
import 'package:locaydo_app/features/auth/domain/repositories/auth_repository.dart';

enum ForgotPasswordResult { success, failure, validationError }

class ForgotPasswordViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  final emailController = TextEditingController();

  String? emailError;
  String? errorMessage;
  bool    isLoading = false;

  ForgotPasswordViewModel({required AuthRepository repository})
      : _repository = repository;

  // ── Validation ────────────────────────────────────────────────────────────

  bool validateEmail() {
    emailError = AppValidators.validateEmail(emailController.text.trim());
    notifyListeners();
    return emailError == null;
  }

  void clearEmailError() {
    if (emailError != null) { emailError = null; notifyListeners(); }
  }

  // ── Send Reset Link ───────────────────────────────────────────────────────

  Future<ForgotPasswordResult> sendResetLink() async {
    if (!validateEmail()) return ForgotPasswordResult.validationError;

    _setLoading(true);
    
    try {
      final email = emailController.text.trim();
      
      // ✅ إرسال مباشر - بدون تحقق مسبق (لأسباب أمنية)
      await _repository.sendPasswordResetEmail(email);
      
      return ForgotPasswordResult.success;
      
    } catch (e) {
      errorMessage = _extractMessage(e);
      return ForgotPasswordResult.failure;
    } finally {
      _setLoading(false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool v) { isLoading = v; notifyListeners(); }

  String _extractMessage(Object e) {
    String message = e.toString().replaceFirst('Exception: ', '');
    return message;
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}