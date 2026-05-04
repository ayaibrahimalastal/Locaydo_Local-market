// lib/features/auth/domain/entities/user_entity.dart

class UserEntity {
  final String uid;
  final String? email;
  final String? username;
  final bool isEmailVerified;
  final bool isSeller;
  final bool hasCompletedSellerProfile;
  final DateTime? createdAt;

  const UserEntity({
    required this.uid,
    this.email,
    this.username,
    this.isEmailVerified = false,
    this.isSeller = false,
    this.hasCompletedSellerProfile = false,
    this.createdAt,
  });

  factory UserEntity.fromFirebaseUser(dynamic firebaseUser) {
    return UserEntity(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      username: firebaseUser.displayName,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime,
    );
  }

  factory UserEntity.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserEntity(
      uid: uid,
      email: data['email'],
      username: data['username'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      isSeller: data['isSeller'] ?? false,
      hasCompletedSellerProfile: data['hasCompletedSellerProfile'] ?? false,
      createdAt: data['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'email': email,
    'username': username,
    'isEmailVerified': isEmailVerified,
    'isSeller': isSeller,
    'hasCompletedSellerProfile': hasCompletedSellerProfile,
    'createdAt': createdAt,
  };

  UserEntity copyWith({
    String? uid,
    String? email,
    String? username,
    bool? isEmailVerified,
    bool? isSeller,
    bool? hasCompletedSellerProfile,
    DateTime? createdAt,
  }) => UserEntity(
    uid: uid ?? this.uid,
    email: email ?? this.email,
    username: username ?? this.username,
    isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    isSeller: isSeller ?? this.isSeller,
    hasCompletedSellerProfile:
        hasCompletedSellerProfile ?? this.hasCompletedSellerProfile,
    createdAt: createdAt ?? this.createdAt,
  );
}