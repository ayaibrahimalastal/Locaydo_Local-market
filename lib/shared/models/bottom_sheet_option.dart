// lib/shared/models/bottom_sheet_option.dart

import 'package:flutter/material.dart';

class BottomSheetOption {
  final IconData    icon;
  final String      title;
  final VoidCallback onTap;
  final Color?      iconColor;

  BottomSheetOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });
}