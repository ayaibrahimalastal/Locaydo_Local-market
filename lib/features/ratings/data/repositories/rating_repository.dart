import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/ratings/data/models/rating_model.dart';

class RatingRepository {
  final Logger _logger;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RatingRepository({
    required Logger logger,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _logger = logger,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  Future<bool> submitRating({
    required String sellerId,
    required double rating,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _logger.log('⚠️ No user logged in');
        return false;
      }

      _logger.log('⭐ Submitting rating: $rating stars for seller $sellerId');

      // 1. التحقق من وجود تقييم سابق
      final existingRating = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('sentRatings')
          .doc(sellerId)
          .get();

      if (existingRating.exists) {
        _logger.log('⚠️ Rating already exists for this seller');
        return false;
      }

      // 2. جلب بيانات البائع
      final sellerDoc = await _firestore.collection('sellers').doc(sellerId).get();
      if (!sellerDoc.exists) {
        _logger.log('❌ Seller not found');
        return false;
      }

      final sellerUserId = sellerDoc.data()?['userId'];
      if (sellerUserId == currentUser.uid) {
        _logger.log('⚠️ User cannot rate themselves');
        return false;
      }

      // 3. حفظ sentRating
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('sentRatings')
          .doc(sellerId)
          .set({
        'rating': rating,
        'sellerId': sellerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _logger.log('✅ Sent rating saved');

      // 4. حفظ receivedRating
      await _firestore
          .collection('sellers')
          .doc(sellerId)
          .collection('receivedRatings')
          .doc(currentUser.uid)
          .set({
        'rating': rating,
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? currentUser.email?.split('@').first ?? 'مستخدم',
        'userAvatar': currentUser.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _logger.log('✅ Received rating saved');

      // 5. تحديث متوسط التقييمات (مع تجاهل الخطأ)
      try {
        final allRatingsSnapshot = await _firestore
            .collection('sellers')
            .doc(sellerId)
            .collection('receivedRatings')
            .get();

        final totalRatings = allRatingsSnapshot.docs.length;
        final sumRatings = allRatingsSnapshot.docs.fold<double>(
          0,
          (sum, doc) => sum + (doc.data()['rating'] as num).toDouble(),
        );
        final averageRating = sumRatings / totalRatings;

        await _firestore.collection('sellers').doc(sellerId).update({
          'rating': averageRating,
          'totalRatings': totalRatings,
        });
        _logger.log('✅ Seller rating updated');
      } catch (updateError) {
        _logger.log('⚠️ Could not update seller ratings: $updateError');
      }

      _logger.log('✅ Rating submission completed successfully');
      return true;

    } catch (e) {
      _logger.error('❌ Failed to submit rating: $e');
      return false;
    }
  }

  Future<double?> getUserRatingForSeller(String sellerId) async {
    try {
      if (_currentUserId.isEmpty) return null;

      _logger.log('🔍 Checking user rating for seller: $sellerId');
      
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('sentRatings')
          .doc(sellerId)
          .get();

      if (doc.exists) {
        final rating = (doc.data()?['rating'] as num?)?.toDouble();
        _logger.log('⭐ Existing rating: $rating');
        return rating;
      }
      _logger.log('⭐ No existing rating found');
      return null;
    } catch (e) {
      _logger.error('❌ Failed to get user rating: $e');
      return null;
    }
  }

  Future<List<RatingModel>> getSellerRatings(String sellerId) async {
    try {
      _logger.log('📦 Getting ratings for seller: $sellerId');
      
      final snapshot = await _firestore
          .collection('sellers')
          .doc(sellerId)
          .collection('receivedRatings')
          .orderBy('createdAt', descending: true)
          .get();

      _logger.log('✅ Found ${snapshot.docs.length} ratings');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RatingModel(
          id: doc.id,
          userId: data['userId'] ?? '',
          userName: data['userName'] ?? 'مستخدم',
          userAvatar: data['userAvatar'],
          sellerId: sellerId,
          rating: (data['rating'] ?? 0).toDouble(),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      _logger.error('❌ Failed to get seller ratings: $e');
      return [];
    }
  }

  /// ✅ حذف جميع تقييمات المستخدم
  Future<void> deleteAllUserRatings(String userId) async {
    try {
      _logger.log('🗑️ Deleting all ratings for user: $userId');
      
      // حذف التقييمات المرسلة
      final sentRatings = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sentRatings')
          .get();
      
      for (var doc in sentRatings.docs) {
        await doc.reference.delete();
      }
      _logger.log('✅ Deleted ${sentRatings.docs.length} sent ratings');
      
      // حذف التقييمات المستلمة (إذا كان بائعاً)
      final sellerDoc = await _firestore
          .collection('sellers')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (sellerDoc.docs.isNotEmpty) {
        final sellerId = sellerDoc.docs.first.id;
        final receivedRatings = await _firestore
            .collection('sellers')
            .doc(sellerId)
            .collection('receivedRatings')
            .get();
        
        for (var doc in receivedRatings.docs) {
          await doc.reference.delete();
        }
        _logger.log('✅ Deleted ${receivedRatings.docs.length} received ratings');
      }
      
      _logger.log('✅ All user ratings deleted successfully');
    } catch (e) {
      _logger.error('❌ Failed to delete user ratings: $e');
    }
  }
}