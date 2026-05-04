// lib/features/auth/presentation/screens/activation_screens.dart
// ✅ بدون تغيير — فقط imports محدّثة

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/enums/activation_status.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'account_activation_view.dart';

// ── Configs ───────────────────────────────────────────────────────────────────

abstract class ActivationScreenConfig {
  final ActivationStatus status;
  final String?          email;
  final VoidCallback     onContinue;
  final VoidCallback     onResendLink;
  final VoidCallback?    onBack;

  const ActivationScreenConfig({
    required this.status,
    this.email,
    required this.onContinue,
    required this.onResendLink,
    this.onBack,
  });
}

class SuccessConfig extends ActivationScreenConfig {
  SuccessConfig({
    required super.onContinue,
    required super.onResendLink,
    super.onBack,
  }) : super(status: ActivationStatus.success);
}

class FailedConfig extends ActivationScreenConfig {
  FailedConfig({
    super.email,
    required super.onContinue,
    required super.onResendLink,
    super.onBack,
  }) : super(status: ActivationStatus.failed);
}

class EmailSentConfig extends ActivationScreenConfig {
  EmailSentConfig({
    required super.email,
    required super.onContinue,
    required super.onResendLink,
    super.onBack,
  }) : super(status: ActivationStatus.emailSent);
}

// ── Screen Builder ────────────────────────────────────────────────────────────

class ActivationScreen extends StatelessWidget {
  final ActivationScreenConfig config;
  const ActivationScreen({super.key, required this.config});

  factory ActivationScreen.success({
    Key? key,
    VoidCallback? onContinue,
    VoidCallback? onBack,
  }) =>
      ActivationScreen(
        key: key,
        config: SuccessConfig(
          onContinue:   onContinue ?? () {},
          onResendLink: () {},
          onBack:       onBack,
        ),
      );

  factory ActivationScreen.failed({
    Key? key,
    String? email,
    required VoidCallback onResendLink,
    VoidCallback? onContinue,
    VoidCallback? onBack,
  }) =>
      ActivationScreen(
        key: key,
        config: FailedConfig(
          email:        email,
          onContinue:   onContinue ?? () {},
          onResendLink: onResendLink,
          onBack:       onBack,
        ),
      );

  factory ActivationScreen.emailSent({
    Key? key,
    required String email,
    required VoidCallback onResendLink,
    VoidCallback? onContinue,
    VoidCallback? onBack,
  }) =>
      ActivationScreen(
        key: key,
        config: EmailSentConfig(
          email:        email,
          onContinue:   onContinue ?? () {},
          onResendLink: onResendLink,
          onBack:       onBack,
        ),
      );

  @override
  Widget build(BuildContext context) => AccountActivationView(
        status:       config.status,
        email:        config.email,
        onResendLink: config.onResendLink,
        onContinue:   config.onContinue,
        onBack:       config.onBack,
      );
}

// ── Simple API ────────────────────────────────────────────────────────────────

class ActivationScreens {
  static Widget success({VoidCallback? onContinue, VoidCallback? onBack}) =>
      ActivationScreen.success(onContinue: onContinue, onBack: onBack);

  static Widget failed({
    String? email,
    required VoidCallback onResendLink,
    VoidCallback? onContinue,
    VoidCallback? onBack,
  }) =>
      ActivationScreen.failed(
        email:        email,
        onResendLink: onResendLink,
        onContinue:   onContinue,
        onBack:       onBack,
      );

  static Widget emailSent({
    required String email,
    required VoidCallback onResendLink,
    VoidCallback? onContinue,
    VoidCallback? onBack,
  }) =>
      ActivationScreen.emailSent(
        email:        email,
        onResendLink: onResendLink,
        onContinue:   onContinue,
        onBack:       onBack,
      );
}

// ── Default Configs ───────────────────────────────────────────────────────────

class DefaultActivationConfigs {
  static VoidCallback onContinueToMain(BuildContext context) =>
      () => Navigator.pushReplacementNamed(
            context, AppRoutes.mainNavigation, arguments: 0,
          );

  static VoidCallback onBackToPrevious(BuildContext context) =>
      () => Navigator.pop(context);

  static VoidCallback onResendLink(String email) =>
      () => debugPrint('Resend link to $email');
}