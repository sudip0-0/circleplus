# agents.md

## Purpose

This file gives Codex clear operating instructions for building the CirclePulse Flutter app.

Use this file as the project behavior guide. All implementation decisions should protect the core product idea:

> private small-group connection, not public social media.

## Codex Role

You are the senior Flutter engineer and product-minded implementation agent for this project.

Your job is to:
- understand the app concept
- preserve the MVP scope
- write clean Flutter code
- keep Firebase integration isolated behind repositories/services
- avoid adding unnecessary features
- update progress.md after meaningful work
- keep architecture.md aligned with the real codebase

## Project Context

CirclePulse is a Flutter mobile app where users create private groups called Circles, invite friends, chat, share photos, post daily photo updates called Pulses, and create meetup plans with simple voting.

This app has:
- no public feed
- no followers
- no explore page
- no random friend requests
- no influencer-style metrics

## Engineering Priorities

In order:

1. Working MVP
2. Clean project structure
3. Good user experience
4. Simple maintainable Firebase architecture
5. Clear documentation
6. Tests for important logic

Do not over-engineer the MVP.

## Preferred Technical Stack

Use:

- Flutter
- Dart
- Firebase Auth
- Cloud Firestore
- Cloudflare R2 for media storage through backend-generated presigned URLs
- Riverpod
- GoRouter
- Material 3

Optional but acceptable:
- Freezed
- json_serializable
- cached_network_image
- image_picker
- intl
- uuid

Do not add heavy dependencies without a strong reason.

## Folder Structure

Use this structure unless the existing project already has a better consistent structure:

```txt
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
  core/
    constants/
    errors/
    utils/
    widgets/
  features/
    auth/
      data/
      domain/
      presentation/
    profile/
      data/
      domain/
      presentation/
    circles/
      data/
      domain/
      presentation/
    messages/
      data/
      domain/
      presentation/
    pulses/
      data/
      domain/
      presentation/
    plans/
      data/
      domain/
      presentation/
```

Each feature should contain:
- models/entities in `domain/`
- repository interfaces in `domain/`
- Firebase implementation in `data/`
- screens/widgets/controllers/providers in `presentation/`

If this is too heavy during early MVP, keep the same intent but simplify sensibly.

## Naming Rules

Use product names consistently:

- Circle = group
- Pulse = daily photo update
- Plan = event/meetup proposal

Use code names like:
- CircleModel
- CircleRepository
- CreateCircleScreen
- CircleRoomScreen
- PulseModel
- TodayPulseCard
- PlanModel
- PlanResponseModel

Avoid generic names like:
- GroupThing
- EventStuff
- ChatData

## Data Model Rules

Every persisted model should have:
- id
- createdAt
- updatedAt where relevant
- createdBy where relevant
- fromMap/toMap or generated serialization

Use Firestore Timestamp handling carefully.

Prefer immutable models.

## Firebase And Storage Rules

Keep direct Firebase calls out of widgets.

Correct:
- Widget uses provider/controller
- Controller uses repository
- Repository uses Firebase service

Incorrect:
- Widget directly calls FirebaseFirestore.instance

Do not put Cloudflare R2 credentials in the Flutter app. Media uploads must go
through a backend or serverless endpoint that returns presigned upload URLs.

## State Management Rules

Use Riverpod.

Recommended:
- authStateProvider
- currentUserProvider
- userCirclesProvider
- circleMessagesProvider(circleId)
- todayPulsesProvider(circleId)
- activePlansProvider(circleId)
- planResponsesProvider(planId)

Async states must handle:
- loading
- error
- empty
- data

## UX Rules

Every main screen needs:
- loading state
- error state
- empty state
- primary action

The app should never show a blank page without explanation.

## MVP Feature Rules

### Auth

Implement:
- email/password signup
- email/password login
- logout
- auth state routing

After signup, create a user document in Firestore.

### Circles

Implement:
- create Circle
- join Circle by invite code
- list my Circles
- member list
- creator role
- member role

Invite code should be unique enough for MVP.

### Messages

Implement:
- text message
- photo message
- chronological real-time list
- sender metadata
- message timestamp
- basic reactions later only if the MVP foundation is complete

### Pulses

Implement:
- post one Pulse per Circle per day
- photo required
- caption optional
- mood optional
- show today’s Pulse progress
- show today’s Pulse wall

Daily key format:
```txt
yyyyMMdd_userId
```

### Plans

Implement:
- create Plan
- date/time
- optional location
- simple responses: in, maybe, cant
- response counts
- member response list

## Security Expectations

Firestore Security Rules should enforce:
- users can read/write their own user profile
- Circle members can read Circle data
- only Circle members can read/write messages
- only Circle members can read/write Pulses
- only Circle members can read/write Plans/responses
- non-members cannot access private Circle content

If rules are not implemented yet, mark clearly in progress.md.

## Testing Expectations

Start with practical tests:
- model serialization tests
- invite code validation test
- date key generation test for Pulse
- Plan response aggregation test
- repository tests if Firebase emulator is configured

Do not block MVP on exhaustive tests.

## Documentation Rules

Update:
- progress.md after each major feature
- architecture.md when structure changes
- readme.md when setup steps change

Do not leave documentation stale.

## Git Commit Style

Use clear commit messages:

```txt
feat(auth): add email signup and login
feat(circles): create and join circles
feat(pulses): add daily pulse posting
feat(plans): add meetup voting
fix(messages): handle empty message list
docs: update architecture and progress
```

## Forbidden Scope Creep

Do not add unless explicitly requested:
- public feed
- algorithmic ranking
- follower system
- creator accounts
- monetization
- ads
- public search
- direct messages outside Circles
- stories outside Circles
- advanced calendar integration
- video calls
- AI recommendations

## When Unsure

Choose the simpler option that helps users:
- connect with real friends
- share real daily updates
- make plans together
- avoid endless scrolling

## Final MVP Success Criteria

The app is successful when a small group of friends can use it for one week and naturally:

- check what each other is doing
- post daily photo updates
- chat inside the group
- create plans to meet
- respond to plans
- feel closer without needing a feed
