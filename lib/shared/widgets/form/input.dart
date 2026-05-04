// lib/widgets/core/input.dart

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';

class Input extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final Function(String)? onChanged;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final bool isSecure;
  final int? minLines;
  final int? maxLines;

  const Input({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.errorText,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.isSecure = false,
    this.minLines,
    this.maxLines,
  });

  @override
  State<Input> createState() => _InputState();
}

class _InputState extends State<Input> {
  late FocusNode _focusNode;
  bool _hasFocus = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _obscureText = widget.isSecure;
  }

  void _handleFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
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
    final bool isMultiline = (widget.maxLines ?? 1) > 1;

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
                  color: AppColors.textPrimary ,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ========== حقل الإدخال ==========
          isMultiline
              ? _buildMultilineField(context, isEnabled)
              : _buildSingleLineField(context, isEnabled),

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
                      size: FigmaDesignSystem.getResponsiveFontSize(context, 14),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.errorText!,
                        style: AppTextStyles.errorText(context).copyWith(
                          fontSize: FigmaDesignSystem.getResponsiveFontSize(context, 12),
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

  Widget _buildSingleLineField(BuildContext context, bool isEnabled) {
    return SizedBox(
      height: FigmaDesignSystem.fieldHeight,
      child: TextFormField(
        controller: widget.controller,
        onChanged: isEnabled ? widget.onChanged : null,
        minLines: 1,
        maxLines: 1,
        keyboardType: widget.keyboardType,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        obscureText: _obscureText,
        style: AppTextStyles.bodyMedium(context).copyWith(
          color: isEnabled ? AppColors.textPrimary : AppColors.textPlaceholder,
        ),
        enabled: isEnabled,
        focusNode: _focusNode,
        cursorColor: AppColors.primary1,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTextStyles.hintText(context).copyWith(
            color: AppColors.textPlaceholder,
          ),
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  size: 20,
                  color: _getIconColor(isEnabled),
                )
              : null,
          suffixIcon: widget.isSecure
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: _getIconColor(isEnabled),
                  ),
                  onPressed: isEnabled ? _toggleObscureText : null,
                )
              : (widget.suffixIcon != null
                  ? IconButton(
                      icon: Icon(
                        widget.suffixIcon,
                        size: 20,
                        color: _getIconColor(isEnabled),
                      ),
                      onPressed: isEnabled ? widget.onSuffixIconPressed : null,
                    )
                  : null),
          filled: true,
          fillColor: Colors.white,  // ✅ أبيض دائماً
          contentPadding: EdgeInsets.symmetric(
            horizontal: FigmaDesignSystem.fieldInnerPaddingHorizontal,
            vertical: FigmaDesignSystem.fieldInnerPaddingVertical,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
            borderSide: BorderSide(
              color: _getBorderColor(isEnabled),
              width: 0.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
            borderSide: BorderSide(
              color: _getBorderColor(isEnabled),
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
            borderSide: const BorderSide(
              color: AppColors.primary1,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
            borderSide: const BorderSide(color: AppColors.errorFields, width: 0.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildMultilineField(BuildContext context, bool isEnabled) {
    return TextFormField(
      controller: widget.controller,
      onChanged: isEnabled ? widget.onChanged : null,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      obscureText: _obscureText,
      style: AppTextStyles.bodyMedium(context).copyWith(
        color: isEnabled ? AppColors.textPrimary : AppColors.textPlaceholder,
      ),
      enabled: isEnabled,
      focusNode: _focusNode,
      cursorColor: AppColors.primary1,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTextStyles.hintText(context).copyWith(
          color: AppColors.textPlaceholder,
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                size: 20,
                color: _getIconColor(isEnabled),
              )
            : null,
        suffixIcon: widget.isSecure
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: _getIconColor(isEnabled),
                ),
                onPressed: isEnabled ? _toggleObscureText : null,
              )
            : (widget.suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      widget.suffixIcon,
                      size: 20,
                      color: _getIconColor(isEnabled),
                    ),
                    onPressed: isEnabled ? widget.onSuffixIconPressed : null,
                  )
                : null),
        filled: true,
        fillColor: Colors.white,  // ✅ أبيض دائماً
        contentPadding: EdgeInsets.symmetric(
          horizontal: FigmaDesignSystem.fieldInnerPaddingHorizontal,
          vertical: FigmaDesignSystem.fieldInnerPaddingVertical,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
          borderSide: BorderSide(
            color: _getBorderColor(isEnabled),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
          borderSide: BorderSide(
            color: _getBorderColor(isEnabled),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
          borderSide: const BorderSide(
            color: AppColors.primary1,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
          borderSide: const BorderSide(color: AppColors.errorFields, width: 0.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FigmaDesignSystem.borderRadius),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
    );
  }

  Color _getBorderColor(bool isEnabled) {
    if (!isEnabled) return const Color(0xFFE0E0E0);
    if (_hasFocus) return AppColors.primary1;
    if (widget.errorText != null) return AppColors.errorFields;
    return AppColors.stroke;
  }

  Color _getIconColor(bool isEnabled) {
    if (!isEnabled) return const Color(0xFFBDBDBD);
    if (_hasFocus) return AppColors.primary1;
    return const Color(0xFF969696);
  }
}