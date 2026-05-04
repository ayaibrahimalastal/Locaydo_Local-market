import 'package:flutter/material.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';

class ErrorRow extends StatelessWidget {
  final String error;

  const ErrorRow({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.errorFields,
            size: FigmaDesignSystem.getResponsiveFontSize(context, 14),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              error,
              style: AppTextStyles.errorText(context),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}