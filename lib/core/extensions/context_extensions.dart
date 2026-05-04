// lib/core/extensions/context_extensions.dart
// ✅ يدمج كل extensions المتكررة في الشاشات (topPadding, contentWidth, ...)

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';

extension AppContext on BuildContext {
  double get contentWidth => FigmaDesignSystem.getResponsiveWidth(this);

  double get topPadding {
    final height = MediaQuery.of(this).size.height;
    if (height > 800) return 60;
    if (height > 600) return 40;
    return 20;
  }

  /// مسافات عمودية متجاوبة
  double verticalSpacing(double factor) => 
      MediaQuery.of(this).size.height * factor.clamp(0.01, 0.1);
  
  double get verticalSpacingSmall  => verticalSpacing(0.02);
  double get verticalSpacingMedium => verticalSpacing(0.03);
  double get verticalSpacingLarge  => verticalSpacing(0.05);

  double get screenWidth  => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  double get horizontalPadding => FigmaDesignSystem.horizontalPadding;
  double get fieldSpacing      => FigmaDesignSystem.gapBetweenFields;
  double get sectionSpacing    => 24.0;

  /// حجم خط متجاوب مع حجم الشاشة
  double responsiveFontSize(double baseSize, {double minSize = 10, double maxSize = 32}) {
    final width = screenWidth;
    double scale;
    
    if (width > 600) {
      scale = 1.2;  // تابلت
    } else if (width > 400) {
      scale = 1.1;  // جوال كبير
    } else {
      scale = 1.0;  // جوال صغير
    }
    
    double calculatedSize = baseSize * scale;
    return calculatedSize.clamp(minSize, maxSize);
  }
  
  // نوع الجهاز
  bool get isTablet => screenWidth > 600;
  bool get isLargePhone => screenWidth > 400 && screenWidth <= 600;
  bool get isSmallPhone => screenWidth <= 400;
}

extension AppContextTheme on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
}

extension AppContextNavigation on BuildContext {
  void pushNamed(String routeName, {Object? arguments}) {
    Navigator.pushNamed(this, routeName, arguments: arguments);
  }
  
  void pushReplacementNamed(String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(this, routeName, arguments: arguments);
  }
  
  void pop<T>([T? result]) {
    Navigator.pop(this, result);
  }
  
  bool get canPop => Navigator.canPop(this);
}