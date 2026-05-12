# architecture.md

## Product Architecture Overview

CirclePulse is a private group-based social app.

The architecture should support:
- real-time group communication
- private group membership
- daily photo updates
- lightweight meetup planning
- scalable but simple Firebase backend
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
  |     |-- members
  |     |-- messages
  |     |-- pulses
  |     |-- plans
  |     |-- responses
  |
  |-- Firebase Storage
  |     |-- avatars
  |     |-- circle covers
  |     |-- message photos
  |     |-- pulse photos
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

  routing/
    app_router.dart

  theme/
    app_theme.dart

  shared/
    widgets/
      empty_state.dart
      loading_view.dart
      error_view.dart
      app_button.dart
      app_text_field.dart
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
        firebase_notification_service.dart
      domain/
        notification_service.dart
      presentation/
        notification_controller.dart
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
  "updatedAt": "serverTimestamp"
}
```

Purpose:
- user identity
- display name
- avatar
- basic profile

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
  "joinedAt": "serverTimestamp"
}
```

Roles:
- creator
- member

Purpose:
- permission checking
- member list
- Circle access

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

## Firebase Storage Paths

```txt
users/{userId}/avatar.jpg

circles/{circleId}/cover.jpg

circles/{circleId}/messages/{messageId}.jpg

circles/{circleId}/pulses/{dateKey}_{userId}.jpg
```

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
                    |-- Members
                    |-- Create Pulse
                    |-- Pulse Wall
                    |-- Create Plan
                    |-- Plan Detail
```

## Routing

Recommended routes:

```txt
/sign-in
/sign-up
/profile/edit
/home
/circles/create
/circles/join
/circles/:circleId
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
```

### Circle Providers

```txt
circleRepositoryProvider
userCirclesProvider
circleProvider(circleId)
circleMembersProvider(circleId)
```

### Message Providers

```txt
messageRepositoryProvider
circleMessagesProvider(circleId)
messageControllerProvider
```

### Pulse Providers

```txt
pulseRepositoryProvider
todayPulsesProvider(circleId)
myTodayPulseProvider(circleId)
pulseProgressProvider(circleId)
pulseControllerProvider
```

### Plan Providers

```txt
planRepositoryProvider
activePlansProvider(circleId)
planProvider(planId)
planResponsesProvider(planId)
planControllerProvider
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
- query circles by inviteCode
- prevent duplicate code if possible

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

Possible user document addition:

```json
{
  "fcmTokens": {
    "tokenValue": true
  }
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
- users can only post as themselves
- users can only create/update their own Pulse
- users can only create/update their own Plan response

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
