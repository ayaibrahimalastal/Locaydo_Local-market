// lib/features/auth/presentation/views/account_activation_view.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/enums/activation_status.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/utils/animations.dart';
import 'package:locaydo_app/core/utils/helpers.dart';
import 'package:locaydo_app/features/auth/presentation/viewmodels/activation_viewmodel.dart';
import 'package:locaydo_app/shared/widgets/common/button.dart';

const _kTimerDuration   = 60;
const _kNavigationDelay = Duration(milliseconds: 800);

// ── Config Classes ───────────────────────────────────────────────────────────

abstract class ActivationScreenConfig {
  final ActivationStatus status;
  final String? email;
  final VoidCallback onContinue;
  final VoidCallback onResendLink;
  final VoidCallback? onBack;

  const ActivationScreenConfig({
    required this.status,
    this.email,
    required this.onContinue,
    required this.onResendLink,
    this.onBack,
  });
}

class SuccessConfig extends ActivationScreenConfig {
  const SuccessConfig({
    required super.onContinue,
    required super.onResendLink,
    super.onBack,
  }) : super(status: ActivationStatus.success);
}

class FailedConfig extends ActivationScreenConfig {
  const FailedConfig({
    super.email,
    required super.onContinue,
    required super.onResendLink,
    super.onBack,
  }) : super(status: ActivationStatus.failed);
}

class EmailSentConfig extends ActivationScreenConfig {
  const EmailSentConfig({
    required super.email,
    required super.onContinue,
    required super.onResendLink,
    super.onBack,
  }) : super(status: ActivationStatus.emailSent);
}

// ── Main View ─────────────────────────────────────────────────────────────────

class AccountActivationView extends StatefulWidget {
  final ActivationStatus status;
  final String?          email;
  final VoidCallback     onResendLink;
  final VoidCallback     onContinue;
  final VoidCallback?    onBack;

  const AccountActivationView({
    super.key,
    required this.status,
    this.email,
    required this.onResendLink,
    required this.onContinue,
    this.onBack,
  });

  @override
  State<AccountActivationView> createState() => _AccountActivationViewState();
}

class _AccountActivationViewState extends State<AccountActivationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  Timer? _timer;
  int    _remainingSeconds        = _kTimerDuration;
  bool   _isTimerExpired          = false;
  bool   _isMonitoring            = false;
  bool   _isWaitingForVerification = false;

  @override
  void initState() {
    super.initState();
    final anim = AppAnimations.createFullAnimation(this);
    _animCtrl = anim.controller;
    _fade = anim.fade;
    _slide = anim.slide;
    _animCtrl.forward();

    if (_shouldStartMonitoring) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startMonitoring();
          _startTimer();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  bool get _shouldStartMonitoring =>
      widget.status == ActivationStatus.emailSent && widget.email != null ||
      widget.status == ActivationStatus.failed && _isWaitingForVerification;

  // ── Monitoring ────────────────────────────────────────
  void _startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    final vm = context.read<ActivationViewModel>();
    vm.startMonitoring(
      onVerified: () {
        if (!mounted) return;
        _timer?.cancel();
        _onEmailVerified();
      },
      onFailed: () {
        if (!mounted) return;
        _timer?.cancel();
        _navigateToFailed();
      },
    );
  }

  Future<void> _onEmailVerified() async {
    Helpers.showSnackBar(
      context,
      'تم تفعيل حسابك بنجاح! جاري تسجيل الدخول...',
    );
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified && mounted) {
        Future.delayed(_kNavigationDelay, () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.activationSuccess);
          }
        });
      }
    }
  }

  // ── Timer ─────────────────────────────────────────────
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { 
        t.cancel(); 
        return; 
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else if (!_isTimerExpired) {
          _isTimerExpired = true;
          t.cancel();
          if (_isWaitingForVerification) {
            _isWaitingForVerification = false;
            Helpers.showSnackBar(
              context,
              'انتهى وقت التفعيل، يرجى طلب رابط جديد',
            );
          } else {
            _navigateToFailed();
          }
        }
      });
    });
  }

  void _navigateToFailed() {
    Navigator.pushReplacementNamed(
      context, 
      AppRoutes.activationFailed, 
      arguments: widget.email,
    );
  }

  // ── Resend ────────────────────────────────────────────
  Future<void> _handleResendLink(ActivationViewModel vm) async {
    if (vm.isResending) return;
    if (widget.email == null) return;
    
    await vm.resendLink(
      email: widget.email!,
      onSuccess: () {
        if (!mounted) return;
        widget.onResendLink();
        setState(() {
          _remainingSeconds        = _kTimerDuration;
          _isTimerExpired          = false;
          _isWaitingForVerification = true;
          _isMonitoring            = false;
        });
        _startTimer();
        _startMonitoring();
        Helpers.showSnackBar(
          context, 
          'تم إرسال رابط تفعيل جديد',
        );
      },
      onError: () {
        if (!mounted) return;
        Helpers.showSnackBar(
          context,
          vm.errorMessage ?? AppStrings.errorOccurred,
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActivationViewModel(),
      child: Consumer<ActivationViewModel>(
        builder: (context, vm, _) => Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(),
            body: SafeArea(
              child: AbsorbPointer(
                absorbing: vm.isResending,
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Center(
                      child: SizedBox(
                        width: context.contentWidth,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              SizedBox(height: context.topPadding),
                              Expanded(child: _buildContent(context, vm)),
                            ],
                          ),
                        ),
                      ),
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

  PreferredSizeWidget? _buildAppBar() {
    if (widget.status == ActivationStatus.success) return null;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: widget.onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
              onPressed: widget.onBack,
            )
          : null,
    );
  }

  Widget _buildContent(BuildContext context, ActivationViewModel vm) {
    final isEmailSent   = widget.status == ActivationStatus.emailSent;
    final showTimer     = (isEmailSent || _isWaitingForVerification) &&
                          !_isTimerExpired && _remainingSeconds > 0;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (vm.isChecking && (isEmailSent || _isWaitingForVerification) && !_isTimerExpired)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primaryDark),
            ),
          SizedBox(height: context.verticalSpacingLarge),
          _ActivationIcon(
            imagePath: vm.getImagePath(widget.status),
            size: _iconSize(context),
          ),
          SizedBox(height: context.verticalSpacingLarge),
          _ActivationTitle(text: vm.getTitle(widget.status)),
          SizedBox(height: context.verticalSpacingSmall),
          _ActivationMessage(text: vm.getMessage(widget.status)),
          if (showTimer) _TimerBadge(seconds: _remainingSeconds),
          if (_isTimerExpired && _isWaitingForVerification)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'انتهى وقت التفعيل، يرجى طلب رابط جديد',
                style: AppTextStyles.bodySmall(context)
                    .copyWith(color: AppColors.errorFields),
              ),
            ),
          if (vm.errorMessage != null &&
              !_isWaitingForVerification &&
              widget.status == ActivationStatus.failed)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                vm.errorMessage!,
                style: AppTextStyles.bodySmall(context)
                    .copyWith(color: AppColors.errorFields),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(height: context.verticalSpacingMedium),
          if (widget.email != null && isEmailSent)
            _EmailCard(email: widget.email!),
          SizedBox(height: context.verticalSpacingMedium),
          _ActivationButton(
            status:         widget.status,
            isLoading:      vm.isResending,
            onContinue:     widget.onContinue,
            onResendLink:   () => _handleResendLink(vm),
            isTimerExpired: _isTimerExpired,
            isWaiting:      _isWaitingForVerification,
          ),
          SizedBox(height: context.verticalSpacingSmall),
        ],
      ),
    );
  }

  double _iconSize(BuildContext context) {
    final w = context.screenWidth;
    if (w > 600) return 150;
    if (w > 400) return 120;
    return 100;
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ActivationIcon extends StatelessWidget {
  final String imagePath;
  final double size;
  const _ActivationIcon({required this.imagePath, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: SvgPicture.asset(
        imagePath,
        width: size * 0.7, height: size * 0.7,
        colorFilter: const ColorFilter.mode(AppColors.primaryDark, BlendMode.srcIn),
      ),
    );
  }
}

class _ActivationTitle extends StatelessWidget {
  final String text;
  const _ActivationTitle({required this.text});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.displayLarge(context).copyWith(
          color: AppColors.primaryDark, fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      );
}

class _ActivationMessage extends StatelessWidget {
  final String text;
  const _ActivationMessage({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          text,
          style: AppTextStyles.bodyLarge(context).copyWith(
            color: AppColors.textSecondary, height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      );
}

class _TimerBadge extends StatelessWidget {
  final int seconds;
  const _TimerBadge({required this.seconds});

  @override
  Widget build(BuildContext context) => Container(
        margin:  const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'الوقت المتبقي للتفعيل: $seconds ثانية',
          style: AppTextStyles.bodySmall(context)
              .copyWith(color: AppColors.primaryDark),
        ),
      );
}

class _EmailCard extends StatelessWidget {
  final String email;
  const _EmailCard({required this.email});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AppColors.primaryDark.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: AppColors.primaryDark.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.email_outlined, color: AppColors.primaryDark, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.sentTo,
                      style: AppTextStyles.bodySmall(context)
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(email,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ActivationButton extends StatelessWidget {
  final ActivationStatus status;
  final bool             isLoading;
  final VoidCallback     onContinue;
  final VoidCallback     onResendLink;
  final bool             isTimerExpired;
  final bool             isWaiting;

  const _ActivationButton({
    required this.status,
    required this.isLoading,
    required this.onContinue,
    required this.onResendLink,
    this.isTimerExpired = false,
    this.isWaiting      = false,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ActivationStatus.emailSent => !isTimerExpired
          ? const SizedBox.shrink()
          : Column(children: [
              const SizedBox(height: 16),
              Button(
                text:        AppStrings.resendLink,
                onPressed:   onResendLink,
                isLoading:   isLoading,
                variant:     ButtonVariant.primary,
                size:        ButtonSize.medium,
                isFullWidth: true,
              ),
            ]),
      ActivationStatus.success => Button(
          text:        AppStrings.continueToApp,
          onPressed:   onContinue,
          variant:     ButtonVariant.primary,
          size:        ButtonSize.medium,
          isFullWidth: true,
        ),
      ActivationStatus.failed => isWaiting
          ? const SizedBox.shrink()
          : Button(
              text:        AppStrings.sendNewLink,
              onPressed:   onResendLink,
              isLoading:   isLoading,
              variant:     ButtonVariant.primary,
              size:        ButtonSize.medium,
              isFullWidth: true,
            ),
    };
  }
}