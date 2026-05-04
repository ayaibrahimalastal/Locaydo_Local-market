// lib/features/auth/presentation/screens/signup_view.dart
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
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:locaydo_app/features/auth/presentation/viewmodels/signup_viewmodel.dart';
import 'package:locaydo_app/shared/widgets/common/button.dart';
import 'package:locaydo_app/shared/widgets/form/input.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => SignupViewModel(
            repository: AuthRepositoryImpl(logger: DebugLogger()),
          ),
      child: const _SignupContent(),
    );
  }
}

class _SignupContent extends StatefulWidget {
  const _SignupContent();

  @override
  State<_SignupContent> createState() => _SignupContentState();
}

class _SignupContentState extends State<_SignupContent>
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

  Future<void> _handleSignup(BuildContext context, SignupViewModel vm) async {
    FocusScope.of(context).unfocus();

    final result = await vm.signup();

    if (!context.mounted) return;

    switch (result) {
      case SignupResult.success:
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.activationEmailSent,
          arguments: vm.emailController.text.trim(),
        );
      case SignupResult.failure:
        // الأخطاء المتعلقة بالحقول تُعرض مباشرة في الحقل من الـ ViewModel
        // الأخطاء العامة تُعرض في Snackbar
        if (vm.emailError == null && vm.passwordError == null) {
          Helpers.showSnackBar(
            context,
            vm.errorMessage ?? 'حدث خطأ في التسجيل',
            color: AppColors.errorSnackBar,
          );
        }
      case SignupResult.validationError:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();

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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: context.topPadding),

                        Text(
                          AppStrings.signupTitle,
                          style: AppTextStyles.displayLarge(context).copyWith(
                            fontSize: context.responsiveFontSize(28),
                            color: AppColors.primary1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        Input(
                          label: AppStrings.usernameLabel,
                          hintText: AppStrings.usernameHint,
                          controller: vm.usernameController,
                          errorText: vm.usernameError,
                          prefixIcon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => vm.clearFieldError('username'),
                        ),
                        const SizedBox(height: 16),

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
                          label: AppStrings.createPasswordLabel,
                          hintText: AppStrings.passwordHint,
                          controller: vm.passwordController,
                          errorText: vm.passwordError,
                          prefixIcon: Icons.lock_outline_rounded,
                          isSecure: true,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => vm.clearFieldError('password'),
                        ),
                        const SizedBox(height: 16),

                        Input(
                          label: AppStrings.confirmPasswordLabel,
                          hintText: AppStrings.passwordHint,
                          controller: vm.confirmController,
                          errorText: vm.confirmError,
                          prefixIcon: Icons.lock_rounded,
                          isSecure: true,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => vm.clearFieldError('confirm'),
                          onSubmitted: (_) => _handleSignup(context, vm),
                        ),
                        const SizedBox(height: 32),

                        Button(
                          text: AppStrings.signupButton,
                          onPressed: () => _handleSignup(context, vm),
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
                              AppStrings.haveAccount,
                              style: AppTextStyles.bodySmall(
                                context,
                              ).copyWith(color: AppColors.textSecondary),
                            ),
                            TextButton(
                              onPressed:
                                  () => Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.login,
                                  ),
                              child: Text(
                                AppStrings.loginButton,
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