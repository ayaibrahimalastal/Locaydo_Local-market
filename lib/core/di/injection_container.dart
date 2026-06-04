import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/enums/search_enums.dart';
import 'package:locaydo_app/core/services/hive_cache_service.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:locaydo_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:locaydo_app/features/auth/presentation/viewmodels/activation_viewmodel.dart';
import 'package:locaydo_app/features/auth/presentation/viewmodels/forgot_password_viewmodel.dart';
import 'package:locaydo_app/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:locaydo_app/features/auth/presentation/viewmodels/signup_viewmodel.dart';
import 'package:locaydo_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:locaydo_app/features/categories/domain/repositories/category_repository.dart';
import 'package:locaydo_app/features/categories/presentation/viewmodels/categories_viewmodel.dart';
import 'package:locaydo_app/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:locaydo_app/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:locaydo_app/features/favorites/presentation/viewmodels/favorites_viewmodel.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:locaydo_app/features/products/domain/repositories/product_repository.dart';
import 'package:locaydo_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:locaydo_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:locaydo_app/features/profile/presentation/viewmodels/seller_products_viewmodel.dart';
import 'package:locaydo_app/features/search/presentation/viewmodels/search_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> buildProviders({
  required HiveCacheService hiveCacheService,
}) {
  final logger = DebugLogger();

  final firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  // ✅ Auth Repository
  final AuthRepository authRepository = AuthRepositoryImpl(
    logger: logger,
    firebaseAuth: firebaseAuth,
    firestore: firestore,
  );

  // ✅ Category Repository
  final CategoryRepository categoryRepository = CategoryRepositoryImpl(
    logger: logger,
    firestore: firestore,
  );

  // ✅ Product Repository
  final ProductRepositoryImpl productRepository = ProductRepositoryImpl(
    logger: logger,
    firestore: firestore,
  );

  // ✅ Favorites Repository
  final FavoritesRepositoryImpl favoritesRepository = FavoritesRepositoryImpl(
    logger: logger,
    firestore: firestore,
    auth: firebaseAuth,
  );

  // ✅ Profile Repository
  final ProfileRepository profileRepository = ProfileRepositoryImpl(
    logger: logger,
  );

  // ✅ Home ViewModel
  final homeViewModel = HomeViewModel(
    logger: logger,
    hiveCacheService: hiveCacheService,
    categoryRepository: categoryRepository,
    productRepository: productRepository,
    favoritesRepository: favoritesRepository,
  );

  // ✅ Favorites ViewModel
  final favoritesViewModel = FavoritesViewModel(
    logger: logger,
    repository: favoritesRepository,
    homeViewModel: homeViewModel,
  );

  return [
    // ✅ Providers الأساسية
    Provider<Logger>.value(value: logger),
    Provider<FirebaseAuth>.value(value: firebaseAuth),
    Provider<FirebaseFirestore>.value(value: firestore),
    Provider<HiveCacheService>.value(value: hiveCacheService),
    
    // ✅ Providers للمستودعات
    Provider<AuthRepository>.value(value: authRepository),
    Provider<ProductRepository>.value(value: productRepository),
    Provider<ProductRepositoryImpl>.value(value: productRepository),
    Provider<CategoryRepository>.value(value: categoryRepository),
    Provider<FavoritesRepositoryImpl>.value(value: favoritesRepository),
    Provider<FavoritesRepository>.value(value: favoritesRepository),
    Provider<ProfileRepository>.value(value: profileRepository),

    // ✅ Auth ViewModels
    ChangeNotifierProvider<SignupViewModel>(
      create: (context) => SignupViewModel(
        repository: context.read<AuthRepository>(),
      ),
    ),
    ChangeNotifierProvider<LoginViewModel>(
      create: (context) => LoginViewModel(
        repository: context.read<AuthRepository>(),
      ),
    ),
    ChangeNotifierProvider<ForgotPasswordViewModel>(
      create: (context) => ForgotPasswordViewModel(
        repository: context.read<AuthRepository>(),
      ),
    ),
    ChangeNotifierProvider<ActivationViewModel>(
      create: (context) => ActivationViewModel(),
    ),

    // ✅ Home ViewModel
    ChangeNotifierProvider<HomeViewModel>.value(value: homeViewModel),
    
    // ✅ Favorites ViewModel - يجب أن يكون بعد HomeViewModel
    ChangeNotifierProvider<FavoritesViewModel>.value(value: favoritesViewModel),
    
    // ✅ Categories ViewModel
    ChangeNotifierProvider<CategoriesViewModel>(
      create: (context) => CategoriesViewModel(
        logger: context.read<Logger>(),
        categoryRepository: context.read<CategoryRepository>(),
      ),
    ),
    
    // ✅ Seller Products ViewModel
    ChangeNotifierProvider<SellerProductsViewModel>(
      create: (context) => SellerProductsViewModel(
        logger: context.read<Logger>(),
        productRepository: context.read<ProductRepositoryImpl>(),
        homeViewModel: context.read<HomeViewModel>(),
      ),
    ),
    
    // ✅ Search ViewModel
    ChangeNotifierProvider<SearchViewModel>(
      create: (context) => SearchViewModel(
        logger: context.read<Logger>(),
        searchType: SearchType.users,
      ),
    ),
  ];
}