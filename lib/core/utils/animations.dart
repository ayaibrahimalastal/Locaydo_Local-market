// lib/core/utils/animations.dart
import 'package:flutter/material.dart';

/// كلاس مركزي لإدارة الأنيميشن في التطبيق
class AppAnimations {
  // ── ثوابت لتوحيد القيم ──────────────────────────────────────────────
  static const Duration defaultDuration = Duration(milliseconds: 1200);
  static const double slideStartOffset = 0.3;
  static const double fadeStartOpacity = 0.0;
  static const double fadeEndOpacity = 1.0;
  static const Curve fadeCurve = Curves.easeIn;
  static const Curve slideCurve = Curves.easeOut;

  // ── دوال إنشاء الأنيميشن ────────────────────────────────────────────
  static AnimationController createFadeSlideController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: defaultDuration,
    );
  }

  static Animation<double> createFadeAnimation(AnimationController controller) {
    return Tween<double>(
      begin: fadeStartOpacity,
      end: fadeEndOpacity,
    ).animate(
      CurvedAnimation(parent: controller, curve: fadeCurve),
    );
  }

  static Animation<Offset> createSlideAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: Offset(0, slideStartOffset),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: controller, curve: slideCurve),
    );
  }

  /// إنشاء جميع عناصر الأنيميشن دفعة واحدة
  static ({
    AnimationController controller,
    Animation<double> fade,
    Animation<Offset> slide,
  }) createFullAnimation(TickerProvider vsync) {
    final controller = createFadeSlideController(vsync);
    return (
      controller: controller,
      fade: createFadeAnimation(controller),
      slide: createSlideAnimation(controller),
    );
  }

  static void runFadeSlide({
    required AnimationController controller,
    VoidCallback? onComplete,
  }) {
    controller.forward().then((_) {
      if (onComplete != null) onComplete();
    });
  }

  static void resetAndRun(AnimationController controller) {
    controller.reset();
    controller.forward();
  }
}

/// ويدجت جاهز للأنيميشن
class FadeSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final VoidCallback? onComplete;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.duration = AppAnimations.defaultDuration,
    this.onComplete,
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _fade = AppAnimations.createFadeAnimation(_controller);
    _slide = AppAnimations.createSlideAnimation(_controller);
    _controller.forward().then((_) {
      if (widget.onComplete != null) widget.onComplete!();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}