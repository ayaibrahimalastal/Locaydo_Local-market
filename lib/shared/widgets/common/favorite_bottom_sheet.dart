import 'package:flutter/material.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'dart:io';

class FavoriteBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required String productTitle,
    required bool isAdding,
    required Future<bool> Function() onToggle,
    required VoidCallback onComplete,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: _FavoriteBottomSheetContent(
          productTitle: productTitle,
          isAdding: isAdding,
          onToggle: onToggle,
          onComplete: onComplete,
        ),
      ),
    );
  }
}

class _FavoriteBottomSheetContent extends StatefulWidget {
  final String productTitle;
  final bool isAdding;
  final Future<bool> Function() onToggle;
  final VoidCallback onComplete;

  const _FavoriteBottomSheetContent({
    required this.productTitle,
    required this.isAdding,
    required this.onToggle,
    required this.onComplete,
  });

  @override
  State<_FavoriteBottomSheetContent> createState() => _FavoriteBottomSheetContentState();
}

class _FavoriteBottomSheetContentState extends State<_FavoriteBottomSheetContent> {
  bool _isLoading = true;
  bool _isSuccess = false;
  bool _isError = false;
  String _message = '';
  bool _isClosing = false;
  bool _isRetrying = false;
  bool _isNoInternet = false;
  bool _isRetryLoading = false; // ✅ متغير لحالة تحميل زر إعادة المحاولة

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInternetAndPerform();
    });
  }

  // ✅ التحقق من الاتصال بالإنترنت قبل التنفيذ
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _checkInternetAndPerform() async {
    final hasInternet = await _hasInternetConnection();
    
    if (!hasInternet) {
      if (mounted && !_isClosing) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _isNoInternet = true;
          _message = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك ثم إعادة المحاولة';
        });
      }
      return;
    }
    
    _performAction();
  }

  Future<void> _performAction() async {
    if (_isClosing || _isRetrying) return;
    
    _isRetrying = true;
    
    setState(() {
      _isLoading = true;
      _isSuccess = false;
      _isError = false;
      _isNoInternet = false;
      _message = '';
    });
    
    try {
      // ✅ التحقق مرة أخرى قبل التنفيذ
      final hasInternet = await _hasInternetConnection();
      if (!hasInternet) {
        throw SocketException('No internet connection');
      }
      
      final success = await widget.onToggle();
      
      if (mounted && !_isClosing) {
        setState(() {
          _isLoading = false;
          _isSuccess = success;
          _isError = !success;
          if (widget.isAdding) {
            _message = success 
                ? 'تمت إضافة "${widget.productTitle}" إلى المفضلة بنجاح'
                : 'فشل إضافة المنتج إلى المفضلة';
          } else {
            _message = success 
                ? 'تمت إزالة "${widget.productTitle}" من المفضلة بنجاح'
                : 'فشل إزالة المنتج من المفضلة';
          }
        });
      }
      
      if (success && mounted && !_isClosing) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted && !_isClosing) {
          _closeBottomSheet();
          widget.onComplete();
        }
      }
      
      _isRetrying = false;
    } on SocketException catch (_) {
      if (mounted && !_isClosing) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _isError = true;
          _isNoInternet = true;
          _message = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك ثم إعادة المحاولة';
        });
      }
      _isRetrying = false;
    } catch (e) {
      if (mounted && !_isClosing) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _isError = true;
          _isNoInternet = false;
          _message = 'حدث خطأ: ${e.toString()}';
        });
      }
      _isRetrying = false;
    }
  }

  // ✅ وظيفة إعادة المحاولة مع تحميل
  Future<void> _handleRetry() async {
    if (_isRetryLoading) return; // ✅ منع الضغط المتكرر
    
    setState(() {
      _isRetryLoading = true;
      _isError = false;
      _message = '';
    });
    
    // ✅ التحقق من الاتصال أولاً
    final hasInternet = await _hasInternetConnection();
    
    if (!hasInternet) {
      // ✅ إذا مازال لا يوجد نت
      if (mounted) {
        setState(() {
          _isRetryLoading = false;
          _isError = true;
          _isNoInternet = true;
          _message = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك ثم إعادة المحاولة';
        });
      }
      return;
    }
    
    // ✅ إذا رجع النت، نحاول إعادة التنفيذ
    setState(() {
      _isError = false;
      _isNoInternet = false;
      _isLoading = true;
      _isSuccess = false;
      _message = '';
    });
    
    try {
      final success = await widget.onToggle();
      
      if (mounted && !_isClosing) {
        setState(() {
          _isLoading = false;
          _isSuccess = success;
          _isError = !success;
          _isRetryLoading = false;
          if (widget.isAdding) {
            _message = success 
                ? 'تمت إضافة "${widget.productTitle}" إلى المفضلة بنجاح'
                : 'فشل إضافة المنتج إلى المفضلة';
          } else {
            _message = success 
                ? 'تمت إزالة "${widget.productTitle}" من المفضلة بنجاح'
                : 'فشل إزالة المنتج من المفضلة';
          }
        });
      }
      
      if (success && mounted && !_isClosing) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted && !_isClosing) {
          _closeBottomSheet();
          widget.onComplete();
        }
      }
    } catch (e) {
      if (mounted && !_isClosing) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _isError = true;
          _isRetryLoading = false;
          _message = 'حدث خطأ: ${e.toString()}';
        });
      }
    }
  }

  void _closeBottomSheet() {
    if (_isClosing) return;
    _isClosing = true;
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _closeBottomSheet,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      widget.isAdding ? 'إضافة للمفضلة' : 'إزالة من المفضلة',
                      style: const TextStyle(
                        fontFamily: 'Dubai',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 32),
                  ],
                ),
              ),
              
              const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading)
                            Text(
                              widget.isAdding 
                                  ? 'جاري إضافة المنتج إلى المفضلة...'
                                  : 'جاري إزالة المنتج من المفضلة...',
                              style: const TextStyle(
                                fontFamily: 'Dubai',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          
                          if (_isSuccess || _isError)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isSuccess ? 'تم بنجاح!' : (_isNoInternet ? 'لا يوجد اتصال!' : 'فشل!'),
                                  style: TextStyle(
                                    fontFamily: 'Dubai',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _isSuccess 
                                        ? Colors.green 
                                        : (_isNoInternet ? Colors.orange : Colors.red),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _message,
                                  style: TextStyle(
                                    fontFamily: 'Dubai',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _isSuccess 
                                        ? Colors.green.shade700 
                                        : (_isNoInternet ? Colors.orange.shade700 : Colors.red.shade700),
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    _buildStatusIcon(),
                  ],
                ),
              ),
              
              // ✅ زر إعادة المحاولة مع مؤشر تحميل
              if (_isError)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isRetryLoading ? null : _handleRetry, // ✅ تعطيل الزر أثناء التحميل
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary1,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isRetryLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('إعادة المحاولة'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: _closeBottomSheet,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('إغلاق'),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_isLoading) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary1.withOpacity(0.1),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: AppColors.primary1,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }
    
    if (_isSuccess) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
          child: Icon(
            Icons.check_rounded,
            color: Colors.green,
            size: 32,
          ),
        ),
      );
    }
    
    if (_isError) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _isNoInternet 
              ? Colors.orange.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Icon(
            _isNoInternet ? Icons.wifi_off_rounded : Icons.close_rounded,
            color: _isNoInternet ? Colors.orange : Colors.red,
            size: 32,
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}