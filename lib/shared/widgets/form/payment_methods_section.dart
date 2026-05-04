import 'package:flutter/material.dart';
import 'package:locaydo_app/core/constants/app_strings.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';


// ──────────────────────────────────────────────────────────────────────────────
// Payment Methods Section (الرئيسي)
// ──────────────────────────────────────────────────────────────────────────────

class PaymentMethodsSection extends StatelessWidget {
  final List<PaymentMethod> selectedPayments;
  final String? paymentError;
  final Function(PaymentMethod) onAdd;
  final Function(PaymentMethod) onRemove;
  final List<PaymentMethod> allMethods;
  final String? label;
  final bool isEnabled;

  const PaymentMethodsSection({
    super.key,
    required this.selectedPayments,
    this.paymentError,
    required this.onAdd,
    required this.onRemove,
    required this.allMethods,
    this.label,
    this.isEnabled = true,
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

        // Container عرض الطرق المحددة
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: FigmaDesignSystem.fieldInnerPaddingHorizontal,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: paymentError != null ? AppColors.errorFields : AppColors.stroke,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
            color: isEnabled ? Colors.white : AppColors.disabledBackground,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...selectedPayments.map((method) {
                  return _PaymentChip(
                    method: method.label,
                    onRemove: isEnabled ? () => onRemove(method) : () {},
                  );
                }).toList(),
                const SizedBox(width: 8),
                Text(
                  AppStrings.paymentMethodsHint,
                  style: AppTextStyles.hintText(context).copyWith(
                    color: isEnabled ? null : AppColors.textPlaceholder,
                  ),
                ),
              ],
            ),
          ),
        ),

        // رسالة الخطأ
        if (paymentError != null) ...[
          const SizedBox(height: 4),
          Container(
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
                    paymentError!,
                    style: AppTextStyles.errorText(context),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),

        // طرق الدفع المتاحة للإضافة
        if (isEnabled)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: allMethods
                .where((p) => !selectedPayments.contains(p))
                .map((method) {
              return GestureDetector(
                onTap: () => onAdd(method),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: FigmaDesignSystem.fieldInnerPaddingHorizontal,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.stroke, width: 0.5),
                    borderRadius:
                        BorderRadius.circular(FigmaDesignSystem.borderRadius),
                    color: Colors.white,
                  ),
                  child: Text(
                    '+ ${method.label}',
                    style: AppTextStyles.hintText(context),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Payment Chip (مدمج داخلياً)
// ──────────────────────────────────────────────────────────────────────────────

class _PaymentChip extends StatelessWidget {
  final String method;
  final VoidCallback onRemove;

  const _PaymentChip({
    required this.method,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBank = method == AppStrings.paymentBank;

    return Container(
      margin: EdgeInsets.only(right: FigmaDesignSystem.gapBetweenFields * 0.25),
      padding: EdgeInsets.symmetric(
        horizontal: FigmaDesignSystem.gapBetweenFields * 0.5,
        vertical: FigmaDesignSystem.gapBetweenFields * 0.25,
      ),
      decoration: BoxDecoration(
        color: isBank
            ? const Color(0xFFFFEFF9)
            : const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: FigmaDesignSystem.getResponsiveFontSize(context, 12),
              color: AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            method,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.bold,
              color: isBank
                  ? const Color(0xFFB41A75)
                  : AppColors.primary1,
            ),
          ),
        ],
      ),
    );
  }
}