// lib/features/ratings/data/models/rating_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String sellerId;
  final double rating;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.sellerId,
    required this.rating,
    required this.createdAt,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map, String docId) {
    return RatingModel(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'],
      sellerId: map['sellerId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'sellerId': sellerId,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}