// lib/features/auth/presentation/screens/forgot_password_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/utils/animations.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:locaydo_app/features/auth/presentation/viewmodels/forgot_password_viewmodel.dart';
import 'package:locaydo_app/shared/widgets/common/button.dart';
import 'package:locaydo_app/shared/widgets/form/input.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordViewModel(
        repository: AuthRepositoryImpl(logger: DebugLogger()),
      ),
      child: const _ForgotPasswordContent(),
    );
  }
}

class _ForgotPasswordContent extends StatefulWidget {
  const _ForgotPasswordContent();

  @override
  State<_ForgotPasswordContent> createState() => _ForgotPasswordContentState();
}

class _ForgotPasswordContentState extends State<_ForgotPasswordContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final animation = AppAnimations.createFullAnimation(this);
    _animCtrl = animation.controller;
    _fade = animation.fade;
    _slide = animation.slide;
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// ✅ عرض رسالة نجاح تحتوي على متطلبات كلمة المرور (مثل الـ Signup)
  void _showPasswordRequirementsSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              ' تم إرسال رابط إعادة تعيين كلمة المرور',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              ' يرجى فتح الرابط وإنشاء كلمة مرور جديدة',
              style: TextStyle(fontSize: 13),
            ),
         
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorSnackBar,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleSend(BuildContext context, ForgotPasswordViewModel vm) async {
    FocusScope.of(context).unfocus();
    
    final result = await vm.sendResetLink();

    if (!mounted) return;

    switch (result) {
      case ForgotPasswordResult.success:
        // ✅ عرض رسالة النجاح مع متطلبات كلمة المرور
        _showPasswordRequirementsSnackBar(context);
        
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        });
        break;
        
      case ForgotPasswordResult.failure:
        _showErrorSnackBar(context, vm.errorMessage ?? 'حدث خطأ في إرسال الرابط');
        break;
        
      case ForgotPasswordResult.validationError:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ForgotPasswordViewModel>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Center(
                child: Container(
                  width: context.contentWidth,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(height: context.topPadding),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildTitle(context),
                              const SizedBox(height: 8),
                              _buildSubtitle(context),
                              SizedBox(height: context.verticalSpacingMedium),
                              Input(
                                hintText: AppStrings.emailHint_,
                                controller: vm.emailController,
                                errorText: vm.emailError,
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) => vm.clearEmailError(),
                                onSubmitted: (_) => _handleSend(context, vm),
                              ),
                              SizedBox(height: context.verticalSpacingMedium),
                              Button(
                                text: AppStrings.sendLink,
                                onPressed: () => _handleSend(context, vm),
                                isLoading: vm.isLoading,
                                variant: ButtonVariant.primary,
                                size: ButtonSize.medium,
                                isFullWidth: true,
                              ),
                              // ✅ إضافة ملاحظة عن متطلبات كلمة المرور
                              const SizedBox(height: 16),
                              _buildPasswordHint(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      AppStrings.forgotPasswordTitle,
      style: AppTextStyles.displayLarge(context).copyWith(
        fontSize: context.responsiveFontSize(28),
        color: AppColors.primary1,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      AppStrings.forgotPasswordSubtitle,
      style: AppTextStyles.bodyMedium(context).copyWith(
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// ✅ عرض متطلبات كلمة المرور (مثل الـ Signup)
  Widget _buildPasswordHint(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary1.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary1.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.primary1,
              ),
              const SizedBox(width: 8),
              Text(
                'عند إنشاء كلمة مرور جديدة:',
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ${AppStrings.passwordMinLength}',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• ${AppStrings.passwordFormat}',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}