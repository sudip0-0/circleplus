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
}
