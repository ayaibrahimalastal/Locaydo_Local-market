// lib/features/search/widgets/location_filter_overlay.dart

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/figma_design_system.dart';

/// نافذة فلترة الموقع - تظهر من الأسفل
class LocationFilterOverlay extends StatefulWidget {
  final List<String> governorates;
  final Function(List<String>) onApplyFilters;
  final List<String> initialSelectedLocations;

  const LocationFilterOverlay({
    super.key,
    required this.governorates,
    required this.onApplyFilters,
    this.initialSelectedLocations = const [],
  });

  /// دالة مساعدة لعرض النافذة
  static Future<void> show({
    required BuildContext context,
    required List<String> governorates,
    required Function(List<String>) onApplyFilters,
    List<String> initialSelectedLocations = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: LocationFilterOverlay(
          governorates: governorates,
          onApplyFilters: onApplyFilters,
          initialSelectedLocations: initialSelectedLocations,
        ),
      ),
    );
  }

  @override
  State<LocationFilterOverlay> createState() => _LocationFilterOverlayState();
}

class _LocationFilterOverlayState extends State<LocationFilterOverlay>
    with SingleTickerProviderStateMixin {
  late List<String> _selectedLocations;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // ✅ المواقع المتطابقة مع Location enum في product_enums.dart
  final List<String> _governoratesList = [
    'شمال غزة',  // Location.northGaza
    'غزة المدينة', // Location.gazaCity
    'الوسطى',     // يتم إضافته يدوياً
    'خان يونس',    // Location.khanYounis
    'رفح',        // Location.rafah
    'دير البلح',   // Location.derBalah
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocations = List.from(widget.initialSelectedLocations);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// تبديل تحديد منطقة
  void _toggleLocation(String locationName) {
    setState(() {
      if (_selectedLocations.contains(locationName)) {
        _selectedLocations.remove(locationName);
      } else {
        _selectedLocations.add(locationName);
      }
    });
  }

  /// إزالة منطقة محددة
  void _removeLocation(String locationName) {
    setState(() {
      _selectedLocations.remove(locationName);
    });
  }

  /// إعادة تعيين جميع الفلاتر
  void _resetFilters() {
    setState(() {
      _selectedLocations.clear();
    });
  }

  /// تطبيق الفلاتر
  void _applyFilters() {
    widget.onApplyFilters(_selectedLocations);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final contentWidth = FigmaDesignSystem.getResponsiveWidth(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value * screenHeight * 0.1),
            child: child,
          );
        },
        child: Container(
          width: contentWidth,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.6,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ========== Header ==========
              _buildHeader(),

              // ========== Content ==========
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اختر محافظة',
                        style: TextStyle(
                          fontFamily: 'Dubai',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ أزرار المحافظات مرتبة أفقياً
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _governoratesList.map((governorate) {
                          return _buildGovernorateChip(governorate);
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // ✅ إضافة ملاحظة صغيرة
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary1.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.primary1.withOpacity(0.7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'يمكنك اختيار أكثر من محافظة للحصول على نتائج أوسع',
                                style: TextStyle(
                                  fontFamily: 'Dubai',
                                  fontSize: 12,
                                  color: AppColors.primary1.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ========== Action Buttons ==========
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء رأس النافذة
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          const Text(
            'بحث حسب الموقع',
            style: TextStyle(
              fontFamily: 'Dubai',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: AppColors.textPlaceholder,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء زر المحافظة (مستطيل بحواف دائرية)
  Widget _buildGovernorateChip(String governorate) {
    final isSelected = _selectedLocations.contains(governorate);

    return GestureDetector(
      onTap: () => _toggleLocation(governorate),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary1 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.stroke,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary1.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              governorate,
              style: TextStyle(
                fontFamily: 'Dubai',
                fontSize: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _removeLocation(governorate),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// بناء أزرار الإجراءات
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // زر عرض النتائج
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary1,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'عرض النتائج',
                style: TextStyle(
                  fontFamily: 'Dubai',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // زر إعادة تعيين الفلتر
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _resetFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary1,
                side: const BorderSide(color: AppColors.primary1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'إعادة تعيين الفلتر',
                style: TextStyle(
                  fontFamily: 'Dubai',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}