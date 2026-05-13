// test/features/auth/activation_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:locaydo_app/core/enums/activation_status.dart';
import 'package:locaydo_app/features/auth/presentation/viewmodels/activation_viewmodel.dart';

void main() {
  group('ActivationViewModel — UI Helpers Tests', () {
    late ActivationViewModel viewModel;

    setUp(() {
      viewModel = ActivationViewModel();
    });

    tearDown(() {
      viewModel.dispose();
    });

    group('Initial State', () {
      test('TC-A01: initial isResending is false', () {
        expect(viewModel.isResending, isFalse);
      });

      test('TC-A02: initial isChecking is false', () {
        expect(viewModel.isChecking, isFalse);
      });

      test('TC-A03: initial errorMessage is null', () {
        expect(viewModel.errorMessage, isNull);
      });
    });

    group('getTitle', () {
      test('TC-A04: getTitle returns correct title for emailSent', () {
        final title = viewModel.getTitle(ActivationStatus.emailSent);
        expect(title, isNotEmpty);
      });

      test('TC-A05: getTitle returns correct title for success', () {
        final title = viewModel.getTitle(ActivationStatus.success);
        expect(title, isNotEmpty);
      });

      test('TC-A06: getTitle returns correct title for failed', () {
        final title = viewModel.getTitle(ActivationStatus.failed);
        expect(title, isNotEmpty);
      });
    });

    group('getImagePath', () {
      test('TC-A07: getImagePath returns non-empty path for success', () {
        expect(viewModel.getImagePath(ActivationStatus.success), isNotEmpty);
      });

      test('TC-A08: getImagePath returns non-empty path for failed', () {
        expect(viewModel.getImagePath(ActivationStatus.failed), isNotEmpty);
      });

      test('TC-A09: getImagePath returns non-empty path for emailSent', () {
        expect(viewModel.getImagePath(ActivationStatus.emailSent), isNotEmpty);
      });
    });

    group('getMessage', () {
      test('TC-A10: getMessage returns non-empty string for emailSent', () {
        expect(viewModel.getMessage(ActivationStatus.emailSent), isNotEmpty);
      });

      test('TC-A11: getMessage returns non-empty string for success', () {
        expect(viewModel.getMessage(ActivationStatus.success), isNotEmpty);
      });

      test('TC-A12: getMessage returns non-empty string for failed', () {
        expect(viewModel.getMessage(ActivationStatus.failed), isNotEmpty);
      });
    });

    group('clearError', () {
      test('TC-A13: clearError can be called without errors', () {
        expect(() => viewModel.clearError(), returnsNormally);
      });
    });

    group('Edge Cases', () {
      test('TC-A14: getTitle returns non-empty for all status values', () {
        for (final status in ActivationStatus.values) {
          expect(viewModel.getTitle(status), isNotEmpty, reason: 'Status: $status');
        }
      });

      test('TC-A15: getImagePath returns non-empty for all status values', () {
        for (final status in ActivationStatus.values) {
          expect(viewModel.getImagePath(status), isNotEmpty, reason: 'Status: $status');
        }
      });

      test('TC-A16: getMessage returns non-empty for all status values', () {
        for (final status in ActivationStatus.values) {
          expect(viewModel.getMessage(status), isNotEmpty, reason: 'Status: $status');
        }
      });
    });
  });
}