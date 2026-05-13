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
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PulseModel.fromMap(doc.data()))
              .toList(),
        );
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
  }) {
    final key = pulseDateKey(DateTime.now());
    final id = pulseDocumentId(dateKey: key, userId: user.id);
    final now = DateTime.now();
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
      createdAt: now,
      updatedAt: now,
    );

    return _circles
        .doc(circleId)
        .collection('pulses')
        .doc(id)
        .set(pulse.toMap(), SetOptions(merge: true));
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
