# CirclePulse

CirclePulse is a Flutter mobile app for private friend groups.

Users create private Circles, invite real friends, chat, share photos, post daily photo check-ins called Pulses, and start lightweight meetup Plans where friends can respond with “I’m in”, “Maybe”, or “Can’t”.

The goal is simple:

> less scrolling, more real connection.

## Product Concept

CirclePulse is not a public social network.

It has:
- no public feed
- no followers
- no explore page
- no influencer features
- no endless scrolling

It is built around private groups where people actually know each other.

## Core Features

### Circles

Private groups for real friends.

Users can:
- create a Circle
- invite friends with a code
- join a Circle
- see members
- chat inside the Circle

### Messages

Group chat inside each Circle.

MVP supports:
- text messages
- photo messages
- real-time updates

### Pulses

A Pulse is a daily photo update inside a Circle.

Users can:
- post one daily Pulse per Circle
- add a short caption
- add an optional mood
- see who posted today
- view today’s group Pulse wall

### Plans

A Plan is a lightweight meetup proposal.

Example:

> “Let’s meet Saturday at 7 PM.”

Members can respond:
- I’m in
- Maybe
- Can’t

## Recommended Tech Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Cloudflare R2 for media storage
- Firebase Cloud Messaging-ready structure
- Riverpod
- GoRouter
- Material 3

## Project Files

Important planning files:

```txt
prompt.md
agents.md
architecture.md
readme.md
progress.md
```

Purpose:

- `prompt.md` gives the main build prompt and product scope.
- `agents.md` gives Codex engineering behavior rules.
- `architecture.md` explains the app structure and backend design.
- `readme.md` explains the app for developers.
- `progress.md` tracks implementation status.

## Suggested Flutter Project Setup

Create a new Flutter app:

```bash
flutter create circlepulse
cd circlepulse
```

Add dependencies:

```bash
flutter pub add firebase_core firebase_auth cloud_firestore firebase_messaging
flutter pub add flutter_riverpod go_router image_picker intl uuid cached_network_image
```

Current MVP storage decision:

- Use Cloudflare R2 instead of Firebase Storage.
- Do not put R2 access keys in the Flutter app.
- Keep R2 credentials in `.env` for backend/serverless work only.
- Add a backend or serverless endpoint later to create presigned upload URLs.
- Store media object keys or URLs in Firestore after upload.

Optional dependencies:

```bash
flutter pub add freezed_annotation json_annotation
flutter pub add --dev build_runner freezed json_serializable
```

## Firebase Setup

Install FlutterFire CLI if needed:

```bash
dart pub global activate flutterfire_cli
```

Configure Firebase:

```bash
flutterfire configure
```

Deploy Firestore rules after reviewing them:

```bash
firebase deploy --only firestore:rules
```

Initialize Firebase in `main.dart`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Firebase Storage is not required for the current setup because media storage is
planned for Cloudflare R2.

## Recommended Folder Structure

```txt
lib/
  main.dart
  app/
  core/
  features/
    auth/
    profile/
    circles/
    messages/
    pulses/
    plans/
    notifications/
```

See `architecture.md` for the full detailed structure.

## MVP Build Order

1. Flutter project setup
2. Firebase setup
3. App theme and router
4. Authentication
5. User profile document
6. Circle creation
7. Circle joining by invite code
8. Home screen with user Circles
9. Circle room screen
10. Text messages
11. Photo messages
12. Daily Pulse posting
13. Pulse wall
14. Plan creation
15. Plan responses
16. Notification-ready structure
17. Security rules
18. Basic tests
19. UI polish

## Main User Flow

```txt
User opens app
  |
  |-- signs up or logs in
  |
  |-- creates profile
  |
  |-- creates or joins Circle
  |
  |-- opens Circle Room
  |
  |-- chats with friends
  |
  |-- posts today’s Pulse
  |
  |-- starts a Plan
  |
  |-- friends respond
```

## Firebase Collections

```txt
users/{userId}

circles/{circleId}

inviteCodes/{inviteCode}

circles/{circleId}/members/{userId}

circles/{circleId}/messages/{messageId}

circles/{circleId}/pulses/{yyyyMMdd_userId}

circles/{circleId}/plans/{planId}

circles/{circleId}/plans/{planId}/responses/{userId}
```

## Development Rule

Before adding any feature, ask:

> Does this help close friends stay connected or meet?

If not, do not add it to the MVP.

## Definition of Done

The first MVP is complete when:

- a user can create an account
- a user can create a Circle
- a user can invite another person
- a user can join by invite code
- Circle members can send messages
- Circle members can send photo messages
- Circle members can post today’s Pulse
- Circle members can view today’s Pulses
- Circle members can create a Plan
- Circle members can vote on a Plan

## Future Features

Only after the MVP works:

- group memories
- weekly recap
- voice notes
- richer reactions
- dynamic invite links
- push notifications through Cloud Functions
- plan reminders
- calendar export
- polls for choosing meeting time
- private photo albums
- offline mode
