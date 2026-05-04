// lib/features/auth/domain/repositories/auth_repository.dart

import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});

  Future<UserEntity> signup({
    required String username,
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> resendActivationLink(String email);

  Future<bool> isEmailVerified();

  Future<void> deleteAccount();

  UserEntity? getCurrentUser();

  Stream<UserEntity?> authStateChanges();
}