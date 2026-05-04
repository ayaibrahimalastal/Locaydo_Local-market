// lib/shared/widgets/common/confirmation_dialog.dart
import 'package:flutter/material.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';

class ConfirmationDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
    Color? titleColor,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: titleColor ?? AppColors.primary1)),
        content: Text(content,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16, color: AppColors.textSecondary)),
        actions: [
          Row(children: [
            Expanded(child: _cancelBtn(ctx)),
            const SizedBox(width: 12),
            Expanded(
              child: _confirmBtn(
                  context: ctx,
                  onPressed: onConfirm,
                  color: confirmColor,
                  text: confirmText),
            ),
          ]),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      ),
    );
  }

  static Widget _cancelBtn(BuildContext ctx) => TextButton(
        onPressed: () => Navigator.pop(ctx),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.stroke),
          ),
        ),
        child: const Text('إلغاء',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
      );

  static Widget _confirmBtn({
    required BuildContext context,
    required VoidCallback onPressed,
    required Color color,
    required String text,
  }) =>
      ElevatedButton(
        onPressed: () { 
          Navigator.pop(context); 
          onPressed(); 
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color, 
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      );

  static Future<void> showLogoutDialog({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) =>
      show(
        context: context,
        title: 'تسجيل الخروج',
        content: 'هل أنت متأكد من تسجيل الخروج؟',
        confirmText: 'تسجيل الخروج',
        confirmColor: AppColors.errorFields,
        onConfirm: onConfirm,
        titleColor: AppColors.errorFields,
      );

  static Future<void> showDeleteAccountDialog({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) =>
      show(
        context: context,
        title: 'حذف الحساب',
        content: 'هل أنت متأكد؟ لا يمكن التراجع عن هذا الإجراء.',
        confirmText: 'حذف الحساب',
        confirmColor: AppColors.errorFields,
        onConfirm: onConfirm,
        titleColor: AppColors.errorFields,
      );
}