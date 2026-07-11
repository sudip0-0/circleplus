import 'package:circleplus/features/circles/domain/circle.dart';
import 'package:circleplus/features/circles/domain/circle_member.dart';
import 'package:circleplus/features/circles/domain/circle_repository.dart';
import 'package:circleplus/features/circles/presentation/circle_controller.dart';
import 'package:circleplus/features/auth/domain/auth_user.dart';
import 'package:circleplus/features/auth/presentation/auth_controller.dart';
import 'package:circleplus/features/messages/domain/message.dart';
import 'package:circleplus/features/messages/domain/message_repository.dart';
import 'package:circleplus/features/messages/presentation/message_controller.dart';
import 'package:circleplus/features/profile/domain/app_user.dart';
import 'package:circleplus/features/profile/domain/profile_repository.dart';
import 'package:circleplus/app/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCircleRepository implements CircleRepository {
  String? deletedCircleId;
  String? deletedCreatorId;

  @override
  Future<CircleModel> createCircle({
    required String name,
    required String? description,
    required AppUser creator,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteCircle({
    required String circleId,
    required String creatorId,
  }) async {
    deletedCircleId = circleId;
    deletedCreatorId = creatorId;
  }

  @override
  Future<CircleModel> joinCircleByInviteCode({
    required String inviteCode,
    required AppUser user,
  }) => throw UnimplementedError();

  @override
  Future<void> leaveCircle({
    required String circleId,
    required String userId,
  }) => throw UnimplementedError();

  @override
  Stream<CircleModel?> watchCircle(String circleId) =>
      Stream.value(null);

  @override
  Stream<List<CircleMemberModel>> watchCircleMembers(String circleId) =>
      Stream.value(const []);

  @override
  Stream<List<CircleModel>> watchUserCircles(String userId) =>
      Stream.value(const []);
}

class _FakeMessageRepository implements MessageRepository {
  String? softDeletedCircleId;
  String? softDeletedMessageId;

  @override
  Future<List<MessageModel>> loadOlderMessages({
    required String circleId,
    required DateTime before,
    int limit = 40,
  }) async => const [];

  @override
  Future<void> sendPhotoMessage({
    required String circleId,
    required String mediaUrl,
    required String? text,
    required AppUser sender,
  }) => throw UnimplementedError();

  @override
  Future<void> sendTextMessage({
    required String circleId,
    required String text,
    required AppUser sender,
  }) => throw UnimplementedError();

  @override
  Future<void> softDeleteMessage({
    required String circleId,
    required String messageId,
  }) async {
    softDeletedCircleId = circleId;
    softDeletedMessageId = messageId;
  }

  @override
  Stream<List<MessageModel>> watchMessages(String circleId, {int limit = 40}) =>
      Stream.value(const []);
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.profile);

  final AppUser profile;

  @override
  Future<void> createProfile(AppUser user) async {}

  @override
  Future<AppUser?> getProfile(String userId) async =>
      userId == profile.id ? profile : null;

  @override
  Future<void> updateProfile(AppUser user) async {}

  @override
  Stream<AppUser?> watchProfile(String userId) =>
      Stream.value(userId == profile.id ? profile : null);
}

void main() {
  const authUser = AuthUser(
    id: 'user-1',
    email: 'a@example.com',
    displayName: 'Ada',
    photoUrl: null,
  );
  final profile = AppUser(
    id: 'user-1',
    displayName: 'Ada',
    email: 'a@example.com',
    photoUrl: null,
    bio: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  test('deleteCircle controller passes creator tombstone call shape', () async {
    final circles = _FakeCircleRepository();
    final container = ProviderContainer(
      overrides: [
        circleRepositoryProvider.overrideWithValue(circles),
        currentUserProvider.overrideWithValue(authUser),
        profileRepositoryProvider.overrideWithValue(
          _FakeProfileRepository(profile),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(circleControllerProvider.notifier)
        .deleteCircle('circle-xyz');

    expect(circles.deletedCircleId, 'circle-xyz');
    expect(circles.deletedCreatorId, 'user-1');
  });

  test('softDeleteMessage controller passes ids to repository', () async {
    final messages = _FakeMessageRepository();
    final container = ProviderContainer(
      overrides: [
        messageRepositoryProvider.overrideWithValue(messages),
        currentUserProvider.overrideWithValue(authUser),
        profileRepositoryProvider.overrideWithValue(
          _FakeProfileRepository(profile),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(messageControllerProvider.notifier)
        .softDeleteMessage(circleId: 'c1', messageId: 'm9');

    expect(messages.softDeletedCircleId, 'c1');
    expect(messages.softDeletedMessageId, 'm9');
  });

  test('CircleModel treats missing status as active and maps deleted', () {
    final now = DateTime(2026, 7, 11);
    final active = CircleModel.fromMap({
      'id': 'c1',
      'name': 'Crew',
      'createdBy': 'u1',
      'inviteCode': 'ABC123',
      'memberCount': 1,
      'createdAt': now,
      'updatedAt': now,
    });
    expect(active.status, CircleStatus.active);
    expect(active.isDeleted, isFalse);

    final deleted = CircleModel.fromMap({
      'id': 'c2',
      'name': 'Gone',
      'createdBy': 'u1',
      'inviteCode': 'DEF456',
      'memberCount': 1,
      'status': 'deleted',
      'createdAt': now,
      'updatedAt': now,
    });
    expect(deleted.isDeleted, isTrue);
    expect(deleted.toMap()['status'], 'deleted');
  });
}
