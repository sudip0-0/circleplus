import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_profile_repository.dart';
import '../domain/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirebaseProfileRepository();
});
