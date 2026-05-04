import 'package:flutter/material.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';
class DropdownBuilder<T> extends StatelessWidget {
  final T value;
  final Function(T?) onChanged;
  final List<T> items;
  final String Function(T) getLabel;
  final String? label;
  final String? hintText;        // ✅ إضافة
  final String? errorText;
  final bool enabled;

  const DropdownBuilder({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    required this.getLabel,
    this.label,
    this.hintText,                // ✅
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Label
        if (label != null && label!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            child: Text(
              label!,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Dropdown Container
        Container(
          height: FigmaDesignSystem.fieldHeight,
          decoration: BoxDecoration(
            border: Border.all(
              color: errorText != null 
                  ? AppColors.errorFields 
                  : (enabled ? AppColors.stroke : AppColors.disabledBorder),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
            color: enabled ? Colors.white : AppColors.disabledBackground,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              onChanged: enabled ? onChanged : null,
              hint: hintText != null  // ✅ إضافة hint
                  ? Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: FigmaDesignSystem.fieldInnerPaddingHorizontal),
                      child: Text(
                        hintText!,
                        style: AppTextStyles.hintText(context),
                      ),
                    )
                  : null,
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: FigmaDesignSystem.fieldInnerPaddingHorizontal),
                    child: Text(
                      getLabel(item),
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: enabled ? AppColors.textPrimary : AppColors.textPlaceholder,
                      ),
                    ),
                  ),
                );
              }).toList(),
              isExpanded: true,
              icon: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: FigmaDesignSystem.fieldInnerPaddingHorizontal),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: enabled ? AppColors.textPlaceholder : AppColors.disabledBorder,
                ),
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
              alignment: Alignment.centerRight,
            ),
          ),
        ),

        // Error Message
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
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
                  errorText!,
                  style: AppTextStyles.errorText(context),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}