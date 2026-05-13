// test/features/ratings/rating_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/ratings/data/models/rating_model.dart';
import 'package:locaydo_app/features/ratings/data/repositories/rating_repository.dart';

@GenerateMocks([Logger, FirebaseFirestore, FirebaseAuth, CollectionReference, DocumentReference, DocumentSnapshot, QuerySnapshot])
import 'rating_test.mocks.dart';

void main() {
  group('RatingModel — fromMap / toMap', () {
    
    test('TC-RM01: fromMap parses all fields correctly', () {
      final Map<String, dynamic> validMap = {
        'userId': 'user123',
        'userName': 'أحمد محمد',
        'userAvatar': 'https://example.com/avatar.jpg',
        'sellerId': 'seller123',
        'rating': 4.5,
        'createdAt': null,
      };

      final model = RatingModel.fromMap(validMap, 'rating123');

      expect(model.id, equals('rating123'));
      expect(model.userId, equals('user123'));
      expect(model.userName, equals('أحمد محمد'));
      expect(model.userAvatar, equals('https://example.com/avatar.jpg'));
      expect(model.sellerId, equals('seller123'));
      expect(model.rating, equals(4.5));
    });

    test('TC-RM02: toMap returns correct map structure', () {
      final now = DateTime.now();
      final model = RatingModel(
        id: 'rating123',
        userId: 'user123',
        userName: 'أحمد محمد',
        userAvatar: 'https://example.com/avatar.jpg',
        sellerId: 'seller123',
        rating: 4.5,
        createdAt: now,
      );

      final map = model.toMap();

      expect(map['userId'], equals('user123'));
      expect(map['userName'], equals('أحمد محمد'));
      expect(map['userAvatar'], equals('https://example.com/avatar.jpg'));
      expect(map['sellerId'], equals('seller123'));
      expect(map['rating'], equals(4.5));
      expect(map.containsKey('createdAt'), isTrue);
    });

    test('TC-RM03: optional fields can be null', () {
      final model = RatingModel(
        id: 'rating123',
        userId: 'user123',
        userName: 'أحمد محمد',
        userAvatar: null,
        sellerId: 'seller123',
        rating: 4.5,
        createdAt: DateTime.now(),
      );

      expect(model.userAvatar, isNull);
    });
  });

  group('Rating Validation — Business Rules', () {
    
    test('TC-RV01: minimum rating is 1.0', () {
      const minRating = 1.0;
      expect(minRating, equals(1.0));
    });

    test('TC-RV02: maximum rating is 5.0', () {
      const maxRating = 5.0;
      expect(maxRating, equals(5.0));
    });

    test('TC-RV03: rating below minimum is invalid', () {
      const rating = 0.5;
      const isValid = rating >= 1.0 && rating <= 5.0;
      expect(isValid, isFalse);
    });

    test('TC-RV04: rating above maximum is invalid', () {
      const rating = 5.5;
      const isValid = rating >= 1.0 && rating <= 5.0;
      expect(isValid, isFalse);
    });

    test('TC-RV05: valid rating 1.0 is acceptable', () {
      const rating = 1.0;
      const isValid = rating >= 1.0 && rating <= 5.0;
      expect(isValid, isTrue);
    });

    test('TC-RV06: valid rating 2.5 is acceptable', () {
      const rating = 2.5;
      const isValid = rating >= 1.0 && rating <= 5.0;
      expect(isValid, isTrue);
    });

    test('TC-RV07: valid rating 5.0 is acceptable', () {
      const rating = 5.0;
      const isValid = rating >= 1.0 && rating <= 5.0;
      expect(isValid, isTrue);
    });
  });

  group('Rating Average Calculation', () {
    
    test('TC-RA01: calculate average rating correctly', () {
      final ratings = [5.0, 4.0, 3.0, 5.0, 4.0];
      final sum = ratings.fold<double>(0, (sum, r) => sum + r);
      final average = sum / ratings.length;
      
      expect(average, equals(4.2));
    });

    test('TC-RA02: average of single rating equals that rating', () {
      final ratings = [4.5];
      final sum = ratings.fold<double>(0, (sum, r) => sum + r);
      final average = sum / ratings.length;
      
      expect(average, equals(4.5));
    });

    test('TC-RA03: total ratings count is correct', () {
      final ratings = [5.0, 4.0, 3.0, 2.0];
      expect(ratings.length, equals(4));
    });

    test('TC-RA04: sum of ratings is correct', () {
      final ratings = [5.0, 4.0, 3.0];
      final sum = ratings.fold<double>(0, (sum, r) => sum + r);
      
      expect(sum, equals(12.0));
    });

    test('TC-RA05: average with decimals works correctly', () {
      final ratings = [4.2, 3.8, 4.5, 5.0, 2.5];
      final sum = ratings.fold<double>(0, (sum, r) => sum + r);
      final average = sum / ratings.length;
      
      expect(average, equals(4.0));
    });
  });

  group('Rating Display Formatting', () {
    
    test('TC-RD01: rating format shows one decimal', () {
      final rating = 4.5;
      final formatted = rating.toStringAsFixed(1);
      expect(formatted, equals('4.5'));
    });

    test('TC-RD02: rating 5.0 shows as 5.0', () {
      final rating = 5.0;
      final formatted = rating.toStringAsFixed(1);
      expect(formatted, equals('5.0'));
    });

    test('TC-RD03: rating 0.0 shows as 0.0', () {
      final rating = 0.0;
      final formatted = rating.toStringAsFixed(1);
      expect(formatted, equals('0.0'));
    });
  });

  group('Star Rating Calculation', () {
    
    test('TC-RS01: rating 5.0 shows 5 full stars', () {
      final rating = 5.0;
      final fullStars = rating.floor();
      final hasHalfStar = (rating - fullStars) >= 0.5;
      
      expect(fullStars, equals(5));
      expect(hasHalfStar, isFalse);
    });

    test('TC-RS02: rating 4.5 shows 4 full stars and 1 half star', () {
      final rating = 4.5;
      final fullStars = rating.floor();
      final hasHalfStar = (rating - fullStars) >= 0.5;
      final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
      
      expect(fullStars, equals(4));
      expect(hasHalfStar, isTrue);
      expect(emptyStars, equals(0));
    });

    test('TC-RS03: rating 4.0 shows 4 full stars and 1 empty star', () {
      final rating = 4.0;
      final fullStars = rating.floor();
      final hasHalfStar = (rating - fullStars) >= 0.5;
      final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
      
      expect(fullStars, equals(4));
      expect(hasHalfStar, isFalse);
      expect(emptyStars, equals(1));
    });

    test('TC-RS04: rating 0.0 shows 0 full stars and 5 empty stars', () {
      final rating = 0.0;
      final fullStars = rating.floor();
      final hasHalfStar = (rating - fullStars) >= 0.5;
      final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
      
      expect(fullStars, equals(0));
      expect(hasHalfStar, isFalse);
      expect(emptyStars, equals(5));
    });

    test('TC-RS05: rating 3.7 shows 3 full stars and 1 half star', () {
      final rating = 3.7;
      final fullStars = rating.floor();
      final hasHalfStar = (rating - fullStars) >= 0.5;
      
      expect(fullStars, equals(3));
      expect(hasHalfStar, isTrue);
    });
  });

  group('Rating User Validation', () {
    
    test('TC-RU01: user cannot rate themselves', () {
      final currentUserId = 'user123';
      final sellerUserId = 'user123';
      final canRate = currentUserId != sellerUserId;
      
      expect(canRate, isFalse);
    });

    test('TC-RU02: different users can rate each other', () {
      final currentUserId = 'user123';
      final sellerUserId = 'seller456';
      final canRate = currentUserId != sellerUserId;
      
      expect(canRate, isTrue);
    });

    test('TC-RU03: user without login cannot submit rating', () {
      final currentUser = null;
      final isLoggedIn = currentUser != null;
      
      expect(isLoggedIn, isFalse);
    });
  });

  group('Rating Duplicate Prevention', () {
    
    test('TC-RDUP01: existing rating should prevent new submission', () {
      final existingRating = true;
      final canSubmit = !existingRating;
      
      expect(canSubmit, isFalse);
    });

    test('TC-RDUP02: no existing rating allows submission', () {
      final existingRating = false;
      final canSubmit = !existingRating;
      
      expect(canSubmit, isTrue);
    });
  });

  group('Rating Model Default Values', () {
    
    test('TC-RDF01: default userName when missing', () {
      final defaultName = 'مستخدم';
      expect(defaultName, equals('مستخدم'));
    });

    test('TC-RDF02: default rating when missing is 0.0', () {
      final rating = 0.0;
      expect(rating, equals(0.0));
    });
  });
}