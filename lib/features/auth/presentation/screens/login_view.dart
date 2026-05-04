// lib/features/auth/presentation/screens/login_view.dart
// ✅ لا تعدّل التصميم — مأخوذ من Figma

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/utils/animations.dart';
import 'package:locaydo_app/core/utils/helpers.dart';
import 'package:locaydo_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:locaydo_app/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:locaydo_app/shared/widgets/common/button.dart';
import 'package:locaydo_app/shared/widgets/form/input.dart';
import 'package:locaydo_app/core/utils/logger.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => LoginViewModel(
            repository: AuthRepositoryImpl(logger: DebugLogger()),
          ),
      child: const _LoginContent(),
    );
  }
}

class _LoginContent extends StatefulWidget {
  const _LoginContent();

  @override
  State<_LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends State<_LoginContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final anim = AppAnimations.createFullAnimation(this);
    _animCtrl = anim.controller;
    _fade = anim.fade;
    _slide = anim.slide;
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(BuildContext context, LoginViewModel vm) async {
    FocusScope.of(context).unfocus();

    final result = await vm.login();

    if (!context.mounted) return;

    switch (result) {
      case LoginResult.success:
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.mainNavigation,
          arguments: 0,
        );
      case LoginResult.emailNotVerified:
        Helpers.showSnackBar(
          context,
          'البريد الإلكتروني غير مفعل، يرجى تفعيل حسابك أولاً',
          color: AppColors.errorSnackBar,
        );
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.activationEmailSent,
          arguments: vm.emailController.text.trim(),
        );
      case LoginResult.failure:
        Helpers.showSnackBar(
          context,
          vm.errorMessage ?? 'حدث خطأ في تسجيل الدخول',
          color: AppColors.errorSnackBar,
        );
      case LoginResult.validationError:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Center(
                child: Container(
                  width: context.contentWidth,
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: context.topPadding),

                        Text(
                          AppStrings.loginTitle,
                          style: AppTextStyles.displayLarge(context).copyWith(
                            fontSize: context.responsiveFontSize(28),
                            color: AppColors.primary1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        Input(
                          label: AppStrings.emailLabel,
                          hintText: AppStrings.emailHint,
                          controller: vm.emailController,
                          errorText: vm.emailError,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => vm.clearFieldError('email'),
                        ),
                        const SizedBox(height: 16),

                        Input(
                          label: AppStrings.passwordLabel,
                          hintText: AppStrings.passwordHint,
                          controller: vm.passwordController,
                          errorText: vm.passwordError,
                          prefixIcon: Icons.lock_outline_rounded,
                          isSecure: true,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => vm.clearFieldError('password'),
                          onSubmitted: (_) => _handleLogin(context, vm),
                        ),
                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.forgotPassword,
                                ),
                            child: Text(
                              AppStrings.forgotPassword,
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.primary1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        Button(
                          text: AppStrings.loginButton,
                          onPressed: () => _handleLogin(context, vm),
                          isLoading: vm.isLoading,
                          variant: ButtonVariant.primary,
                          size: ButtonSize.medium,
                          isFullWidth: true,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.noAccount,
                              style: AppTextStyles.bodySmall(
                                context,
                              ).copyWith(color: AppColors.textSecondary),
                            ),
                            TextButton(
                              onPressed:
                                  () => Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.signup,
                                  ),
                              child: Text(
                                AppStrings.createAccount,
                                style: AppTextStyles.bodyLarge(
                                  context,
                                ).copyWith(
                                  color: AppColors.primary1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}