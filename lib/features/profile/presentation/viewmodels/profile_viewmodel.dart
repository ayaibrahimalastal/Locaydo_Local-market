// lib/features/profile/presentation/viewmodels/profile_viewmodel.dart
// NOTE: Dialog calls moved to ProfileScreen — ViewModel uses callbacks

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/enums/profile_enums.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;
  final Logger _logger;

  String  userName   = 'علي الاغا';
  double  userRating = 4.5;
  int     totalRatings = 128;
  String? profileImage;
  int     availableProductsCount = 12;
  int     savedProductsCount     = 8;

  bool    isLoading    = false;
  String? errorMessage;

  ProfileViewModel({
    required ProfileRepository repository,
    required Logger logger,
  })  : _repository = repository,
        _logger     = logger;

  List<ProfileMenuItem> get menuItems => ProfileMenuItem.values;

  Future<void> loadUserData() async {
    _setLoading(true);
    _clearError();
    try {
      final d = await _repository.getUserData();
      userName               = d.userName;
      userRating             = d.userRating;
      totalRatings           = d.totalRatings;
      profileImage           = d.profileImage;
      availableProductsCount = d.availableProductsCount;
      savedProductsCount     = d.savedProductsCount;
      _logger.log('User data loaded');
    } catch (e) {
      _setError('فشل تحميل البيانات');
      _logger.error('loadUserData failed', e);
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ MVVM FIX: dialogs now handled in screen via callbacks
  /// Call logout() directly from screen after user confirms
  Future<void> logout() async {
    try {
      await _repository.logout();
      // TODO: Navigate to login — emit event or use callback
    } catch (e) {
      _logger.error('Logout failed', e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _repository.deleteAccount();
      // TODO: Navigate to welcome — emit event or use callback
    } catch (e) {
      _logger.error('Delete account failed', e);
    }
  }

  void _setLoading(bool v) { isLoading = v; notifyListeners(); }
  void _setError(String m) { errorMessage = m; notifyListeners(); }
  void _clearError()       { errorMessage = null; notifyListeners(); }
}