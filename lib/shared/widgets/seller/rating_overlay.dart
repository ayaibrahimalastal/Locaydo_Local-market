// lib/shared/widgets/seller/rating_overlay.dart

import 'package:flutter/material.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/theme/app_text_styles.dart';
import 'package:locaydo_app/features/ratings/data/repositories/rating_repository.dart';
import 'package:locaydo_app/core/utils/logger.dart';

class RatingOverlay {
  static Future<void> show({
    required BuildContext context,
    required String sellerId,
    required String sellerName,
    required VoidCallback onRatingSubmitted,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,  // مهم لفتح لوحة المفاتيح
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RatingOverlayContent(
        sellerId: sellerId,
        sellerName: sellerName,
        onRatingSubmitted: onRatingSubmitted,
      ),
    );
  }
}

class _RatingOverlayContent extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final VoidCallback onRatingSubmitted;

  const _RatingOverlayContent({
    required this.sellerId,
    required this.sellerName,
    required this.onRatingSubmitted,
  });

  @override
  State<_RatingOverlayContent> createState() => _RatingOverlayContentState();
}

class _RatingOverlayContentState extends State<_RatingOverlayContent> {
  double _selectedRating = 0;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _errorMessage;
  final _logger = DebugLogger();

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      setState(() {
        _errorMessage = 'الرجاء اختيار عدد النجوم';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = RatingRepository(logger: _logger);
      final success = await repository.submitRating(
        sellerId: widget.sellerId,
        rating: _selectedRating,
      );

      setState(() {
        _isSubmitting = false;
        _isSubmitted = success;
        if (!success) {
          _errorMessage = 'فشل إرسال التقييم، يرجى المحاولة مرة أخرى';
        }
      });

      if (success && mounted) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pop(context);
          widget.onRatingSubmitted();
        }
      }
    } catch (e) {
      _logger.error('Error in submitRating: $e');
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'حدث خطأ: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.stroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'تقييم البائع',
              style: AppTextStyles.displaySmall(context)?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              widget.sellerName,
              style: AppTextStyles.bodyMedium(context)?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            if (!_isSubmitted) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1.0;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = starValue;
                        _errorMessage = null;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        starValue <= _selectedRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 48,
                        color: starValue <= _selectedRating
                            ? AppColors.warning
                            : AppColors.textPlaceholder,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedRating > 0
                    ? 'قيمت البائع بـ $_selectedRating نجوم'
                    : 'اختر عدد النجوم',
                style: AppTextStyles.bodySmall(context)?.copyWith(
                  color: AppColors.textPlaceholder,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedRating > 0 && !_isSubmitting
                      ? _submitRating
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'إرسال التقييم',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ] else ...[
              Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تم إرسال تقييمك بنجاح!',
                    style: AppTextStyles.bodyLarge(context)?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'شكراً لتقييمك للبائع',
                    style: AppTextStyles.bodySmall(context)?.copyWith(
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}