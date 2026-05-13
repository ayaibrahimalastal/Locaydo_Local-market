// test/features/profile/profile_viewmodel_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:locaydo_app/core/enums/profile_enums.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/profile/data/models/user_data_model.dart';
import 'package:locaydo_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:locaydo_app/features/profile/presentation/viewmodels/profile_viewmodel.dart';

@GenerateMocks([ProfileRepository, Logger])
import 'profile_viewmodel_test.mocks.dart' as profile_mocks;

void main() {
  group('ProfileViewModel — Unit Tests', () {
    late profile_mocks.MockProfileRepository mockRepository;
    late profile_mocks.MockLogger mockLogger;
    late ProfileViewModel viewModel;

    final mockUserData = UserDataModel(
      userName: 'أحمد محمد',
      userRating: 4.8,
      totalRatings: 256,
      profileImage: 'https://example.com/avatar.jpg',
      availableProductsCount: 20,
      savedProductsCount: 15,
      email: 'ahmed@example.com',
      phoneNumber: '0599123456',
    );

    setUp(() {
      mockRepository = profile_mocks.MockProfileRepository();
      mockLogger = profile_mocks.MockLogger();
      viewModel = ProfileViewModel(
        repository: mockRepository,
        logger: mockLogger,
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    // ── Initial State Tests ─────────────────────────────────────────────────

    group('Initial State', () {
      test('TC-PV01: initial isLoading is false', () {
        expect(viewModel.isLoading, isFalse);
      });

      test('TC-PV02: initial errorMessage is null', () {
        expect(viewModel.errorMessage, isNull);
      });

      test('TC-PV03: initial userName has default value', () {
        expect(viewModel.userName, equals('علي الاغا'));
      });

      test('TC-PV04: initial userRating is 4.5', () {
        expect(viewModel.userRating, equals(4.5));
      });

      test('TC-PV05: initial totalRatings is 128', () {
        expect(viewModel.totalRatings, equals(128));
      });

      test('TC-PV06: initial profileImage is null', () {
        expect(viewModel.profileImage, isNull);
      });

      test('TC-PV07: initial availableProductsCount is 12', () {
        expect(viewModel.availableProductsCount, equals(12));
      });

      test('TC-PV08: initial savedProductsCount is 8', () {
        expect(viewModel.savedProductsCount, equals(8));
      });
    });

    // ── Menu Items Tests ───────────────────────────────────────────────────

    group('Menu Items', () {
      test('TC-PV09: menuItems returns all profile menu items', () {
        final menuItems = viewModel.menuItems;
        expect(menuItems, isNotEmpty);
        expect(menuItems.length, equals(ProfileMenuItem.values.length));
      });
    });

    // ── Load User Data Tests ───────────────────────────────────────────────

    group('Load User Data', () {
      test('TC-PV10: loadUserData sets isLoading to true during loading', () async {
        when(mockRepository.getUserData()).thenAnswer((_) async => mockUserData);

        final future = viewModel.loadUserData();

        expect(viewModel.isLoading, isTrue);
        await future;
      });

      test('TC-PV11: loadUserData updates user data on success', () async {
        when(mockRepository.getUserData()).thenAnswer((_) async => mockUserData);

        await viewModel.loadUserData();

        expect(viewModel.userName, equals('أحمد محمد'));
        expect(viewModel.userRating, equals(4.8));
        expect(viewModel.totalRatings, equals(256));
        expect(viewModel.profileImage, equals('https://example.com/avatar.jpg'));
        expect(viewModel.availableProductsCount, equals(20));
        expect(viewModel.savedProductsCount, equals(15));
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.errorMessage, isNull);
      });

      test('TC-PV12: loadUserData sets error on failure', () async {
        when(mockRepository.getUserData()).thenThrow(Exception('Network error'));

        await viewModel.loadUserData();

        expect(viewModel.errorMessage, equals('فشل تحميل البيانات'));
        expect(viewModel.isLoading, isFalse);
      });

      test('TC-PV13: loadUserData preserves default values on failure', () async {
        when(mockRepository.getUserData()).thenThrow(Exception('Network error'));

        await viewModel.loadUserData();

        expect(viewModel.userName, equals('علي الاغا'));
        expect(viewModel.userRating, equals(4.5));
        expect(viewModel.totalRatings, equals(128));
        expect(viewModel.availableProductsCount, equals(12));
        expect(viewModel.savedProductsCount, equals(8));
      });
    });

    // ── Logout Tests ───────────────────────────────────────────────────────

    group('Logout', () {
      test('TC-PV14: logout calls repository logout method', () async {
        when(mockRepository.logout()).thenAnswer((_) async => Future.value());

        await viewModel.logout();

        verify(mockRepository.logout()).called(1);
      });

      test('TC-PV15: logout handles error gracefully', () async {
        when(mockRepository.logout()).thenThrow(Exception('Logout failed'));

        expect(() => viewModel.logout(), returnsNormally);
      });
    });

    // ── Delete Account Tests ───────────────────────────────────────────────

    group('Delete Account', () {
      test('TC-PV16: deleteAccount calls repository deleteAccount method', () async {
        when(mockRepository.deleteAccount()).thenAnswer((_) async => Future.value());

        await viewModel.deleteAccount();

        verify(mockRepository.deleteAccount()).called(1);
      });

      test('TC-PV17: deleteAccount handles error gracefully', () async {
        when(mockRepository.deleteAccount()).thenThrow(Exception('Delete failed'));

        expect(() => viewModel.deleteAccount(), returnsNormally);
      });
    });

    // ── Error Management Tests ─────────────────────────────────────────────

    group('Error Management', () {
      test('TC-PV18: errorMessage is cleared on successful load', () async {
        when(mockRepository.getUserData()).thenThrow(Exception('Error'));
        await viewModel.loadUserData();
        expect(viewModel.errorMessage, isNotNull);

        when(mockRepository.getUserData()).thenAnswer((_) async => mockUserData);
        await viewModel.loadUserData();

        expect(viewModel.errorMessage, isNull);
      });
    });

    // ── Multiple Load Tests ────────────────────────────────────────────────

    group('Multiple Load Operations', () {
      test('TC-PV19: consecutive loadUserData calls work correctly', () async {
        when(mockRepository.getUserData()).thenAnswer((_) async => mockUserData);

        await viewModel.loadUserData();
        expect(viewModel.userName, equals('أحمد محمد'));

        await viewModel.loadUserData();
        expect(viewModel.userName, equals('أحمد محمد'));
      });
    });
  });
}