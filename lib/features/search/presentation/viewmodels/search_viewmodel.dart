import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/enums/search_enums.dart';
import 'package:locaydo_app/core/routes/app_routes.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/search/data/models/search_result_model.dart';

class SearchViewModel extends ChangeNotifier {
  final Logger _logger;
  final SearchType searchType;

  String searchQuery = '';
  bool _isSearching = false;
  bool _hasResults = false;
  bool _isLoading = false;

  List<UserSearchResult> _userResults = [];
  List<ProductSearchResult> _productResults = [];

  BuildContext? _context;

  SearchViewModel({
    required Logger logger,
    required this.searchType,
  }) : _logger = logger;

  void setContext(BuildContext context) {
    _context = context;
  }

  List<UserSearchResult> get filteredUserResults => _userResults;
  List<ProductSearchResult> get filteredProductResults => _productResults;

  bool get hasResults => _hasResults;
  bool get isSearching => _isSearching;
  bool get isLoading => _isLoading;

  void setSearchQuery(String query) {
    if (searchQuery != query) {
      searchQuery = query;
      _logger.log('🔍 Search: "$query"');
      _performSearch();
    }
  }

  void clearSearch() {
    searchQuery = '';
    _userResults = [];
    _productResults = [];
    _isSearching = false;
    _isLoading = false;
    _hasResults = false;
    notifyListeners();
    _logger.log('🗑️ Search cleared');
  }

  void onUserTap(UserSearchResult user) {
    _logger.log('👤 User tapped: ${user.name} (ID: ${user.id})');
    
    if (_context != null) {
      Navigator.pushNamed(
        _context!,
        AppRoutes.sellerView,
        arguments: user.id,
      );
    }
  }

  void onProductTap(ProductSearchResult product) {
    _logger.log('📦 Product tapped: ${product.title} (ID: ${product.id})');
    
    if (_context != null) {
      Navigator.pushNamed(
        _context!,
        AppRoutes.productDetails,
        arguments: product.id,
      );
    }
  }

  Future<void> toggleFavorite(String productId) async {
    try {
      _logger.log('⭐ Toggling favorite for product: $productId');
      
      final productRef = FirebaseFirestore.instance
          .collection('products')
          .doc(productId);

      final doc = await productRef.get();
      if (doc.exists) {
        final currentFavorite = doc.data()?['isFavorite'] ?? false;
        await productRef.update({
          'isFavorite': !currentFavorite,
        });

        final index = _productResults.indexWhere((p) => p.id == productId);
        if (index != -1) {
          final p = _productResults[index];
          _productResults[index] = ProductSearchResult(
            id: p.id,
            title: p.title,
            price: p.price,
            currency: p.currency,
            imageUrl: p.imageUrl,
            location: p.location,
            area: p.area,
            paymentMethods: p.paymentMethods,
            isFavorite: !currentFavorite,
            sellerName: p.sellerName,
            sellerAvatarUrl: p.sellerAvatarUrl,
            sellerId: p.sellerId,
          );
          notifyListeners();
          _logger.log('✅ Favorite toggled successfully');
        }
      }
    } catch (e) {
      _logger.error('❌ Toggle favorite failed', e);
    }
  }

  void _performSearch() async {
    if (searchQuery.isEmpty) {
      _userResults = [];
      _productResults = [];
      _isSearching = false;
      _isLoading = false;
      _hasResults = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _isLoading = true;
    _hasResults = false;
    notifyListeners();

    if (searchType == SearchType.users) {
      await _searchUsers(searchQuery);
    } else {
      await _searchProducts(searchQuery);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _searchUsers(String query) async {
    try {
      _logger.log('👥 Searching users for: "$query"');

      final sellersSnapshot = await FirebaseFirestore.instance
          .collection('sellers')
          .orderBy('name')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .limit(20)
          .get();

      _logger.log('📊 Found ${sellersSnapshot.docs.length} sellers in Firestore');

      final users = sellersSnapshot.docs.map((doc) {
        final data = doc.data();
        return UserSearchResult(
          id: doc.id,
          name: data['name'] ?? '',
          imageUrl: data['avatarUrl'],
          rating: (data['rating'] ?? 0).toDouble(),
          type: SearchResultType.seller,
        );
      }).toList();

      _userResults = users;
      _hasResults = users.isNotEmpty;
      _logger.log('✅ Found ${users.length} users');
      
    } catch (e) {
      _logger.error('❌ Search users failed', e);
      _userResults = [];
      _hasResults = false;
    }
  }

  Future<void> _searchProducts(String query) async {
    try {
      _logger.log('📦 Searching products for: "$query"');

      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('title')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .limit(20)
          .get();

      _logger.log('📊 Found ${productsSnapshot.docs.length} products in Firestore');

      if (productsSnapshot.docs.isEmpty) {
        _productResults = [];
        _hasResults = false;
        return;
      }

      final uniqueSellerIds = <String>{};
      final productsData = <Map<String, dynamic>>[];
      
      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final sellerId = data['sellerId'];
        if (sellerId != null && sellerId.toString().isNotEmpty) {
          uniqueSellerIds.add(sellerId.toString());
        }
        productsData.add({
          'id': doc.id,
          ...data,
        });
      }

      _logger.log('📊 Found ${uniqueSellerIds.length} unique sellers');

      final sellersMap = <String, Map<String, dynamic>>{};
      
      for (final sellerId in uniqueSellerIds) {
        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(sellerId)
            .get();
        
        if (sellerDoc.exists) {
          sellersMap[sellerId] = sellerDoc.data()!;
        }
      }

      final products = <ProductSearchResult>[];
      
      for (final productData in productsData) {
        final sellerId = productData['sellerId']?.toString();
        final sellerData = sellerId != null ? sellersMap[sellerId] : null;
        
        products.add(ProductSearchResult(
          id: productData['id'],
          title: productData['title'] ?? '',
          price: (productData['price'] ?? 0).toDouble(),
          currency: productData['currency'] ?? '₪',
          imageUrl: productData['imageUrl'],
          location: productData['location'] ?? '',
          area: productData['area'] ?? '',
          paymentMethods: (productData['paymentMethods'] as List? ?? [])
              .map((e) => PaymentMethod.fromString(e))
              .toList(),
          isFavorite: productData['isFavorite'] ?? false,
          sellerName: sellerData?['name'] ?? productData['sellerName'] ?? '',
          sellerAvatarUrl: sellerData?['avatarUrl'],
          sellerId: sellerId,
        ));
      }

      _productResults = products;
      _hasResults = products.isNotEmpty;
      _logger.log('✅ Found ${products.length} products');
      
    } catch (e) {
      _logger.error('❌ Search products failed', e);
      _productResults = [];
      _hasResults = false;
    }
  }
}