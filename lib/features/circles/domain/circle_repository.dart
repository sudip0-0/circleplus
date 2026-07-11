import '../../profile/domain/app_user.dart';
import 'circle.dart';
import 'circle_member.dart';

abstract interface class CircleRepository {
  Future<CircleModel> createCircle({
    required String name,
    required String? description,
    required AppUser creator,
  });

  Future<CircleModel> joinCircleByInviteCode({
    required String inviteCode,
    required AppUser user,
  });

  Stream<List<CircleModel>> watchUserCircles(String userId);

  Stream<CircleModel?> watchCircle(String circleId);

  Stream<List<CircleMemberModel>> watchCircleMembers(String circleId);

  /// Removes [userId] from [circleId] and decrements memberCount atomically.
  /// Throws [AppException] if the user is the creator and there are other
  /// members still in the Circle.
  Future<void> leaveCircle({
    required String circleId,
    required String userId,
  });

  /// Soft-deletes the Circle (`status: deleted`) and removes the creator's
  /// membership. Only callable by the creator when they are the last member.
  Future<void> deleteCircle({
    required String circleId,
    required String creatorId,
  });
}
