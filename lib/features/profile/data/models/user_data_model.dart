// lib/features/profile/data/models/user_data_model.dart

class UserDataModel {
  final String  userName;
  final double  userRating;
  final int     totalRatings;
  final String? profileImage;
  final int     availableProductsCount;
  final int     savedProductsCount;
  final String  email;
  final String? phoneNumber;

  UserDataModel({
    required this.userName,
    required this.userRating,
    required this.totalRatings,
    this.profileImage,
    required this.availableProductsCount,
    required this.savedProductsCount,
    required this.email,
    this.phoneNumber,
  });

  factory UserDataModel.fromJson(Map<String, dynamic> json) {
    return UserDataModel(
      userName:               json['userName'] ?? '',
      userRating:             (json['userRating'] ?? 0.0).toDouble(),
      totalRatings:           json['totalRatings'] ?? 0,
      profileImage:           json['profileImage'],
      availableProductsCount: json['availableProductsCount'] ?? 0,
      savedProductsCount:     json['savedProductsCount'] ?? 0,
      email:                  json['email'] ?? '',
      phoneNumber:            json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() => {
        'userName':               userName,
        'userRating':             userRating,
        'totalRatings':           totalRatings,
        'profileImage':           profileImage,
        'availableProductsCount': availableProductsCount,
        'savedProductsCount':     savedProductsCount,
        'email':                  email,
        'phoneNumber':            phoneNumber,
      };
}