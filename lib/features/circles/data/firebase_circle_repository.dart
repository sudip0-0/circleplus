import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/invite_code_generator.dart';
import '../../profile/domain/app_user.dart';
import '../domain/circle.dart';
import '../domain/circle_member.dart';
import '../domain/circle_repository.dart';

class FirebaseCircleRepository implements CircleRepository {
  FirebaseCircleRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _circles =>
      _firestore.collection('circles');

  @override
  Future<CircleModel> createCircle({
    required String name,
    required String? description,
    required AppUser creator,
  }) async {
    final circleRef = _circles.doc();
    final now = DateTime.now();
    final inviteCode = await _createUniqueInviteCode();
    final circle = CircleModel(
      id: circleRef.id,
      name: name.trim(),
      description: _blankToNull(description),
      coverUrl: null,
      createdBy: creator.id,
      inviteCode: inviteCode,
      memberCount: 1,
      lastMessageText: null,
      lastMessageAt: null,
      createdAt: now,
      updatedAt: now,
    );
    final member = CircleMemberModel(
      userId: creator.id,
      circleId: circle.id,
      role: CircleMemberRole.creator,
      displayName: creator.displayName,
      photoUrl: creator.photoUrl,
      joinedAt: now,
    );

    final batch = _firestore.batch();
    batch.set(circleRef, circle.toMap());
    batch.set(circleRef.collection('members').doc(creator.id), member.toMap());
    await batch.commit();

    return circle;
  }

  @override
  Future<CircleModel> joinCircleByInviteCode({
    required String inviteCode,
    required AppUser user,
  }) async {
    final normalizedCode = inviteCode.trim().toUpperCase();
    if (!isValidInviteCode(normalizedCode)) {
      throw const AppException('Enter a valid 6-character invite code.');
    }

    final query = await _circles
        .where('inviteCode', isEqualTo: normalizedCode)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw const AppException('No Circle found for that invite code.');
    }

    final circleRef = query.docs.first.reference;
    final memberRef = circleRef.collection('members').doc(user.id);

    await _firestore.runTransaction((transaction) async {
      final memberSnapshot = await transaction.get(memberRef);
      if (memberSnapshot.exists) {
        throw const AppException('You are already in this Circle.');
      }

      final now = DateTime.now();
      transaction.set(
        memberRef,
        CircleMemberModel(
          userId: user.id,
          circleId: circleRef.id,
          role: CircleMemberRole.member,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          joinedAt: now,
        ).toMap(),
      );
      transaction.update(circleRef, {
        'memberCount': FieldValue.increment(1),
        'updatedAt': now,
      });
    });

    final snapshot = await circleRef.get();
    return CircleModel.fromMap(snapshot.data() ?? <String, Object?>{});
  }

  @override
  Stream<List<CircleModel>> watchUserCircles(String userId) {
    return _firestore
        .collectionGroup('members')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final circleIds = snapshot.docs
              .map((doc) => doc.data()['circleId'] as String?)
              .whereType<String>()
              .toSet()
              .toList();

          final circles = <CircleModel>[];
          for (final circleId in circleIds) {
            final circleSnapshot = await _circles.doc(circleId).get();
            final data = circleSnapshot.data();
            if (circleSnapshot.exists && data != null) {
              circles.add(CircleModel.fromMap(data));
            }
          }
          circles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return circles;
        });
  }

  @override
  Stream<CircleModel?> watchCircle(String circleId) {
    return _circles.doc(circleId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return CircleModel.fromMap(data);
    });
  }

  @override
  Stream<List<CircleMemberModel>> watchCircleMembers(String circleId) {
    return _circles
        .doc(circleId)
        .collection('members')
        .orderBy('joinedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CircleMemberModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<String> _createUniqueInviteCode() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = generateInviteCode();
      final existing = await _circles
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        return code;
      }
    }
    throw const AppException('Could not create a unique invite code.');
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
