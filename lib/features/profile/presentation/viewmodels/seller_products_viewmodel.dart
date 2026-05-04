import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/network/firebase_collections.dart';
import 'package:locaydo_app/core/theme/app_colors.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/products/data/models/seller_product_model.dart';
import 'package:locaydo_app/features/products/data/repositories/product_repository_impl.dart';
import 'package:locaydo_app/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';

class SellerProductsViewModel extends ChangeNotifier {
  final Logger _logger;
  final ProductRepositoryImpl _productRepository;
  HomeViewModel? _homeViewModel;

  List<SellerProduct> _availableProducts = [];
  List<SellerProduct> _soldProducts = [];
  bool isLoading = false;
  String? errorMessage;

  SellerProductsViewModel({
    required Logger logger,
    ProductRepositoryImpl? productRepository,
    HomeViewModel? homeViewModel,
  })  : _logger = logger,
        _productRepository = productRepository ?? ProductRepositoryImpl(logger: logger),
        _homeViewModel = homeViewModel {
    loadProducts();
    _homeViewModel?.addListener(_onHomeViewModelChanged);
  }

  List<SellerProduct> get availableProducts => _availableProducts;
  List<SellerProduct> get soldProducts => _soldProducts;

  void _onHomeViewModelChanged() {
    _logger.log('🔄 HomeViewModel changed, refreshing seller products...');
    loadProducts();
  }

  Future<void> loadProducts() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.log('⚠️ No user logged in');
        isLoading = false;
        notifyListeners();
        return;
      }

      _logger.log('📦 Loading seller products for user: ${user.uid}');

      final userDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(user.uid)
          .get();

      String sellerId = user.uid;
      
      if (userDoc.exists) {
        final data = userDoc.data();
        final storedSellerId = data?['sellerId'] as String?;
        if (storedSellerId != null && storedSellerId.isNotEmpty) {
          sellerId = storedSellerId;
          _logger.log('📝 Found sellerId: $sellerId');
        }
      }

      final allProducts = await _productRepository.getSellerProducts(sellerId);
      
      _availableProducts = allProducts
          .where((p) => p.status == ProductStatus.available)
          .toList();
      
      _soldProducts = allProducts
          .where((p) => p.status == ProductStatus.sold)
          .toList();
      
      _logger.log('✅ Loaded ${_availableProducts.length} available, ${_soldProducts.length} sold products');
    } catch (e) {
      errorMessage = 'فشل تحميل المنتجات';
      _logger.error('❌ Failed to load products', e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsSold(SellerProduct product) async {
    _logger.log('💰💰💰 STARTING markAsSold for: ${product.title}');
    _logger.log('💰💰💰 Product ID: ${product.id}');
    _logger.log('💰💰💰 Current status: ${product.status}');
    
    // حفظ نسخة للتراجع
    final originalProduct = product;
    
    try {
      // 1. تحديث الواجهة فوراً
      _logger.log('📱 Updating UI - removing from available...');
      _availableProducts.removeWhere((p) => p.id == product.id);
      final updatedProduct = product.copyWith(status: ProductStatus.sold);
      _soldProducts.insert(0, updatedProduct);
      notifyListeners();
      _logger.log('📱 UI updated: available=${_availableProducts.length}, sold=${_soldProducts.length}');
      
      // 2. إزالة المنتج من HomeViewModel
      _logger.log('🏠 Removing from HomeViewModel...');
      _homeViewModel?.removeProduct(product.id);
      _homeViewModel?.refreshFavoritesCache();
      
      // 3. تحديث قاعدة البيانات
      _logger.log('💾 Updating Firebase...');
      await _productRepository.markAsSold(product.id);
      _logger.log('💾 Firebase updated successfully!');
      
      // 4. إعادة تحميل المنتجات للتأكد
      _logger.log('🔄 Refreshing products...');
      await _homeViewModel?.refreshProducts();
      _homeViewModel?.refreshFavoritesCache();
      await loadProducts();
      
      _logger.log('✅✅✅ markAsSold completed successfully!');
      
    } catch (e) {
      _logger.error('❌❌❌ markAsSold FAILED: $e', e);
      
      // التراجع عن التغييرات
      _soldProducts.removeWhere((p) => p.id == originalProduct.id);
      _availableProducts.insert(0, originalProduct);
      
      _homeViewModel?.refreshFavoritesCache();
      notifyListeners();
      
      errorMessage = 'فشل تحديث حالة المنتج: ${e.toString()}';
    }
  }

  Future<void> deleteProduct(SellerProduct product) async {
    try {
      isLoading = true;
      notifyListeners();
      
      _logger.log('🗑️ Deleting product: ${product.id} - ${product.title}');
      
      _homeViewModel?.removeProduct(product.id);
      _homeViewModel?.refreshFavoritesCache();
      
      _availableProducts.removeWhere((p) => p.id == product.id);
      _soldProducts.removeWhere((p) => p.id == product.id);
      
      notifyListeners();
      
      await _productRepository.deleteProduct(product.id);
      _logger.log('✅ Product deleted successfully');
      await _homeViewModel?.refreshProducts();
      
    } catch (e) {
      errorMessage = 'فشل حذف المنتج';
      _logger.error('❌ Failed to delete product', e);
      await loadProducts();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ✅ ✅ ✅ الدالة المعدلة -最重要的是 ✅ ✅ ✅
  void editProduct(BuildContext context, SellerProduct product) {
    _logger.log('✏️ Editing product: ${product.title} (ID: ${product.id})');
    
    // ✅ تجميع جميع الصور في قائمة واحدة
    final List<String> allImages = [];
    if (product.imageUrl.isNotEmpty) {
      allImages.add(product.imageUrl);
    }
    allImages.addAll(product.additionalImages);
    
    _logger.log('📸 Product has ${allImages.length} images');
    _logger.log('📸 Main image: ${product.imageUrl}');
    _logger.log('📸 Additional images: ${product.additionalImages}');
    
    final productData = {
      'id': product.id,
      'name': product.title,
      'description': product.description,
      'price': product.price,
      'condition': product.condition,
      'category': product.category,
      'location': _getLocationFromString(product.location),
      'payments': product.paymentMethods,
      'imagePaths': allImages,  // ✅ تمرير جميع الصور
    };
    
    Navigator.pushNamed(
      context,
      AppRoutes.editProduct,
      arguments: productData,
    ).then((result) {
      if (result == true) {
        _logger.log('🔄 Product edited, reloading products...');
        loadProducts();
        _homeViewModel?.refreshProducts();
      }
    });
  }

  Location _getLocationFromString(String locationString) {
    switch (locationString) {
      case 'رفح': return Location.rafah;
      case 'غزة': return Location.gazaCity;
      case 'شمال غزة': return Location.northGaza;
      case 'الوسطى': return Location.middleArea;
      case 'خانيونس': return Location.khanYounis;
      default: return Location.northGaza;
    }
  }

  void showProductOptions(BuildContext context, SellerProduct product) {
    final isSold = product.status == ProductStatus.sold;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSold)
              ListTile(
                leading: const Icon(Icons.sell, color: AppColors.primary1),
                title: const Text('تحديد كمباع'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmMarkAsSold(context, product);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary1),
              title: const Text('تعديل المنتج'),
              onTap: () {
                Navigator.pop(context);
                editProduct(context, product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.errorFields),
              title: const Text('حذف المنتج', style: TextStyle(color: AppColors.errorFields)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, product);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmMarkAsSold(BuildContext context, SellerProduct product) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'تحديد كمباع',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'هل أنت متأكد من أن المنتج "${product.title}" قد تم بيعه؟',
            textAlign: TextAlign.right,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppColors.stroke),
                      ),
                    ),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      markAsSold(product);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary1,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('تأكيد'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SellerProduct product) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'حذف المنتج',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'هل أنت متأكد من حذف المنتج "${product.title}"؟',
            textAlign: TextAlign.right,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppColors.stroke),
                      ),
                    ),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      deleteProduct(product);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorFields,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('حذف'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }
  
  @override
  void dispose() {
    _homeViewModel?.removeListener(_onHomeViewModelChanged);
    super.dispose();
  }
}