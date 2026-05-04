// lib/widgets/form/phone_input.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';

class PhoneInput extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final String? errorText;
  final CountryCode selectedCode;
  final Function(CountryCode) onCodeChanged;
  final Function(String)? onChanged;
  final VoidCallback? onSubmitted;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  const PhoneInput({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.errorText,
    required this.selectedCode,
    required this.onCodeChanged,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
  });

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.enabled;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== Label ==========
          if (widget.label != null && widget.label!.isNotEmpty) ...[
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                widget.label!,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ========== حقل الهاتف مع رمز البلد ==========
          SizedBox(
            height: FigmaDesignSystem.fieldHeight,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  FigmaDesignSystem.borderRadius,
                ),
                border: Border.all(
                  color: _getBorderColor(),
                  width: _hasFocus ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  // ========== رقم الهاتف ==========
                  Expanded(
                    child: TextFormField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      onChanged: isEnabled ? widget.onChanged : null,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color:
                            isEnabled
                                ? AppColors.textPrimary
                                : AppColors.textPlaceholder,
                      ),
                      enabled: isEnabled,
                      cursorColor: AppColors.primary1,
                      textInputAction:
                          widget.textInputAction ?? TextInputAction.done,
                      onFieldSubmitted: (_) => widget.onSubmitted?.call(),

                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],

                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: AppTextStyles.hintText(
                          context,
                        ).copyWith(color: AppColors.textPlaceholder),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),

                  // ========== رمز البلد مع القائمة المنسدلة ==========
                  _CountryCodeDropdown(
                    selectedCode: widget.selectedCode,
                    onChanged: isEnabled ? widget.onCodeChanged : null,
                  ),
                ],
              ),
            ),
          ),

          // ========== رسالة الخطأ ==========
          if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
            const SizedBox(height: FigmaDesignSystem.gapBetweenFields * 0.25),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.errorFields,
                      size: FigmaDesignSystem.getResponsiveFontSize(
                        context,
                        14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.errorText!,
                        style: AppTextStyles.errorText(context).copyWith(
                          fontSize: FigmaDesignSystem.getResponsiveFontSize(
                            context,
                            12,
                          ),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (!widget.enabled) return const Color(0xFFE0E0E0);
    if (_hasFocus) return AppColors.primary1;
    if (widget.errorText != null) return AppColors.errorFields;
    return AppColors.stroke;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Country Code Dropdown Widget
// ──────────────────────────────────────────────────────────────────────────────

class _CountryCodeDropdown extends StatelessWidget {
  final CountryCode selectedCode;
  final Function(CountryCode)? onChanged;

  const _CountryCodeDropdown({required this.selectedCode, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onChanged != null;

    return PopupMenuButton<CountryCode>(
      onSelected: onChanged,
      enabled: isEnabled,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isEnabled ? AppColors.stroke : const Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCode.code,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color:
                    isEnabled
                        ? AppColors.textPrimary
                        : AppColors.textPlaceholder,
              ),
            ),
            const SizedBox(width: 4),
            const _PalestinianFlag(),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color:
                  isEnabled
                      ? AppColors.textSecondary
                      : AppColors.textPlaceholder,
            ),
          ],
        ),
      ),
      itemBuilder:
          (context) =>
              CountryCode.values.map((code) {
                return PopupMenuItem<CountryCode>(
                  value: code,
                  child: Row(
                    children: [
                      Text(code.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        '${code.code} (${code.countryName})',
                        style: AppTextStyles.bodyMedium(context),
                      ),
                    ],
                  ),
                );
              }).toList(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Palestinian Flag Widget (Custom Paint)
// ──────────────────────────────────────────────────────────────────────────────

class _PalestinianFlag extends StatelessWidget {
  const _PalestinianFlag();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 13,
      child: CustomPaint(painter: _PalestinianFlagPainter()),
    );
  }
}

class _PalestinianFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Black stripe
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h / 3),
      Paint()..color = const Color(0xFF1A1A1A),
    );

    // White stripe
    canvas.drawRect(
      Rect.fromLTWH(0, h / 3, w, h / 3),
      Paint()..color = Colors.white,
    );

    // Green stripe
    canvas.drawRect(
      Rect.fromLTWH(0, 2 * h / 3, w, h / 3),
      Paint()..color = const Color(0xFF009933),
    );

    // Red triangle
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(w * 0.55, h / 2)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = const Color(0xFFE31D1C),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
