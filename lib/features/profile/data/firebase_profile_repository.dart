import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_user.dart';
import '../domain/profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<AppUser?> watchProfile(String userId) {
    return _users.doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return AppUser.fromMap(data);
    });
  }

  @override
  Future<AppUser?> getProfile(String userId) async {
    final snapshot = await _users.doc(userId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return AppUser.fromMap(data);
  }

  @override
  Future<void> createProfile(AppUser user) {
    return _users.doc(user.id).set(user.toMap());
  }

  @override
  Future<void> updateProfile(AppUser user) {
    return _users.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }
}
