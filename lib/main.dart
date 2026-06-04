import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/services/app_link_handler.dart';
import 'package:locaydo_app/core/services/hive_cache_service.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/di/injection_container.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

import 'features/auth/presentation/screens/splash_view.dart';
import 'features/auth/presentation/screens/welcome_view.dart';
import 'features/auth/presentation/screens/login_view.dart';
import 'features/auth/presentation/screens/signup_view.dart';
import 'features/auth/presentation/screens/forgot_password_view.dart';
import 'features/auth/presentation/screens/activation_screens.dart';
import 'features/categories/presentation/screens/categories_screen.dart';
import 'features/categories/presentation/screens/category_details_screen.dart';
import 'features/products/presentation/screens/product_form_screen.dart';
import 'features/products/presentation/screens/product_details_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/profile/presentation/screens/basic_info_screen.dart';
import 'features/profile/presentation/screens/seller_profile_setup_screen.dart';
import 'features/profile/presentation/screens/seller_profile_view_screen.dart';
import 'features/profile/presentation/screens/seller_profile_edit_screen.dart';
import 'features/profile/presentation/screens/seller_products_screen.dart';
import 'features/profile/presentation/screens/vendor_check_screen.dart';
import 'features/seller/presentation/screens/seller_profile_screen.dart';
import 'features/search/presentation/screens/search_screen.dart';
import 'features/favorites/presentation/screens/favorites_screen.dart';
import 'shared/screens/loading_screen.dart';
import 'shared/widgets/navigation/main_navigation_screen.dart';
import 'core/enums/product_enums.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // ✅ استدعاء واحد فقط لـ ensureInitialized
  final binding = WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ الحفاظ على شاشة الترحيب باستخدام نفس الـ binding
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  
  // ✅ تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ✅ تهيئة Hive Cache Service
  final hiveCacheService = HiveCacheService();
  await hiveCacheService.init();
  
  if (kDebugMode) {
    debugPrint('✅ Hive Cache Service initialized');
    debugPrint('📦 Cached products count: ${hiveCacheService.getCachedProductsCount()}');
  }
  
  // ✅ تعيين navigatorKey
  AppLinkHandler.setNavigatorKey(navigatorKey);
  
  // ✅ تهيئة معالج الروابط
  await AppLinkHandler.init();
  
  if (kDebugMode) {
    debugPrint('🔥 Firebase initialized successfully');
    debugPrint('🚀 Starting application...');
  }

  // ✅ إخفاء شاشة الترحيب بعد الانتهاء من التهيئة
  FlutterNativeSplash.remove();

  runApp(LocaydoApp(
    hiveCacheService: hiveCacheService,
  ));
}

class LocaydoApp extends StatelessWidget {
  final HiveCacheService hiveCacheService;
  
  const LocaydoApp({
    super.key,
    required this.hiveCacheService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildProviders(hiveCacheService: hiveCacheService),
      child: MaterialApp(
        title: 'Locaydo',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: AppTheme.lightTheme,
        home: _buildHomeScreen(),
        onGenerateRoute: _onGenerateRoute,
        onUnknownRoute: (settings) => _unknownRoute(settings),
      ),
    );
  }

  Widget _buildHomeScreen() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      if (kDebugMode) {
        debugPrint('✅ User is signed in! (${user.email}) → Home');
      }
      return const MainNavigationScreen(initialIndex: 0);
    } else {
      if (kDebugMode) {
        debugPrint('👤 User is signed out! → Splash');
      }
      return SplashView(
        splashDuration: const Duration(seconds: 1),
      );
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  Widget _buildLoadingScreen() {
    return const LoadingScreen(message: '');
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    _log('📍 Navigating to: ${settings.name}');
    if (settings.name == '/') {
      return _onGenerateRoute(RouteSettings(name: AppRoutes.splash));
    }

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (context) => SplashView(splashDuration: const Duration(seconds: 1)),
        );

      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (context) => const WelcomeView());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (context) => const LoginView());

      case AppRoutes.signup:
        return MaterialPageRoute(builder: (context) => const SignupView());

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (context) => const ForgotPasswordView());

      case AppRoutes.activationEmailSent:
        final email = _getArg<String>(settings) ?? '';
        return MaterialPageRoute(
          builder: (context) => ActivationScreens.emailSent(
            email: email,
            onResendLink: DefaultActivationConfigs.onResendLink(email),
            onContinue: DefaultActivationConfigs.onContinueToMain(context),
            onBack: DefaultActivationConfigs.onBackToPrevious(context),
          ),
        );

      case AppRoutes.activationSuccess:
        return MaterialPageRoute(
          builder: (context) => ActivationScreens.success(
            onContinue: DefaultActivationConfigs.onContinueToMain(context),
          ),
        );

      case AppRoutes.activationFailed:
        final email = _getArg<String>(settings);
        return MaterialPageRoute(
          builder: (context) => ActivationScreens.failed(
            email: email,
            onResendLink: DefaultActivationConfigs.onResendLink(email ?? ''),
            onBack: DefaultActivationConfigs.onBackToPrevious(context),
          ),
        );

      case AppRoutes.mainNavigation:
        final index = settings.arguments as int? ?? 0;
        return MaterialPageRoute(
          builder: (context) => MainNavigationScreen(initialIndex: index),
        );

      case AppRoutes.addProduct:
        return MaterialPageRoute(builder: (context) => const ProductFormScreen.add());

      case AppRoutes.editProduct:
        final data = _getArg<Map<String, dynamic>>(settings);
        return MaterialPageRoute(
          builder: (context) => ProductFormScreen.edit(initialData: data ?? {}),
        );

      case AppRoutes.productDetails:
        final product = settings.arguments;
        if (product == null) {
          return MaterialPageRoute(builder: (context) => _buildLoadingScreen());
        }
        return MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(product: product),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(builder: (context) => const ProfileScreen());

      case AppRoutes.basicInfo:
        return MaterialPageRoute(builder: (context) => const BasicInfoScreen());

      case AppRoutes.sellerProfile:
        return MaterialPageRoute(builder: (context) => const SellerProfileSetupScreen());

      case AppRoutes.sellerProfileView:
        return MaterialPageRoute(builder: (context) => const SellerProfileViewScreen());

      case AppRoutes.sellerProfileEdit:
        return MaterialPageRoute(builder: (context) => const SellerProfileEditScreen());

      case AppRoutes.sellerAvailableProducts:
        return MaterialPageRoute(builder: (context) => const SellerProductsScreen.available());

      case AppRoutes.sellerSoldProducts:
        return MaterialPageRoute(builder: (context) => const SellerProductsScreen.sold());

      case AppRoutes.vendorCheck:
        return MaterialPageRoute(builder: (context) => const VendorCheckScreen());

      case AppRoutes.categories:
        return MaterialPageRoute(builder: (context) => const CategoriesScreen());

      case AppRoutes.favorites:
        return MaterialPageRoute(builder: (context) => const FavoritesScreen());

      case AppRoutes.categoryDetails:
        final args = settings.arguments;
        
        String categoryId = '';
        String categoryName = '';
        
        if (args is Map<String, dynamic>) {
          categoryId = args['categoryId'] as String? ?? '';
          categoryName = args['categoryName'] as String? ?? '';
        } else if (args is String) {
          categoryId = args;
          categoryName = args;
        }
        
        if (categoryId.isEmpty) {
          _log('❌ Invalid category details route');
          return MaterialPageRoute(builder: (context) => _buildLoadingScreen());
        }
        
        return MaterialPageRoute(
          builder: (context) => CategoryDetailsScreen(
            categoryId: categoryId,
            categoryName: categoryName,
          ),
        );

      case AppRoutes.sellerView:
        final sellerId = settings.arguments as String? ?? '';
        if (sellerId.isEmpty) {
          return MaterialPageRoute(builder: (context) => _buildLoadingScreen());
        }
        return MaterialPageRoute(
          builder: (context) => SellerProfileView(sellerId: sellerId),
        );
 
      case AppRoutes.searchUsers:
        return MaterialPageRoute(builder: (context) => const SearchScreen.users());

      case AppRoutes.searchProducts:
        return MaterialPageRoute(builder: (context) => const SearchScreen.products());

      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(initialIndex: 0),
        );

      case AppRoutes.main:
      case AppRoutes.notFound:
        return MaterialPageRoute(builder: (context) => _buildLoadingScreen());

      default :
        return _unknownRoute(settings);
    }
  }

  T? _getArg<T>(RouteSettings settings) {
    final args = settings.arguments;
    return args is T ? args : null;
  }

  MaterialPageRoute _unknownRoute(RouteSettings settings) {
    _log('❌ Unknown route: ${settings.name}');
    return MaterialPageRoute(
      builder: (context) => _buildLoadingScreen(),
      settings: settings,
    );
  }
}