// lib/features/auth/presentation/viewmodels/activation_viewmodel.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/enums/activation_status.dart';

class ActivationViewModel extends ChangeNotifier {
  bool    _isResending = false;
  bool    _isChecking  = false;
  String? _errorMessage;
  
  // Optional navigator key for global navigation
  static GlobalKey<NavigatorState>? navigatorKey;

  bool    get isResending   => _isResending;
  bool    get isChecking    => _isChecking;
  String? get errorMessage  => _errorMessage;

  // ── Email Verification ────────────────────────────────────────────────────
  Future<bool> checkEmailVerification() async {
    _isChecking = true;
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// يراقب حالة التفعيل كل 3 ثواني
  void startMonitoring({
    required VoidCallback onVerified,
    required VoidCallback onFailed,
    int maxAttempts = 20,
  }) {
    int attempts = 0;

    Future<void> check() async {
      if (attempts >= maxAttempts) {
        _errorMessage = 'انتهى وقت التفعيل، يرجى طلب رابط جديد';
        onFailed();
        return;
      }
      attempts++;
      final verified = await checkEmailVerification();
      if (verified) {
        onVerified();
      } else {
        Future.delayed(const Duration(seconds: 3), check);
      }
    }

    check();
  }

  // ── Resend Link ───────────────────────────────────────────────────────────
  Future<bool> resendLink({
    required String email,
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) async {
    if (_isResending) return false;
    
    _isResending = true;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('لا يوجد مستخدم');
      }
      await user.sendEmailVerification();
      _errorMessage = null;
      onSuccess();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      onError();
      return false;
    } finally {
      _isResending = false;
      notifyListeners();
    }
  }

  // ── UI Helpers ────────────────────────────────────────────────────────────
  String getTitle(ActivationStatus status) {
    switch (status) {
      case ActivationStatus.emailSent: 
        return AppStrings.activationTitle;
      case ActivationStatus.success:   
        return AppStrings.activationSuccess;
      case ActivationStatus.failed:    
        return AppStrings.activationFailed;
    }
  }

  String getMessage(ActivationStatus status) {
    switch (status) {
      case ActivationStatus.emailSent:
        return '${AppStrings.activationEmailSent}\n${AppStrings.activationCheckEmail}';
      case ActivationStatus.success:
        return '${AppStrings.activationSuccess}\n${AppStrings.activationWelcome}';
      case ActivationStatus.failed:
        return _errorMessage ??
            '${AppStrings.activationInvalidLink}\n${AppStrings.activationRequestNew}';
    }
  }

  String getImagePath(ActivationStatus status) {
    switch (status) {
      case ActivationStatus.success:   
        return AppAssets.successSvg;
      case ActivationStatus.failed:    
        return AppAssets.failedSvg;
      case ActivationStatus.emailSent: 
        return AppAssets.emailSentSvg;
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}