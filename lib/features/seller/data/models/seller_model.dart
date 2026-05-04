// lib/features/seller/data/models/seller_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? avatarUrl;
  final String? countryCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  SellerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.avatarUrl,
    this.countryCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SellerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellerModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      avatarUrl: data['avatarUrl'],
      countryCode: data['countryCode'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'countryCode': countryCode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}