import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/date_key.dart';
import '../../profile/domain/app_user.dart';
import '../domain/pulse.dart';
import '../domain/pulse_repository.dart';

class FirebasePulseRepository implements PulseRepository {
  FirebasePulseRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _circles =>
      _firestore.collection('circles');

  @override
  Stream<List<PulseModel>> watchTodayPulses(String circleId) {
    final key = pulseDateKey(DateTime.now());
    return _circles
        .doc(circleId)
        .collection('pulses')
        .where('dateKey', isEqualTo: key)
        .snapshots()
        .map((snapshot) {
          final pulses = snapshot.docs
              .map((doc) => PulseModel.fromMap(doc.data()))
              .toList();
          pulses.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return pulses;
        });
  }

  @override
  Stream<PulseModel?> watchMyTodayPulse({
    required String circleId,
    required String userId,
  }) {
    final key = pulseDateKey(DateTime.now());
    return _circles
        .doc(circleId)
        .collection('pulses')
        .doc(pulseDocumentId(dateKey: key, userId: userId))
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (!snapshot.exists || data == null) {
            return null;
          }
          return PulseModel.fromMap(data);
        });
  }

  @override
  Future<void> createOrUpdatePulse({
    required String circleId,
    required AppUser user,
    required String photoUrl,
    required String? caption,
    required String? mood,
  }) async {
    final key = pulseDateKey(DateTime.now());
    final id = pulseDocumentId(dateKey: key, userId: user.id);
    final now = DateTime.now();
    final circleRef = _circles.doc(circleId);
    final pulseRef = circleRef.collection('pulses').doc(id);

    await _firestore.runTransaction((transaction) async {
      final circleSnapshot = await transaction.get(circleRef);
      final pulseSnapshot = await transaction.get(pulseRef);
      final circleData = circleSnapshot.data() ?? <String, dynamic>{};
      final isNewPulse = !pulseSnapshot.exists;

      final pulse = PulseModel(
        id: id,
        circleId: circleId,
        userId: user.id,
        userName: user.displayName,
        userPhotoUrl: user.photoUrl,
        photoUrl: photoUrl,
        caption: _blankToNull(caption),
        mood: _blankToNull(mood),
        dateKey: key,
        createdAt: pulseSnapshot.exists
            ? PulseModel.fromMap(pulseSnapshot.data()!).createdAt
            : now,
        updatedAt: now,
      );

      transaction.set(pulseRef, pulse.toMap(), SetOptions(merge: true));

      if (!isNewPulse) {
        return;
      }

      final existingKey = circleData['todayPulseDateKey'] as String?;
      final existingCount = (circleData['todayPulseCount'] as int?) ?? 0;
      final nextCount = existingKey == key ? existingCount + 1 : 1;
      transaction.update(circleRef, {
        'todayPulseDateKey': key,
        'todayPulseCount': nextCount,
        'updatedAt': now,
      });
    });
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
