import 'package:circleplus/features/messages/domain/message.dart';
import 'package:circleplus/features/plans/domain/plan.dart';
import 'package:circleplus/features/plans/domain/plan_response.dart';
import 'package:circleplus/features/pulses/domain/pulse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MessageModel serializes to and from map', () {
    final now = DateTime(2026, 5, 13, 10, 15);
    final message = MessageModel(
      id: 'message-1',
      circleId: 'circle-1',
      senderId: 'user-1',
      senderName: 'Sudip',
      senderPhotoUrl: null,
      type: MessageType.text,
      text: 'See you soon',
      mediaUrl: null,
      createdAt: now,
      updatedAt: null,
    );

    final restored = MessageModel.fromMap(message.toMap());

    expect(restored.id, message.id);
    expect(restored.type, MessageType.text);
    expect(restored.text, message.text);
    expect(restored.createdAt, now);
  });

  test('PulseModel serializes and uses daily document id', () {
    final now = DateTime(2026, 5, 13, 10, 15);
    final pulse = PulseModel(
      id: pulseDocumentId(dateKey: '20260513', userId: 'user-1'),
      circleId: 'circle-1',
      userId: 'user-1',
      userName: 'Sudip',
      userPhotoUrl: null,
      photoUrl: 'https://example.com/pulse.jpg',
      caption: 'Coffee walk',
      mood: 'easy',
      dateKey: '20260513',
      createdAt: now,
      updatedAt: now,
    );

    final restored = PulseModel.fromMap(pulse.toMap());

    expect(pulse.id, '20260513_user-1');
    expect(restored.id, pulse.id);
    expect(restored.dateKey, '20260513');
    expect(restored.caption, 'Coffee walk');
  });

  test('PlanModel serializes to and from map', () {
    final now = DateTime(2026, 5, 13, 10, 15);
    final plan = PlanModel(
      id: 'plan-1',
      circleId: 'circle-1',
      createdBy: 'user-1',
      createdByName: 'Sudip',
      title: 'Coffee',
      description: 'Meet downtown',
      location: 'Cafe',
      startsAt: now.add(const Duration(days: 1)),
      status: PlanStatus.active,
      inCount: 1,
      maybeCount: 0,
      cantCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    final restored = PlanModel.fromMap(plan.toMap());

    expect(restored.id, plan.id);
    expect(restored.status, PlanStatus.active);
    expect(restored.inCount, 1);
    expect(restored.startsAt, plan.startsAt);
  });

  test(
    'PlanResponseModel serializes and count delta avoids duplicate inflation',
    () {
      final now = DateTime(2026, 5, 13, 10, 15);
      final response = PlanResponseModel(
        userId: 'user-1',
        userName: 'Sudip',
        userPhotoUrl: null,
        response: PlanResponseValue.in_,
        comment: null,
        updatedAt: now,
      );

      final restored = PlanResponseModel.fromMap(response.toMap());
      final duplicateDelta = planResponseCountDelta(
        previous: PlanResponseValue.in_,
        next: PlanResponseValue.in_,
      );
      final changedDelta = planResponseCountDelta(
        previous: PlanResponseValue.maybe,
        next: PlanResponseValue.cant,
      );

      expect(restored.response, PlanResponseValue.in_);
      expect(duplicateDelta, {'inCount': 0, 'maybeCount': 0, 'cantCount': 0});
      expect(changedDelta, {'inCount': 0, 'maybeCount': -1, 'cantCount': 1});
    },
  );
}
