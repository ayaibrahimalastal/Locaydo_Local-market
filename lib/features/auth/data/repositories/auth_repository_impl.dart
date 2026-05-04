// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/auth/domain/entities/user_entity.dart';
import 'package:locaydo_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Logger _logger;

  AuthRepositoryImpl({
    required Logger logger,
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _logger = logger,
       _auth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Signup ────────────────────────────────────────────────────────────────

  @override
  Future<UserEntity> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      _logger.log('signup: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;

      await user.updateDisplayName(username);
      await user.reload();
      await user.sendEmailVerification();

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'username': username,
        'email': email,
        'hasCompletedSellerProfile': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.log('signup success: ${user.uid}');
      return UserEntity.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      _logger.error('signup FirebaseAuthException', e);
      throw Exception(_mapAuthError(e.code, e.message));
    } catch (e) {
      _logger.error('signup error', e);
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      _logger.log('login: $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      await user.reload();

      _logger.log('login success: ${user.uid}');
      return UserEntity.fromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      _logger.error('login FirebaseAuthException', e);
      throw Exception(_mapAuthError(e.code, e.message));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _logger.log('logout success');
    } catch (e) {
      _logger.error('logout error', e);
      throw Exception('حدث خطأ في تسجيل الخروج');
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _logger.log('sendPasswordResetEmail: $email');
      
      // ✅ إرسال مباشر - Firebase يرسل الرابط فقط إذا كان الإيميل موجوداً
      // ✅ لأسباب أمنية، لا نتحقق من وجود الإيميل مسبقاً
      await _auth.sendPasswordResetEmail(email: email);
      
      _logger.log('password reset email sent successfully: $email');
      
    } on FirebaseAuthException catch (e) {
      _logger.error('sendPasswordResetEmail FirebaseAuthException', e);
      
      // ✅ حتى لو كان user-not-found، نعطي نفس الرسالة (لأسباب أمنية)
      // ✅ لا نخبر المستخدم إذا كان الإيميل غير مسجل
      throw Exception('حدث خطأ في إرسال رابط إعادة التعيين');
    } catch (e) {
      _logger.error('sendPasswordResetEmail error', e);
      rethrow;
    }
  }

  // ── Activation ────────────────────────────────────────────────────────────

  @override
  Future<void> resendActivationLink(String email) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('يرجى تسجيل الدخول أولاً لإعادة إرسال رابط التفعيل');
      }
      
      await user.sendEmailVerification();
      _logger.log('activation link resent: $email');
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code, e.message));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    await user?.reload();
    return user?.emailVerified ?? false;
  }

  // ── Account ───────────────────────────────────────────────────────────────

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('لا يوجد مستخدم');
      
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      
      _logger.log('account deleted');
    } catch (e) {
      throw Exception('حدث خطأ في حذف الحساب');
    }
  }

  @override
  UserEntity? getCurrentUser() {
    final user = _auth.currentUser;
    return user != null ? UserEntity.fromFirebaseUser(user) : null;
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return _auth.authStateChanges().map(
      (user) => user != null ? UserEntity.fromFirebaseUser(user) : null,
    );
  }

  // ── Helper Methods ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      _logger.error('getUserData error', e);
      return null;
    }
  }

  Future<void> updateSellerProfileStatus(String uid, bool completed) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'hasCompletedSellerProfile': completed,
      });
      _logger.log('seller profile status updated: $uid -> $completed');
    } catch (e) {
      _logger.error('updateSellerProfileStatus error', e);
      throw Exception('حدث خطأ في تحديث حالة ملف البائع');
    }
  }

  // ── Error Mapping ─────────────────────────────────────────────────────────

  String _mapAuthError(String code, String? message) {
    switch (code) {
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، استخدم 6 أحرف على الأقل';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'user-disabled':
        return 'الحساب معطل، تواصل مع الدعم';
      case 'network-request-failed':
        return 'لا يوجد اتصال بالإنترنت';
      case 'too-many-requests':
        return 'عدد كبير من المحاولات، حاول لاحقاً';
      case 'operation-not-allowed':
        return 'تسجيل الدخول بالبريد وكلمة المرور غير مفعل';
      default:
        return message ?? 'حدث خطأ غير متوقع';
    }
  }
}