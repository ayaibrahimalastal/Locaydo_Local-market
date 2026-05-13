// lib/features/auth/presentation/viewmodels/login_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/utils/validators.dart';
import 'package:locaydo_app/features/auth/domain/repositories/auth_repository.dart';

enum LoginResult { success, failure, validationError, emailNotVerified }

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  final emailController    = TextEditingController();
  final passwordController = TextEditingController();

  String? emailError;
  String? passwordError;
  String? errorMessage;
  bool    isLoading = false;

  LoginViewModel({required AuthRepository repository})
      : _repository = repository;

  // ── Validation ────────────────────────────────────────────────────────────

  bool validateForm() {
    emailError    = AppValidators.validateEmail(_email);
    passwordError = AppValidators.validatePassword(_password);
    notifyListeners();
    return emailError == null && passwordError == null;
  }

  void clearFieldError(String field) {
    if (field == 'email'    && emailError    != null) { emailError    = null; notifyListeners(); }
    if (field == 'password' && passwordError != null) { passwordError = null; notifyListeners(); }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<LoginResult> login() async {
    if (!validateForm()) return LoginResult.validationError;

    _setLoading(true);
    try {
      await _repository.login(email: _email, password: _password);

      final isVerified = await _repository.isEmailVerified();
      if (!isVerified) return LoginResult.emailNotVerified;

      return LoginResult.success;
    } catch (e) {
      errorMessage = _extractMessage(e);
      return LoginResult.failure;
    } finally {
      _setLoading(false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _email    => emailController.text.trim();
  String get _password => passwordController.text;

  void _setLoading(bool v) { isLoading = v; notifyListeners(); }

  String _extractMessage(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void validate() {}
}