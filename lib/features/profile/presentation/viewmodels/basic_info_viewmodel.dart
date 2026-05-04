// lib/features/profile/presentation/viewmodels/basic_info_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/profile/domain/repositories/profile_repository.dart';

class BasicInfoViewModel extends ChangeNotifier {
  final ProfileRepository _repository;
  final Logger _logger;

  String  userName     = 'مها حميد';
  String  email        = 'mahahmaide@gmail.com';
  String? phoneNumber;
  String? profileImage;

  bool    isLoading    = false;
  String? errorMessage;

  BasicInfoViewModel({
    required ProfileRepository repository,
    required Logger logger,
  })  : _repository = repository,
        _logger     = logger;

  Future<void> loadUserBasicInfo() async {
    _setLoading(true);
    _clearError();
    try {
      final d = await _repository.getUserData();
      userName     = d.userName;
      email        = d.email;
      phoneNumber  = d.phoneNumber;
      profileImage = d.profileImage;
      _logger.log('Basic info loaded');
    } catch (e) {
      _setError('فشل تحميل البيانات');
      _logger.error('loadUserBasicInfo failed', e);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) { isLoading = v; notifyListeners(); }
  void _setError(String m) { errorMessage = m; notifyListeners(); }
  void _clearError()       { errorMessage = null; notifyListeners(); }
}