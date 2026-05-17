# architecture.md

## Product Architecture Overview

CirclePulse is a private group-based social app.

The architecture should support:
- real-time group communication
- private group membership
- daily photo updates
- lightweight meetup planning
- scalable but simple Firebase backend
- Cloudflare R2 media storage through a backend upload endpoint
- Flutter UI with clean state management

## System Overview

```txt
Flutter App
  |
  |-- Firebase Authentication
  |
  |-- Cloud Firestore
  |     |-- users
  |     |-- circles
  |     |-- inviteCodes
  |     |-- members
  |     |-- messages
  |     |-- pulses
  |     |-- plans
  |     |-- responses
  |
  |-- Cloudflare R2
  |     |-- avatars
  |     |-- circle covers
  |     |-- message photos
  |     |-- pulse photos
  |     |-- uploads must use backend-generated presigned URLs
  |
  |-- Firebase Cloud Messaging
        |-- notifications for messages, pulses, plans
```

## Flutter Architecture

Use a feature-first structure with shared app infrastructure at the top level.

```txt
lib/
  main.dart

  app.dart

  core/
    constants/
      app_constants.dart
    errors/
      app_exception.dart
    utils/
      date_key.dart
      invite_code_generator.dart
      media_type.dart

  routing/
    app_router.dart

  theme/
    app_theme.dart

  shared/
    widgets/
      empty_state.dart
      loading_view.dart
      error_view.dart
      app_text_field.dart
      avatar.dart
      circlepulse_ui.dart
    models/
    extensions/

  services/
    firebase/
      firebase_service.dart
    storage/
      storage_service.dart
    notifications/
      notification_service.dart

  features/
    auth/
      data/
        firebase_auth_repository.dart
      domain/
        auth_repository.dart
        auth_user.dart
      presentation/
        auth_controller.dart
        sign_in_screen.dart
        sign_up_screen.dart

    profile/
      data/
        firebase_profile_repository.dart
      domain/
        app_user.dart
        profile_repository.dart
      presentation/
        profile_providers.dart
        edit_profile_screen.dart
        profile_controller.dart

    circles/
      data/
        firebase_circle_repository.dart
      domain/
        circle.dart
        circle_member.dart
        circle_repository.dart
      presentation/
        home_screen.dart
        create_circle_screen.dart
        join_circle_screen.dart
        circle_room_screen.dart
        circle_members_screen.dart
        circle_controller.dart

    messages/
      data/
        firebase_message_repository.dart
      domain/
        message.dart
        message_repository.dart
      presentation/
        message_list.dart
        message_composer.dart
        message_controller.dart

    pulses/
      data/
        firebase_pulse_repository.dart
      domain/
        pulse.dart
        pulse_repository.dart
      presentation/
        today_pulse_card.dart
        pulse_wall_screen.dart
        create_pulse_screen.dart
        pulse_controller.dart

    plans/
      data/
        firebase_plan_repository.dart
      domain/
        plan.dart
        plan_response.dart
        plan_repository.dart
      presentation/
        plan_card.dart
        create_plan_screen.dart
        plan_detail_screen.dart
        plan_controller.dart

    notifications/
      data/
        firebase_notification_repository.dart
      domain/
        notification_repository.dart
      presentation/
        notification_controller.dart

  services/
    notifications/
      notification_service.dart
```

## Dependency Direction

```txt
presentation -> domain -> data
```

Rules:
- presentation can depend on domain
- data can implement domain repository interfaces
- domain should not import Flutter UI or Firebase directly
- Firebase details should stay inside data layer

## UI Structure

The MVP UI uses Material 3 plus a small shared visual layer in
`shared/widgets/circlepulse_ui.dart`.

That layer owns:
- warm CirclePulse colors
- gradient app background through `WarmScaffold`
- soft app bars and icon buttons
- rounded private-card containers
- the CirclePulse logo mark
- the primary gradient action button
- reusable privacy/info panels

Feature screens still own their product layout and state wiring. Widgets do not
call Firebase directly; screens continue to use Riverpod controllers and
repositories for app behavior.

## Firebase Collections

### users

Path:

```txt
users/{userId}
```

Fields:

```json
{
  "id": "userId",
  "displayName": "Adam",
  "email": "adam@example.com",
  "photoUrl": null,
  "bio": null,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp",
  "fcmTokens": [],
  "fcmTokenUpdatedAt": "timestamp"
}
```

Purpose:
- user identity
- display name
- avatar
- basic profile
- notification-ready FCM token storage

### circles

Path:

```txt
circles/{circleId}
```

Fields:

```json
{
  "id": "circleId",
  "name": "Best Friends",
  "description": "Our private circle",
  "coverUrl": null,
  "createdBy": "userId",
  "inviteCode": "AB12CD",
  "memberCount": 4,
  "lastMessageText": "See you tomorrow",
  "lastMessageAt": "timestamp",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

Purpose:
- private group metadata
- invite code
- home screen card data

### invite codes

Path:

```txt
inviteCodes/{inviteCode}
```

Fields:

```json
{
  "code": "AB12CD",
  "circleId": "circleId",
  "createdBy": "userId",
  "createdAt": "serverTimestamp"
}
```

Purpose:
- resolve exact invite codes without making all Circle metadata readable
- prevent invite code collisions during Circle creation

### circle members

Path:

```txt
circles/{circleId}/members/{userId}
```

Fields:

```json
{
  "userId": "userId",
  "circleId": "circleId",
  "role": "creator",
  "displayName": "Adam",
  "photoUrl": null,
  "joinedAt": "serverTimestamp",
  "inviteCodeUsed": null
}
```

Roles:
- creator
- member

Purpose:
- permission checking
- member list
- Circle access
- invite-backed join verification for non-creator members

### messages

Path:

```txt
circles/{circleId}/messages/{messageId}
```

Fields:

```json
{
  "id": "messageId",
  "circleId": "circleId",
  "senderId": "userId",
  "senderName": "Adam",
  "senderPhotoUrl": null,
  "type": "text",
  "text": "Hello",
  "mediaUrl": null,
  "createdAt": "serverTimestamp",
  "updatedAt": null
}
```

Message types:
- text
- photo
- system

Purpose:
- real-time group chat

### pulses

Path:

```txt
circles/{circleId}/pulses/{yyyyMMdd_userId}
```

Fields:

```json
{
  "id": "20260512_userId",
  "circleId": "circleId",
  "userId": "userId",
  "userName": "Adam",
  "userPhotoUrl": null,
  "photoUrl": "storageUrl",
  "caption": "Studying today",
  "mood": "tired",
  "dateKey": "20260512",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

Purpose:
- one daily update per user per Circle
- group presence ritual

### plans

Path:

```txt
circles/{circleId}/plans/{planId}
```

Fields:

```json
{
  "id": "planId",
  "circleId": "circleId",
  "createdBy": "userId",
  "createdByName": "Adam",
  "title": "Let’s meet Saturday",
  "description": "Coffee?",
  "location": "Downtown",
  "startsAt": "timestamp",
  "status": "active",
  "inCount": 2,
  "maybeCount": 1,
  "cantCount": 0,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

Status:
- active
- cancelled
- completed

Purpose:
- lightweight meetup proposal

### plan responses

Path:

```txt
circles/{circleId}/plans/{planId}/responses/{userId}
```

Fields:

```json
{
  "userId": "userId",
  "userName": "Adam",
  "userPhotoUrl": null,
  "response": "in",
  "comment": "I can come",
  "updatedAt": "serverTimestamp"
}
```

Response values:
- in
- maybe
- cant

Purpose:
- event voting
- social coordination

## Media Storage

```txt
users/{userId}/avatar.jpg

circles/{circleId}/cover.jpg

circles/{circleId}/messages/{messageId}.jpg

circles/{circleId}/pulses/{dateKey}_{userId}.jpg
```

CirclePulse uses Cloudflare R2 for media storage instead of Firebase Storage.
R2 credentials must never be shipped in the Flutter app. They may live in a
local `.env` file for backend/serverless development only.

The Flutter app uploads media through a backend or serverless endpoint that
returns presigned upload URLs. Media features depend on the `StorageService`
abstraction and never access R2 credentials directly.

## Navigation Flow

```txt
App Start
  |
  |-- Not authenticated -> Sign In / Sign Up
  |
  |-- Authenticated
        |
        |-- User profile missing -> Create/Edit Profile
        |
        |-- User profile exists -> Home
              |
              |-- Create Circle
              |-- Join Circle
              |-- Circle Room
                    |
                    |-- Circle Chat
                    |-- Members
                    |-- Create Pulse
                    |-- Pulse Wall
                    |-- Create Plan
                    |-- Plan Detail
```

## Routing

Implemented routes:

```txt
/sign-in
/sign-up
/profile/edit
/home
/circles/create
/circles/join
/circles/:circleId
/circles/:circleId/chat
/circles/:circleId/members
/circles/:circleId/pulse/create
/circles/:circleId/pulses
/circles/:circleId/plans/create
/circles/:circleId/plans/:planId
```

## State Management

Use Riverpod providers.

### Auth Providers

```txt
authRepositoryProvider
authStateProvider
currentUserProvider
authControllerProvider
```

### Profile Providers

```txt
profileRepositoryProvider
currentUserProfileProvider
profileControllerProvider
```

### Circle Providers

```txt
circleRepositoryProvider
userCirclesProvider
circleProvider(circleId)
circleMembersProvider(circleId)
circleControllerProvider
```

### Message Providers

```txt
messageRepositoryProvider
circleMessagesProvider(circleId)
messageControllerProvider
```

Messages are streamed from the latest bounded query and rendered oldest to
newest in the UI to avoid loading unlimited history during the MVP.

### Pulse Providers

```txt
pulseRepositoryProvider
todayPulsesProvider(circleId)
myTodayPulseProvider(circleId)
pulseControllerProvider
```

### Plan Providers

```txt
planRepositoryProvider
activePlansProvider(circleId)
planProvider((circleId, planId))
planResponsesProvider((circleId, planId))
planControllerProvider
```

## Current Circle Room And Chat Composition

Circle rooms now act as a private Circle dashboard and show:
- Circle context, private status, and invite code
- today's Pulse progress and Pulse wall navigation
- member preview and member list action
- upcoming Plan preview and create Plan action
- recent Pulse photo moments
- a primary action into the dedicated Circle chat

Circle chat is a separate route and owns:
- full-height real-time message list
- text and photo messages through the shared R2 upload path
- message composer

Home now shows lightweight per-Circle Pulse progress using today's Pulse count
against the Circle member count, plus whether the current user has posted.

Photo message and Pulse photo creation are wired through `StorageService`.
When `R2_UPLOAD_SIGNER_URL` is configured, the app requests a presigned
Cloudflare R2 PUT URL, uploads bytes to that URL, then stores the returned
public URL in the message or Pulse document. Without the signer URL, the app
shows a developer setup error instead of attempting a direct upload.

## Upload Signer

The repo includes a Cloudflare Worker scaffold at:

```txt
backend/r2-upload-worker
```

The Worker verifies Firebase ID tokens before signing uploads. For Circle media
types (`circleCover`, `messagePhoto`, `pulsePhoto`), it also verifies that the
authenticated user is a member of the target Circle by reading that user's
membership document through Firestore. Avatar uploads are scoped to the
authenticated user.

On success, the Worker returns:

```json
{
  "uploadUrl": "presigned put url",
  "publicUrl": "public media url",
  "objectKey": "r2 object key",
  "method": "PUT"
}
```

Flutter reads the signer URL from:

```txt
--dart-define=R2_UPLOAD_SIGNER_URL=https://your-worker-url
```

## Pulse Date Key

Use local date for user-facing daily behavior.

Format:

```txt
yyyyMMdd
```

Example:

```txt
20260512
```

Utility:

```dart
String pulseDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y$m$d';
}
```

## Invite Code Strategy

For MVP:
- generate 6-character uppercase alphanumeric code
- store in Circle document
- store a matching `inviteCodes/{code}` lookup document
- join by reading the exact invite code document, then adding membership
- prevent duplicate codes before Circle creation

Example:
```txt
A7K2QD
```

Later:
- dynamic links
- expiring invite links
- admin approval

## Notification Architecture

MVP should be notification-ready.

Events that can trigger notifications later:
- new Circle invite
- new message
- new Pulse
- new Plan
- Plan response update

For MVP, prepare:
- FCM token storage under users
- notification service interface
- permission request flow

Implemented user document addition:

```json
{
  "fcmTokens": ["tokenValue"],
  "fcmTokenUpdatedAt": "timestamp"
}
```

## Security Rules Strategy

Important security idea:

Only members of a Circle can access that Circle’s private content.

Helper logic in Firestore rules should check:

```txt
exists(/databases/$(database)/documents/circles/$(circleId)/members/$(request.auth.uid))
```

Required protections:
- non-authenticated users cannot read private content
- non-members cannot read Circle messages, Pulses, Plans
- users can only join a Circle when their member document includes a valid
  invite code that resolves to that Circle
- Circle member count can only increment in the same commit that creates a
  valid invite-backed member document
- users can only post as themselves
- users can only create/update their own Pulse
- users can only create/update their own Plan response
- Plan response count updates must match the user's previous and next response
  in the same commit
- invite-code lookup allows exact signed-in `get` requests but blocks list scans

R2 access must be protected by the upload-signing backend. Firestore rules can
protect stored object keys and URLs, but they cannot protect R2 credentials.

## Performance Notes

Use:
- Firestore streams for chat and live updates
- pagination for messages later
- denormalized last message fields on Circle
- denormalized member display info for faster rendering
- image compression before upload if possible

Avoid:
- loading all messages forever
- deeply nested streams in large widget trees
- public queries over private user data

## UI Component System

Create reusable widgets:
- AppButton
- AppTextField
- CircleCard
- EmptyState
- LoadingView
- ErrorView
- Avatar
- MediaThumbnail
- StatusChip
- ResponseButton

## MVP Risks

### Risk 1: App feels like a WhatsApp clone

Solution:
- make Pulse and Plan visible in the Circle Room
- do not hide them behind menus
- make today’s Pulse progress part of the home screen

### Risk 2: Daily Pulse feels forced

Solution:
- use warm copy
- allow optional caption
- make posting fast
- avoid guilt-heavy messaging

### Risk 3: Event planning feels too serious

Solution:
- call it “Plan”
- use quick responses
- keep calendar complexity out of MVP

### Risk 4: Firebase rules become weak

Solution:
- implement membership-based rules early
- test access patterns
- do not expose private Circle content to non-members

## Future Architecture Ideas

Only after MVP:
- Cloud Functions for notifications
- Firestore aggregate counters
- dynamic invite links
- calendar export
- memories/recaps
- voice notes
- richer reactions
- photo albums
- location-based meetup suggestions
- offline-first improvements
