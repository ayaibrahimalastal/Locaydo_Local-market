// lib/features/profile/data/repositories/profile_repository_impl.dart

import 'package:locaydo_app/core/utils/logger.dart';
import 'package:locaydo_app/features/profile/data/models/user_data_model.dart';
import 'package:locaydo_app/features/profile/domain/repositories/profile_repository.dart';


class ProfileRepositoryImpl implements ProfileRepository {
  final Logger _logger;

  ProfileRepositoryImpl({required Logger logger}) : _logger = logger;

  @override
  Future<UserDataModel> getUserData() async {
    // TODO: final doc = await FirebaseFirestore.instance
    //     .collection(FirebaseCollections.users)
    //     .doc(FirebaseAuth.instance.currentUser?.uid)
    //     .get();
    // return UserDataModel.fromJson(doc.data()!);
    _logger.log('getUserData — Firebase not yet configured');
    throw UnimplementedError('Firebase not yet configured');
  }

  @override
  Future<void> logout() async {
    // TODO: await FirebaseAuth.instance.signOut();
    _logger.log('logout — Firebase not yet configured');
    throw UnimplementedError('Firebase not yet configured');
  }

  @override
  Future<void> deleteAccount() async {
    // TODO: await FirebaseAuth.instance.currentUser?.delete();
    _logger.log('deleteAccount — Firebase not yet configured');
    throw UnimplementedError('Firebase not yet configured');
  }
}