// test/features/auth/login_viewmodel_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:locaydo_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:locaydo_app/features/auth/domain/entities/user_entity.dart';
import 'package:locaydo_app/features/auth/presentation/viewmodels/login_viewmodel.dart';

@GenerateMocks([AuthRepository])
import 'login_viewmodel_test.mocks.dart';

void main() {
  group('LoginViewModel — Unit Tests', () {
    late MockAuthRepository mockRepository;
    late LoginViewModel viewModel;

    // ✅ إنشاء UserEntity وهمي صحيح للاختبار
    final mockUser = UserEntity(
      uid: 'user123',
      email: 'test@gmail.com',
      username: 'Test User',
      isEmailVerified: true,
      isSeller: false,
      hasCompletedSellerProfile: false,
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockRepository = MockAuthRepository();
      viewModel = LoginViewModel(repository: mockRepository);
    });

    tearDown(() {
      viewModel.dispose();
    });

    group('Email Validation', () {
      test('TC-V01: empty email shows error', () {
        viewModel.emailController.text = '';
        viewModel.passwordController.text = 'Test123!';
        
        final isValid = viewModel.validateForm();
        
        expect(viewModel.emailError, isNotNull);
        expect(isValid, isFalse);
      });

      test('TC-V02: invalid email format shows error', () {
        viewModel.emailController.text = 'not-an-email';
        viewModel.passwordController.text = 'Test123!';
        
        viewModel.validateForm();
        
        // ✅ التحقق من وجود @ في رسالة الخطأ
        expect(viewModel.emailError, contains('@'));
      });

      test('TC-V03: valid email clears email error', () {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        
        viewModel.validateForm();
        
        expect(viewModel.emailError, isNull);
      });

      test('TC-V04: clearFieldError removes email error', () {
        viewModel.emailController.text = '';
        viewModel.validateForm();
        expect(viewModel.emailError, isNotNull);
        
        viewModel.clearFieldError('email');
        expect(viewModel.emailError, isNull);
      });
    });

    group('Password Validation', () {
      test('TC-V05: empty password shows error', () {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = '';
        
        viewModel.validateForm();
        
        expect(viewModel.passwordError, isNotNull);
      });

      test('TC-V06: password shorter than 6 chars shows error', () {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = '123';
        
        viewModel.validateForm();
        
        expect(viewModel.passwordError, isNotNull);
        expect(viewModel.passwordError, contains('6'));
      });

      test('TC-V07: valid password clears password error', () {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        
        viewModel.validateForm();
        
        expect(viewModel.passwordError, isNull);
      });

      test('TC-V08: clearFieldError removes password error', () {
        viewModel.passwordController.text = '';
        viewModel.validateForm();
        expect(viewModel.passwordError, isNotNull);
        
        viewModel.clearFieldError('password');
        expect(viewModel.passwordError, isNull);
      });
    });

    group('Combined Validation', () {
      test('TC-V09: all empty fields fail validation', () {
        viewModel.emailController.text = '';
        viewModel.passwordController.text = '';
        
        final result = viewModel.validateForm();
        
        expect(result, isFalse);
        expect(viewModel.emailError, isNotNull);
        expect(viewModel.passwordError, isNotNull);
      });

      test('TC-V10: all valid fields pass validation', () {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        
        final result = viewModel.validateForm();
        
        expect(result, isTrue);
        expect(viewModel.emailError, isNull);
        expect(viewModel.passwordError, isNull);
      });
    });

    group('Initial State', () {
      test('TC-V11: initial isLoading is false', () {
        expect(viewModel.isLoading, isFalse);
      });

      test('TC-V12: initial errorMessage is null', () {
        expect(viewModel.errorMessage, isNull);
      });
    });

    group('Login Logic', () {
      test('TC-V15: returns validationError when form is invalid', () async {
        viewModel.emailController.text = '';
        viewModel.passwordController.text = '';
        
        final result = await viewModel.login();
        
        expect(result, LoginResult.validationError);
        expect(viewModel.isLoading, isFalse);
        verifyNever(mockRepository.login(email: anyNamed('email'), password: anyNamed('password')));
      });

      test('TC-V16: successful login returns success', () async {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        
        when(mockRepository.login(email: anyNamed('email'), password: anyNamed('password')))
            .thenAnswer((_) async => mockUser);
        
        when(mockRepository.isEmailVerified()).thenAnswer((_) async => true);
        
        final result = await viewModel.login();
        
        expect(result, LoginResult.success);
        expect(viewModel.errorMessage, isNull);
      });

      test('TC-V17: returns emailNotVerified when email not verified', () async {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        
        final unverifiedUser = UserEntity(
          uid: 'user123',
          email: 'test@gmail.com',
          username: 'Test User',
          isEmailVerified: false,
          isSeller: false,
          hasCompletedSellerProfile: false,
          createdAt: DateTime.now(),
        );
        
        when(mockRepository.login(email: anyNamed('email'), password: anyNamed('password')))
            .thenAnswer((_) async => unverifiedUser);
        
        when(mockRepository.isEmailVerified()).thenAnswer((_) async => false);
        
        final result = await viewModel.login();
        
        expect(result, LoginResult.emailNotVerified);
      });

      test('TC-V18: returns failure and sets errorMessage on exception', () async {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        
        when(mockRepository.login(email: anyNamed('email'), password: anyNamed('password')))
            .thenThrow(Exception('Invalid credentials'));
        
        final result = await viewModel.login();
        
        expect(result, LoginResult.failure);
        expect(viewModel.errorMessage, isNotNull);
      });

      test('TC-V19: sets isLoading to true during login', () async {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        
        when(mockRepository.login(email: anyNamed('email'), password: anyNamed('password')))
            .thenAnswer((_) async => mockUser);
        when(mockRepository.isEmailVerified()).thenAnswer((_) async => true);
        
        final future = viewModel.login();
        
        expect(viewModel.isLoading, isTrue);
        await future;
      });

      test('TC-V20: sets isLoading to false after login completes', () async {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        
        when(mockRepository.login(email: anyNamed('email'), password: anyNamed('password')))
            .thenAnswer((_) async => mockUser);
        when(mockRepository.isEmailVerified()).thenAnswer((_) async => true);
        
        await viewModel.login();
        
        expect(viewModel.isLoading, isFalse);
      });

      test('TC-V21: login calls repository with correct credentials', () async {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        
        when(mockRepository.login(email: anyNamed('email'), password: anyNamed('password')))
            .thenAnswer((_) async => mockUser);
        when(mockRepository.isEmailVerified()).thenAnswer((_) async => true);
        
        await viewModel.login();
        
        verify(mockRepository.login(
          email: 'test@gmail.com',
          password: 'Test123!',
        )).called(1);
      });

      test('TC-V22: calls isEmailVerified only after successful login', () async {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        
        when(mockRepository.login(email: anyNamed('email'), password: anyNamed('password')))
            .thenAnswer((_) async => mockUser);
        when(mockRepository.isEmailVerified()).thenAnswer((_) async => true);
        
        await viewModel.login();
        
        verify(mockRepository.isEmailVerified()).called(1);
      });

      test('TC-V23: does not call isEmailVerified when login throws error', () async {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        
        when(mockRepository.login(email: anyNamed('email'), password: anyNamed('password')))
            .thenThrow(Exception('Network error'));
        
        await viewModel.login();
        
        verifyNever(mockRepository.isEmailVerified());
      });
    });

    group('Edge Cases', () {
      test('TC-V24: email with spaces is trimmed', () {
        viewModel.emailController.text = '  test@gmail.com  ';
        viewModel.passwordController.text = 'Test123!';
        
        viewModel.validateForm();
        
        expect(viewModel.emailError, isNull);
      });

      test('TC-V25: clearFieldError with wrong field does nothing', () {
        viewModel.emailController.text = '';
        viewModel.validateForm();
        expect(viewModel.emailError, isNotNull);
        
        viewModel.clearFieldError('wrong_field');
        expect(viewModel.emailError, isNotNull);
      });
    });
  });
}