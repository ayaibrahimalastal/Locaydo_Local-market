// lib/features/profile/domain/repositories/profile_repository.dart

import 'package:locaydo_app/features/profile/data/models/user_data_model.dart';

abstract class ProfileRepository {
  Future<UserDataModel> getUserData();
  Future<void> logout();
  Future<void> deleteAccount();
}