// lib/features/search/data/repositories/search_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:locaydo_app/core/enums/product_enums.dart';
import 'package:locaydo_app/core/enums/search_enums.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/search/data/models/search_result_model.dart';
import 'package:locaydo_app/features/search/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final Logger _logger;

  SearchRepositoryImpl({required Logger logger}) : _logger = logger;

  @override
  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      _logger.log('👥 searchUsers repo: "$query"');

      final sellersSnapshot = await FirebaseFirestore.instance
          .collection('sellers')
          .orderBy('name')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .limit(20)
          .get();

      _logger.log('📊 Found ${sellersSnapshot.docs.length} sellers');

      // ✅ استخدام Map لمنع التكرار
      final uniqueUsers = <String, UserSearchResult>{};
      
      for (var doc in sellersSnapshot.docs) {
        final data = doc.data();
        final userId = doc.id;
        
        if (!uniqueUsers.containsKey(userId)) {
          uniqueUsers[userId] = UserSearchResult(
            id: userId,
            name: data['name'] ?? '',
            imageUrl: data['avatarUrl'],
            rating: (data['rating'] ?? 0).toDouble(),
            type: SearchResultType.seller,
          );
        }
      }

      return uniqueUsers.values.toList();
      
    } catch (e) {
      _logger.error('❌ searchUsers failed', e);
      return [];
    }
  }

  @override
  Future<List<ProductSearchResult>> searchProducts(String query) async {
    try {
      _logger.log('📦 searchProducts repo: "$query"');

      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('title')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .limit(20)
          .get();

      _logger.log('📊 Found ${productsSnapshot.docs.length} products');

      if (productsSnapshot.docs.isEmpty) {
        return [];
      }

      // ✅ جمع الـ sellerIds الفريدة
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

      // ✅ جلب بيانات البائعين دفعة واحدة
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

      // ✅ بناء النتائج مع بيانات البائع
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

      // ✅ إزالة التكرار بناءً على الـ ID
      final uniqueProducts = <String, ProductSearchResult>{};
      for (final product in products) {
        if (!uniqueProducts.containsKey(product.id)) {
          uniqueProducts[product.id] = product;
        }
      }

      return uniqueProducts.values.toList();
      
    } catch (e) {
      _logger.error('❌ searchProducts failed', e);
      return [];
    }
  }
}