import '../../core/errors/app_exception.dart';

/// Blocks Circle creators from leaving while other members remain.
///
/// Used by [FirebaseCircleRepository.leaveCircle]. Creator last-member
/// deletion is a separate path (`deleteCircle`).
void guardLeaveAsCreator({
  required String? role,
  required int memberCount,
}) {
  if (role == 'creator' && memberCount > 1) {
    throw const AppException(
      'You created this Circle. Ask another member to host it before you leave, or delete the Circle if you want to close it.',
    );
  }
}
