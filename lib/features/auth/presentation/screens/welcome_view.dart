// lib/features/auth/presentation/screens/welcome_view.dart
import 'package:flutter/material.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';
import 'package:locaydo_app/shared/widgets/common/button.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.welcomeBackground,
        body: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = context.contentWidth;
              return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Container(
                      width: contentWidth,
                     
                      child: Column(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(height: context.topPadding),
                          _WelcomeImage(contentWidth: contentWidth),
                          SizedBox(height: context.verticalSpacingLarge),
                          _WelcomeCard(contentWidth: contentWidth),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeImage extends StatelessWidget {
  final double contentWidth;
  const _WelcomeImage({required this.contentWidth});

  @override
  Widget build(BuildContext context) {
    final imageHeight = context.verticalSpacingLarge * 7;
    
    return SizedBox(
      height: imageHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SvgPicture.asset(
          AppAssets.welcome,
          width: contentWidth,
          height: imageHeight,
          fit: BoxFit.cover,
          placeholderBuilder: (__) => Container(
            color: Colors.white.withOpacity(0.2),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: context.screenWidth * 0.15,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final double contentWidth;
  const _WelcomeCard({required this.contentWidth});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = context.screenHeight < 600;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: FigmaDesignSystem.horizontalPadding,
        vertical: context.verticalSpacingMedium,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(175),
          topRight: Radius.circular(175),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: context.topPadding ),
          Text(
            AppStrings.welcomeTitle,
            style: AppTextStyles.displayLarge(context).copyWith(
              color: AppColors.primary1,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 12 : context.verticalSpacingSmall),
          Text(
            AppStrings.welcomeDescription,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
              fontWeight: FontWeight.w500
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 20 : context.verticalSpacingMedium),
          Button(
            text: AppStrings.loginButton,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            variant: ButtonVariant.primary,
            size: ButtonSize.medium,
            isFullWidth: true,
          ),
          SizedBox(height: isSmallScreen ? 8 : context.verticalSpacingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.noAccount,
                style: AppTextStyles.bodySmall(context),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
                child: Text(
                  AppStrings.createAccount,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}