// test/features/auth/signup_viewmodel_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:locaydo_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:locaydo_app/features/auth/domain/entities/user_entity.dart';
import 'package:locaydo_app/features/auth/presentation/viewmodels/signup_viewmodel.dart';

@GenerateMocks([AuthRepository])
import 'signup_viewmodel_test.mocks.dart';

void main() {
  group('SignupViewModel — Unit Tests', () {
    late MockAuthRepository mockRepository;
    late SignupViewModel viewModel;

    // ✅ إنشاء UserEntity وهمي للاختبار
    final mockUser = UserEntity(
      uid: 'user123',
      email: 'test@gmail.com',
      username: 'testuser',
      isEmailVerified: false,
      isSeller: false,
      hasCompletedSellerProfile: false,
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockRepository = MockAuthRepository();
      viewModel = SignupViewModel(repository: mockRepository);
    });

    tearDown(() {
      viewModel.dispose();
    });

    // ── Username Validation Tests ──────────────────────────────────────────────

    group('Username Validation', () {
      test('TC-S01: empty username shows error', () {
        viewModel.usernameController.text = '';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        final isValid = viewModel.validateForm();
        
        expect(viewModel.usernameError, isNotNull);
        expect(isValid, isFalse);
      });

      test('TC-S02: valid username clears error', () {
        viewModel.usernameController.text = 'validuser';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        viewModel.validateForm();
        
        expect(viewModel.usernameError, isNull);
      });

      test('TC-S03: clearFieldError removes username error', () {
        viewModel.usernameController.text = '';
        viewModel.validateForm();
        expect(viewModel.usernameError, isNotNull);
        
        viewModel.clearFieldError('username');
        expect(viewModel.usernameError, isNull);
      });
    });

    // ── Email Validation Tests ─────────────────────────────────────────────────

    group('Email Validation', () {
      test('TC-S04: empty email shows error', () {
        viewModel.emailController.text = '';
        viewModel.usernameController.text = 'testuser';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        final isValid = viewModel.validateForm();
        
        expect(viewModel.emailError, isNotNull);
        expect(isValid, isFalse);
      });

      test('TC-S05: invalid email format shows error', () {
        viewModel.emailController.text = 'not-an-email';
        viewModel.usernameController.text = 'testuser';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        viewModel.validateForm();
        
        expect(viewModel.emailError, isNotNull);
        expect(viewModel.emailError, contains('@'));
      });

      test('TC-S06: valid email clears error', () {
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.usernameController.text = 'testuser';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        viewModel.validateForm();
        
        expect(viewModel.emailError, isNull);
      });

      test('TC-S07: clearFieldError removes email error', () {
        viewModel.emailController.text = '';
        viewModel.validateForm();
        expect(viewModel.emailError, isNotNull);
        
        viewModel.clearFieldError('email');
        expect(viewModel.emailError, isNull);
      });
    });

    // ── Password Validation Tests ──────────────────────────────────────────────

    group('Password Validation', () {
      test('TC-S08: empty password shows error', () {
        viewModel.passwordController.text = '';
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.confirmController.text = 'Test123!';
        
        viewModel.validateForm();
        
        expect(viewModel.passwordError, isNotNull);
      });

      test('TC-S09: password shorter than 6 chars shows error', () {
        viewModel.passwordController.text = '123';
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.confirmController.text = '123';
        
        viewModel.validateForm();
        
        expect(viewModel.passwordError, isNotNull);
        expect(viewModel.passwordError, contains('6'));
      });

      test('TC-S10: valid password clears error', () {
        viewModel.passwordController.text = 'Test123!';
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.confirmController.text = 'Test123!';
        
        viewModel.validateForm();
        
        expect(viewModel.passwordError, isNull);
      });

      test('TC-S11: clearFieldError removes password error', () {
        viewModel.passwordController.text = '';
        viewModel.validateForm();
        expect(viewModel.passwordError, isNotNull);
        
        viewModel.clearFieldError('password');
        expect(viewModel.passwordError, isNull);
      });
    });

    // ── Confirm Password Validation Tests ──────────────────────────────────────

    group('Confirm Password Validation', () {
      test('TC-S12: empty confirm password shows error', () {
        viewModel.confirmController.text = '';
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        
        viewModel.validateForm();
        
        expect(viewModel.confirmError, isNotNull);
      });

      test('TC-S13: mismatched passwords shows error', () {
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Different123!';
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        
        viewModel.validateForm();
        
        expect(viewModel.confirmError, isNotNull);
        expect(viewModel.confirmError, contains('تطابق'));
      });

      test('TC-S14: matching passwords clears error', () {
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        
        viewModel.validateForm();
        
        expect(viewModel.confirmError, isNull);
      });

      test('TC-S15: clearFieldError removes confirm error', () {
        viewModel.confirmController.text = '';
        viewModel.validateForm();
        expect(viewModel.confirmError, isNotNull);
        
        viewModel.clearFieldError('confirm');
        expect(viewModel.confirmError, isNull);
      });
    });

    // ── Combined Validation Tests ──────────────────────────────────────────────

    group('Combined Validation', () {
      test('TC-S16: all empty fields fail validation', () {
        viewModel.usernameController.text = '';
        viewModel.emailController.text = '';
        viewModel.passwordController.text = '';
        viewModel.confirmController.text = '';
        
        final result = viewModel.validateForm();
        
        expect(result, isFalse);
        expect(viewModel.usernameError, isNotNull);
        expect(viewModel.emailError, isNotNull);
        expect(viewModel.passwordError, isNotNull);
        expect(viewModel.confirmError, isNotNull);
      });

      test('TC-S17: all valid fields pass validation', () {
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        final result = viewModel.validateForm();
        
        expect(result, isTrue);
        expect(viewModel.usernameError, isNull);
        expect(viewModel.emailError, isNull);
        expect(viewModel.passwordError, isNull);
        expect(viewModel.confirmError, isNull);
      });
    });

    // ── Initial State Tests ────────────────────────────────────────────────────

    group('Initial State', () {
      test('TC-S18: initial isLoading is false', () {
        expect(viewModel.isLoading, isFalse);
      });

      test('TC-S19: initial errorMessage is null', () {
        expect(viewModel.errorMessage, isNull);
      });
    });

    // ── Signup Logic Tests ─────────────────────────────────────────────────────

    group('Signup Logic', () {
      test('TC-S20: returns validationError when form is invalid', () async {
        viewModel.usernameController.text = '';
        viewModel.emailController.text = '';
        viewModel.passwordController.text = '';
        viewModel.confirmController.text = '';
        
        final result = await viewModel.signup();
        
        expect(result, SignupResult.validationError);
        expect(viewModel.isLoading, isFalse);
        verifyNever(mockRepository.signup(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
        ));
      });

      test('TC-S21: successful signup returns success', () async {
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        when(mockRepository.signup(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUser);
        
        final result = await viewModel.signup();
        
        expect(result, SignupResult.success);
        expect(viewModel.errorMessage, isNull);
      });

      test('TC-S22: sets isLoading to true during signup', () async {
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        when(mockRepository.signup(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUser);
        
        final future = viewModel.signup();
        
        expect(viewModel.isLoading, isTrue);
        await future;
      });

      test('TC-S23: sets isLoading to false after signup completes', () async {
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        when(mockRepository.signup(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUser);
        
        await viewModel.signup();
        
        expect(viewModel.isLoading, isFalse);
      });

      test('TC-S24: returns failure and sets errorMessage on exception', () async {
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        when(mockRepository.signup(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('Email already exists'));
        
        final result = await viewModel.signup();
        
        expect(result, SignupResult.failure);
        expect(viewModel.errorMessage, isNotNull);
      });

      test('TC-S25: sets emailError when exception contains "البريد"', () async {
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        when(mockRepository.signup(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('البريد الإلكتروني مستخدم بالفعل'));
        
        await viewModel.signup();
        
        expect(viewModel.emailError, isNotNull);
        expect(viewModel.emailError, contains('مستخدم'));
      });

      test('TC-S26: sets passwordError when exception contains "المرور"', () async {
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        when(mockRepository.signup(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('كلمة المرور ضعيفة جداً'));
        
        await viewModel.signup();
        
        expect(viewModel.passwordError, isNotNull);
      });

      test('TC-S27: signup calls repository with correct data', () async {
        viewModel.usernameController.text = 'testuser';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        when(mockRepository.signup(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUser);
        
        await viewModel.signup();
        
        verify(mockRepository.signup(
          username: 'testuser',
          email: 'test@gmail.com',
          password: 'Test123!',
        )).called(1);
      });

      test('TC-S28: email is trimmed before validation', () {
        viewModel.emailController.text = '  test@gmail.com  ';
        viewModel.usernameController.text = 'testuser';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        viewModel.validateForm();
        
        expect(viewModel.emailError, isNull);
      });

      test('TC-S29: username is trimmed before signup', () async {
        viewModel.usernameController.text = '  testuser  ';
        viewModel.emailController.text = 'test@gmail.com';
        viewModel.passwordController.text = 'Test123!';
        viewModel.confirmController.text = 'Test123!';
        
        when(mockRepository.signup(
          username: anyNamed('username'),
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUser);
        
        await viewModel.signup();
        
        verify(mockRepository.signup(
          username: 'testuser', // ✅ تم تقليمها
          email: 'test@gmail.com',
          password: 'Test123!',
        )).called(1);
      });
    });
  });
}