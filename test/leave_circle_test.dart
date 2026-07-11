import 'package:circleplus/core/errors/app_exception.dart';
import 'package:circleplus/core/utils/circle_leave_guard.dart';
import 'package:circleplus/features/circles/domain/circle.dart';
import 'package:circleplus/features/circles/domain/circle_member.dart';
import 'package:flutter_test/flutter_test.dart';

// Pure-logic coverage for leave/delete decisions.
// End-to-end Firestore rule coverage for leave/delete lives in rules-tests/.

void main() {
  group('guardLeaveAsCreator', () {
    test('regular member can always leave', () {
      expect(
        () => guardLeaveAsCreator(role: 'member', memberCount: 3),
        returnsNormally,
      );
    });

    test('creator can leave when they are the only member', () {
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

  group('CircleMemberRole', () {
    test('parses creator and member', () {
      expect(CircleMemberRole.fromName('creator'), CircleMemberRole.creator);
      expect(CircleMemberRole.fromName('member'), CircleMemberRole.member);
      expect(CircleMemberRole.fromName('unknown'), CircleMemberRole.member);
      expect(CircleMemberRole.fromName(null), CircleMemberRole.member);
    });
  });

  group('CircleModel serialization', () {
    test('toMap / fromMap preserves fields', () {
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
      expect(restored.memberCount, 3);
      expect(restored.inviteCode, 'ABC123');
    });
  });
}
