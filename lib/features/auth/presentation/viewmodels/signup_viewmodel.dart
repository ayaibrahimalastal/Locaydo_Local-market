// lib/features/auth/presentation/viewmodels/signup_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/utils/validators.dart';
import 'package:locaydo_app/features/auth/domain/repositories/auth_repository.dart';

enum SignupResult { success, failure, validationError }

class SignupViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  final usernameController = TextEditingController();
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController  = TextEditingController();

  String? usernameError;
  String? emailError;
  String? passwordError;
  String? confirmError;
  String? errorMessage;
  bool    isLoading = false;

  SignupViewModel({required AuthRepository repository})
      : _repository = repository;

  // ── Validation ────────────────────────────────────────────────────────────

  bool validateForm() {
    usernameError = AppValidators.validateUsername(usernameController.text);
    emailError    = AppValidators.validateEmail(_email);
    passwordError = AppValidators.validatePassword(_password);
    confirmError  = AppValidators.validateConfirmPassword(
      confirmController.text, _password,
    );
    notifyListeners();
    return usernameError == null &&
        emailError    == null &&
        passwordError == null &&
        confirmError  == null;
  }

  void clearFieldError(String field) {
    switch (field) {
      case 'username': if (usernameError != null) { usernameError = null; notifyListeners(); }
      case 'email':    if (emailError    != null) { emailError    = null; notifyListeners(); }
      case 'password': if (passwordError != null) { passwordError = null; notifyListeners(); }
      case 'confirm':  if (confirmError  != null) { confirmError  = null; notifyListeners(); }
    }
  }

  // ── Signup ────────────────────────────────────────────────────────────────

  Future<SignupResult> signup() async {
    if (!validateForm()) return SignupResult.validationError;

    _setLoading(true);
    try {
      await _repository.signup(
        username: usernameController.text.trim(),
        email:    _email,
        password: _password,
      );
      return SignupResult.success;
    } catch (e) {
      errorMessage = _extractMessage(e);
      // إذا كان الخطأ متعلق بالبريد → أظهره في حقل البريد
      if (errorMessage!.contains('البريد')) {
        emailError = errorMessage;
        notifyListeners();
      }
      // إذا كان الخطأ متعلق بكلمة المرور → أظهره في حقلها
      else if (errorMessage!.contains('المرور')) {
        passwordError = errorMessage;
        notifyListeners();
      }
      return SignupResult.failure;
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
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }
}