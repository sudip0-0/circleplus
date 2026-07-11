import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/circle_leave_guard.dart';
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

  CollectionReference<Map<String, dynamic>> get _inviteCodes =>
      _firestore.collection('inviteCodes');

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
    batch.set(_inviteCodes.doc(inviteCode), {
      'code': inviteCode,
      'circleId': circle.id,
      'createdBy': creator.id,
      'createdAt': now,
    });
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

    final inviteSnapshot = await _inviteCodes.doc(normalizedCode).get();
    final inviteData = inviteSnapshot.data();
    final circleId = inviteData?['circleId'] as String?;
    if (!inviteSnapshot.exists || circleId == null) {
      throw const AppException('No Circle found for that invite code.');
    }

    final circleRef = _circles.doc(circleId);
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
          inviteCodeUsed: normalizedCode,
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

          final snapshots = await Future.wait(
            circleIds.map((circleId) => _circles.doc(circleId).get()),
          );

          final circles = <CircleModel>[];
          for (final circleSnapshot in snapshots) {
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

  @override
  Future<void> leaveCircle({
    required String circleId,
    required String userId,
  }) async {
    final circleRef = _circles.doc(circleId);
    final memberRef = circleRef.collection('members').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final circleSnapshot = await transaction.get(circleRef);
      final memberSnapshot = await transaction.get(memberRef);

      if (!memberSnapshot.exists) {
        throw const AppException('You are not a member of this Circle.');
      }

      final role = memberSnapshot.data()?['role'] as String?;
      final memberCount =
          (circleSnapshot.data()?['memberCount'] as int?) ?? 0;

      guardLeaveAsCreator(role: role, memberCount: memberCount);

      transaction.delete(memberRef);
      transaction.update(circleRef, {
        'memberCount': FieldValue.increment(-1),
        'updatedAt': DateTime.now(),
      });
    });
  }

  @override
  Future<void> deleteCircle({
    required String circleId,
    required String creatorId,
  }) async {
    final circleRef = _circles.doc(circleId);

    // Verify the requester is the creator and is the last member before
    // deleting. We read inside a transaction to prevent TOCTOU races.
    await _firestore.runTransaction((transaction) async {
      final circleSnapshot = await transaction.get(circleRef);
      if (!circleSnapshot.exists) {
        return;
      }
      final data = circleSnapshot.data()!;
      if (data['createdBy'] != creatorId) {
        throw const AppException('Only the creator can delete a Circle.');
      }
      final memberCount = (data['memberCount'] as int?) ?? 0;
      if (memberCount > 1) {
        throw const AppException(
          'Cannot delete a Circle that still has other members.',
        );
      }

      // Delete the creator's own member document and the circle document.
      final memberRef = circleRef.collection('members').doc(creatorId);
      transaction.delete(memberRef);
      transaction.delete(circleRef);
    });
  }

  Future<String> _createUniqueInviteCode() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = generateInviteCode();
      final existing = await _inviteCodes.doc(code).get();
      if (!existing.exists) {
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
