// lib/features/profile/presentation/screens/vendor_check_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:locaydo_app/core/constants/app_assets.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/extensions/context_extensions.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/features/profile/presentation/screens/seller_profile_setup_screen.dart';
import 'package:locaydo_app/shared/widgets/common/button.dart';

class VendorCheckScreen extends StatelessWidget {
  const VendorCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = context.screenHeight;
    final contentWidth = context.contentWidth;
    final spacingLarge = screenHeight * 0.2;
    final spacingMedium = screenHeight * 0.1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          centerTitle: true,
          title: Text(
            AppStrings.vendorCheckTitle,
            style: AppTextStyles.displaySmall(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: contentWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: screenHeight > 700 ? spacingLarge : spacingMedium,
                      ),
                      SvgPicture.asset(
                        AppAssets.vendorcheck,
                        width: contentWidth * 0.3,
                        height: contentWidth * 0.3,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 40),
                      Text(
                        AppStrings.vendorCheckMessage,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: AppColors.textPrimary,
                          fontSize: context.responsiveFontSize(18),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Button(
                        text: AppStrings.vendorCheckButton,
                        onPressed: () {
                          // ✅ استخدام pushReplacement لتجنب تراكم الشاشات
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SellerProfileSetupScreen(
                                source: 'add_product',
                              ),
                            ),
                          );
                        },
                        variant: ButtonVariant.primary,
                        size: ButtonSize.medium,
                        isFullWidth: true,
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
}