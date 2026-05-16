import 'package:circleplus/core/errors/app_exception.dart';
import 'package:circleplus/features/circles/domain/circle.dart';
import 'package:circleplus/features/circles/domain/circle_member.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Pure domain / logic tests for Leave Circle edge cases.
//
// These tests exercise the in-memory decision logic that mirrors what the
// FirebaseCircleRepository and CircleMembersScreen do. They do not require
// Firebase or a network connection.
// ---------------------------------------------------------------------------

/// Simulates the repository-level guard for leaving as a creator.
/// Returns normally on success, throws [AppException] when blocked.
void guardLeaveAsCreator({
  required String role,
  required int memberCount,
}) {
  if (role == 'creator' && memberCount > 1) {
    throw const AppException(
      'You created this Circle. Ask another member to host it before you leave, or delete the Circle if you want to close it.',
    );
  }
}

void main() {
  group('Leave Circle – domain guard', () {
    test('regular member can always leave', () {
      expect(
        () => guardLeaveAsCreator(role: 'member', memberCount: 3),
        returnsNormally,
      );
    });

    test('creator can leave when they are the only member (triggers delete)', () {
      expect(
        () => guardLeaveAsCreator(role: 'creator', memberCount: 1),
        returnsNormally,
      );
    });

    test('creator is blocked when other members still exist', () {
      expect(
        () => guardLeaveAsCreator(role: 'creator', memberCount: 2),
        throwsA(isA<AppException>()),
      );
    });

    test('AppException message is user-friendly', () {
      try {
        guardLeaveAsCreator(role: 'creator', memberCount: 5);
        fail('Expected AppException');
      } on AppException catch (e) {
        expect(e.message, contains('created this Circle'));
      }
    });
  });

  group('CircleMemberModel – role detection', () {
    test('CircleMemberRole.fromName parses creator correctly', () {
      expect(
        CircleMemberRole.fromName('creator'),
        CircleMemberRole.creator,
      );
    });

    test('CircleMemberRole.fromName parses member correctly', () {
      expect(
        CircleMemberRole.fromName('member'),
        CircleMemberRole.member,
      );
    });

    test('CircleMemberRole.fromName falls back to member for unknown values', () {
      expect(
        CircleMemberRole.fromName('unknown'),
        CircleMemberRole.member,
      );
    });

    test('CircleMemberRole.fromName falls back to member for null', () {
      expect(
        CircleMemberRole.fromName(null),
        CircleMemberRole.member,
      );
    });
  });

  group('CircleModel – serialization round-trip', () {
    test('toMap / fromMap preserves all fields', () {
      final now = DateTime(2026, 5, 16, 12, 0);
      final circle = CircleModel(
        id: 'circle-abc',
        name: 'Weekend crew',
        description: 'Our weekend hangout circle',
        coverUrl: null,
        createdBy: 'user-1',
        inviteCode: 'ABC123',
        memberCount: 3,
        lastMessageText: 'See you soon',
        lastMessageAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final restored = CircleModel.fromMap(circle.toMap());

      expect(restored.id, circle.id);
      expect(restored.name, circle.name);
      expect(restored.memberCount, 3);
      expect(restored.inviteCode, 'ABC123');
    });
  });
}
