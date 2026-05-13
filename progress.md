# progress.md

## Project

CirclePulse

## Current Stage

Phase 3 in progress. Firebase initialization, Riverpod app scope, GoRouter routing, Authentication, Profile, Circles, text Messages, Pulse structure/wall, and lightweight Plans are in place. Cloudflare R2 remains documented as the media storage provider, and photo uploads are intentionally blocked until a backend presigned URL endpoint exists.

## Product Summary

CirclePulse is a Flutter mobile app for private friend groups. Users create Circles, invite friends, chat, share photos, post daily photo updates called Pulses, and create meetup Plans with simple voting.

## MVP Status

### 0. Planning

- [x] App idea defined
- [x] Core product direction defined
- [x] MVP scope defined
- [x] Technical stack selected
- [x] Firebase architecture drafted
- [x] Required Codex files created

### 1. Project Setup

- [x] Create Flutter project
- [x] Add Firebase dependencies
- [x] Add Riverpod
- [x] Add GoRouter
- [x] Add image picker
- [x] Add Intl
- [x] Add Firebase config
- [x] Confirm Cloudflare R2 as media storage provider
- [ ] Add backend/serverless endpoint for R2 presigned uploads
- [x] Create folder structure
- [x] Add app theme
- [x] Add router shell
- [x] Initialize Firebase in app entry
- [x] Add Riverpod ProviderScope
- [x] Wire router shell to GoRouter

### 2. Authentication

- [x] Create AuthRepository interface
- [x] Create FirebaseAuthRepository
- [x] Build sign up screen
- [x] Build sign in screen
- [x] Add logout
- [x] Add auth state provider
- [x] Add auth-based routing
- [x] Create Firestore user document after signup

### 3. Profile

- [x] Create AppUser model
- [x] Create ProfileRepository
- [x] Build edit profile screen
- [ ] Add avatar upload
- [x] Add display name validation
- [x] Route user to profile setup if missing

### 4. Circles

- [x] Create Circle model
- [x] Create CircleMember model
- [x] Create CircleRepository
- [x] Implement create Circle
- [x] Generate invite code
- [x] Implement join by invite code
- [x] Implement list my Circles
- [x] Implement member list
- [x] Build Home Screen
- [x] Build Create Circle Screen
- [x] Build Join Circle Screen
- [x] Build Circle Room Screen

### 5. Messages

- [x] Create Message model
- [x] Create MessageRepository
- [x] Implement text messages
- [x] Implement real-time message stream
- [x] Implement message composer
- [x] Implement message list
- [ ] Implement photo message upload
- [x] Update Circle lastMessage fields
- [x] Add empty message state

### 6. Pulses

- [x] Create Pulse model
- [x] Create PulseRepository
- [x] Create date key utility
- [x] Implement one Pulse per user per Circle per day
- [ ] Implement photo upload for Pulse
- [x] Implement optional caption
- [x] Implement optional mood
- [x] Build Today Pulse Card
- [x] Build Create Pulse Screen
- [x] Build Pulse Wall Screen
- [ ] Show Pulse progress on Home Screen
- [x] Show Pulse progress inside Circle Room

### 7. Plans

- [x] Create Plan model
- [x] Create PlanResponse model
- [x] Create PlanRepository
- [x] Implement create Plan
- [x] Implement response voting
- [x] Implement response count updates
- [x] Build Plan Card
- [x] Build Create Plan Screen
- [x] Build Plan Detail Screen
- [x] Add empty Plans state

### 8. Notifications

- [ ] Request notification permission
- [ ] Store FCM token
- [ ] Create notification service abstraction
- [ ] Prepare notification event types
- [ ] Add placeholder for future Cloud Functions

### 9. Firebase Security

- [ ] Write Firestore rules
- [ ] Ensure only authenticated users can access app data
- [ ] Ensure only Circle members can read Circle content
- [ ] Ensure only Circle members can write messages
- [ ] Ensure users can only write their own Pulse
- [ ] Ensure users can only write their own Plan response
- [ ] Protect R2 uploads through backend-generated presigned URLs
- [ ] Test basic access manually

No Firestore rules file is currently configured in the repo. Membership-based rules remain a required next step before production use.

### 10. Tests

- [x] Test Pulse date key generation
- [x] Test invite code format
- [x] Test model serialization
- [x] Test Plan response aggregation logic
- [ ] Test auth routing logic

### 11. UI Polish

- [ ] Add consistent spacing
- [ ] Add reusable button
- [ ] Add reusable text field
- [x] Add EmptyState widget
- [x] Add LoadingView widget
- [x] Add ErrorView widget
- [ ] Add CircleCard widget
- [ ] Add Avatar widget
- [ ] Add responsive layout checks
- [ ] Add friendly copywriting

## Priority Backlog

### P0: Required for MVP

- Auth
- Create/join Circles
- Group chat
- Daily Pulse
- Plan voting
- Firebase security rules

### P1: Important but after core MVP

- Photo compression
- Push notifications through Cloud Functions
- Better invite links
- Reactions
- Group cover images
- Profile avatars
- Message pagination

### P2: Later

- Weekly memories
- Calendar export
- Polls for choosing meetup time
- Voice notes
- Group albums
- Offline mode
- Advanced privacy settings

## Known Product Decisions

### Decision: No public feed

Reason:
The app is about private friendship, not content consumption.

### Decision: No friend request system in MVP

Reason:
Invite codes are simpler and more aligned with private groups.

### Decision: Circle-first architecture

Reason:
All meaningful activity happens inside groups.

### Decision: Pulse is inside each Circle

Reason:
A user may have different friend groups and should be able to share different updates to different Circles.

### Decision: Plans are lightweight

Reason:
The app should help friends meet without becoming a calendar app.

## Open Questions

These do not block MVP:

1. Should Pulse posting unlock viewing other members’ Pulses?
2. Should invite codes expire?
3. Should Circle creators be able to remove members?
4. Should Plans support multiple suggested times in MVP?
5. Should a user be allowed to post the same Pulse to multiple Circles?
6. Should photo messages and Pulse photos have retention limits?
7. Should users be able to delete messages?

## Current Assumptions

- The app will use Firebase for MVP.
- Media files will use Cloudflare R2, not Firebase Storage.
- R2 credentials are kept out of Flutter and ignored through `.env`.
- Photo uploads require a backend/serverless presigned URL endpoint before implementation.
- Authentication starts with email/password.
- Groups are private by default.
- Invite is by code in MVP.
- Every user can create multiple Circles.
- Every Circle can have multiple members.
- Every member can post one Pulse per day per Circle.
- Every member can create Plans.
- Every member can vote on Plans.

## Next Step

Continue MVP implementation:

1. add Firestore security rules for users and Circle membership
2. add the backend/serverless presigned upload endpoint for R2 before enabling photo messages or Pulse posting
3. implement notifications-ready FCM token storage when security rules are in place
