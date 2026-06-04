// lib/features/auth/presentation/screens/splash_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // ✅ إضافة import
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';
import 'package:locaydo_app/core/utils/animations.dart';

class SplashView extends StatefulWidget {
  final VoidCallback? onNavigationComplete;
  final Duration splashDuration;

  const SplashView({
    super.key,
    this.onNavigationComplete,
    required this.splashDuration,
  });

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startNavigationTimer();
    
    // ✅ التأكد من إخفاء Native Splash إذا كانت لا تزال ظاهرة
    FlutterNativeSplash.remove();
  }

  void _initAnimations() {
    _controller = AppAnimations.createFadeSlideController(this);
    _fadeAnimation = AppAnimations.createFadeAnimation(_controller);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  void _startNavigationTimer() {
    _navigationTimer = Timer(widget.splashDuration, _onNavigationComplete);
  }

  void _onNavigationComplete() {
    if (!mounted) return;
    
    if (widget.onNavigationComplete != null) {
      widget.onNavigationComplete!();
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = context.screenWidth * 0.7;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.primaryGradient,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                AppAssets.splash,
                width: logoSize,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildFallbackLogo(context, logoSize),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackLogo(BuildContext context, double size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.shopping_cart_rounded,
          size: size * 0.5,
          color: Colors.white,
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.appName,
          style: AppTextStyles.displayLarge(context).copyWith(
            color: Colors.white,
            fontSize: size * 0.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.appSubtitle,
          style: AppTextStyles.bodyLarge(context).copyWith(
            color: Colors.white70,
            fontSize: size * 0.08,
          ),
        ),
      ],
    );
  }
}