import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locaydo_app/features/products/presentation/screens/product_details_screen.dart';
import 'package:locaydo_app/shared/widgets/navigation/main_navigation_screen.dart';
import 'package:locaydo_app/shared/screens/loading_screen.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';

class AppLinkHandler {
  static final AppLinks _appLinks = AppLinks();
  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _isProcessing = false;
  static String? _pendingLinkProductId;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    
    if (_pendingLinkProductId != null) {
      debugPrint('📦 Processing pending link: $_pendingLinkProductId');
      _navigateToProduct(_pendingLinkProductId!);
      _pendingLinkProductId = null;
    }
  }

  static Future<void> init() async {
    debugPrint('🔗 Initializing App Links...');

    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('📱 Initial link: $initialLink');
        _handleLink(initialLink);
      }
    } catch (e) {
      debugPrint('❌ Error getting initial link: $e');
    }

    _appLinks.uriLinkStream.listen((Uri uri) {
      debugPrint('📱 Link received: $uri');
      _handleLink(uri);
    }, onError: (err) {
      debugPrint('❌ Link error: $err');
    });
  }

  static void _handleLink(Uri uri) {
    if (uri.scheme == 'locaydo' && uri.host == 'product') {
      final productId = uri.pathSegments.first;
      debugPrint('📦 Product ID from link: $productId');
      
      if (_isProcessing) {
        debugPrint('⚠️ Already processing, skipping...');
        return;
      }
      
      if (_navigatorKey?.currentContext == null) {
        debugPrint('⏳ App not ready, storing pending link...');
        _pendingLinkProductId = productId;
        return;
      }
      
      _navigateToProduct(productId);
    }
  }

  static void _navigateToProduct(String productId) {
    if (_isProcessing) return;
    _isProcessing = true;
    
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      _isProcessing = false;
      return;
    }
    
    debugPrint('🔄 Navigating to product: $productId');
    
    final navigator = Navigator.of(context);
    
    // ✅ عرض LoadingScreen فوراً
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoadingScreen(message: 'جاري فتح المنتج...'),
      ),
      (route) => false,
    );
    
    // ✅ التحقق من المنتج في الخلفية
    _verifyAndNavigate(productId);
  }

  static Future<void> _verifyAndNavigate(String productId) async {
    // ✅ انتظر قليلاً للتأكد من ظهور LoadingScreen
    await Future.delayed(const Duration(milliseconds: 200));
    
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      _isProcessing = false;
      return;
    }
    
    try {
      debugPrint('🔍 Verifying product existence: $productId');
      
      // ✅ التحقق من وجود المنتج في Firestore
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      
      if (!productDoc.exists) {
        debugPrint('❌ Product not found: $productId');
        
        // ✅ المنتج غير موجود - نعود للرئيسية مع رسالة خطأ
        if (context.mounted) {
          _navigatorKey?.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 0)),
            (route) => false,
          );
          
          // ✅ إظهار رسالة خطأ بعد العودة للرئيسية
          Future.delayed(const Duration(milliseconds: 100), () {
            final currentContext = _navigatorKey?.currentContext;
            if (currentContext != null) {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(
                  content: Text('❌ المنتج غير موجود'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
        }
        _isProcessing = false;
        return;
      }
      
      debugPrint('✅ Product verified, navigating to details');
      
      // ✅ المنتج موجود - ننتقل لصفحة التفاصيل
      if (context.mounted) {
        _navigatorKey?.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(productId: productId),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error verifying product: $e');
      
      // ✅ حدث خطأ - نعود للرئيسية
      if (context.mounted) {
        _navigatorKey?.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 0)),
          (route) => false,
        );
        
        Future.delayed(const Duration(milliseconds: 100), () {
          final currentContext = _navigatorKey?.currentContext;
          if (currentContext != null) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              SnackBar(
                content: Text('❌ حدث خطأ: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    } finally {
      _isProcessing = false;
    }
  }
}