import 'package:circleplus/features/circles/domain/circle.dart';
import 'package:circleplus/features/circles/domain/circle_member.dart';
import 'package:circleplus/features/profile/domain/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppUser serializes to and from map', () {
    final now = DateTime(2026, 5, 13, 9, 30);
    final user = AppUser(
      id: 'user-1',
      displayName: 'Sudip',
      email: 'sudip@example.com',
      photoUrl: null,
      bio: 'Private circles first.',
      createdAt: now,
      updatedAt: now,
    );

    final restored = AppUser.fromMap(user.toMap());

    expect(restored.id, user.id);
    expect(restored.displayName, user.displayName);
    expect(restored.email, user.email);
    expect(restored.bio, user.bio);
    expect(restored.createdAt, user.createdAt);
  });

  test('CircleModel serializes to and from map', () {
    final now = DateTime(2026, 5, 13, 9, 30);
    final circle = CircleModel(
      id: 'circle-1',
      name: 'Best Friends',
      description: 'Weekend crew',
      coverUrl: null,
      createdBy: 'user-1',
      inviteCode: 'AB12CD',
      memberCount: 2,
      lastMessageText: null,
      lastMessageAt: null,
      createdAt: now,
      updatedAt: now,
    );

    final restored = CircleModel.fromMap(circle.toMap());

    expect(restored.id, circle.id);
    expect(restored.name, circle.name);
    expect(restored.inviteCode, circle.inviteCode);
    expect(restored.memberCount, circle.memberCount);
  });

  test('CircleMemberModel serializes to and from map', () {
    final now = DateTime(2026, 5, 13, 9, 30);
    final member = CircleMemberModel(
      userId: 'user-1',
      circleId: 'circle-1',
      role: CircleMemberRole.member,
      displayName: 'Sudip',
      photoUrl: null,
      joinedAt: now,
      inviteCodeUsed: 'AB12CD',
    );

    final restored = CircleMemberModel.fromMap(member.toMap());

    expect(restored.userId, member.userId);
    expect(restored.circleId, member.circleId);
    expect(restored.role, member.role);
    expect(restored.joinedAt, member.joinedAt);
    expect(restored.inviteCodeUsed, member.inviteCodeUsed);
  });
}
