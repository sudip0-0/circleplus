# progress.md

## Project

CirclePulse

## Current Stage

Phase 4 in progress. Firebase initialization, Riverpod app scope, GoRouter routing, Authentication, Profile, Circles, bounded text/photo Messages, Pulse structure/wall/Home progress, lightweight Plans, local Firestore rules, private invite-code lookup, a Cloudflare Worker R2 upload signer scaffold, media upload wiring, avatar upload, and notification-ready FCM token storage are in place. Current work is focused on deployment readiness and a two-user MVP smoke test.

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
- [x] Add backend/serverless scaffold for R2 presigned uploads
- [ ] Deploy configured R2 presigned upload endpoint
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
- [x] Add avatar upload
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
- [x] Bound message stream to latest messages for MVP
- [x] Implement message composer
- [x] Implement message list
- [x] Implement photo message upload
- [x] Update Circle lastMessage fields
- [x] Add empty message state

### 6. Pulses

- [x] Create Pulse model
- [x] Create PulseRepository
- [x] Create date key utility
- [x] Implement one Pulse per user per Circle per day
- [x] Implement photo upload for Pulse
- [x] Implement optional caption
- [x] Implement optional mood
- [x] Build Today Pulse Card
- [x] Build Create Pulse Screen
- [x] Build Pulse Wall Screen
- [x] Show Pulse progress on Home Screen
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

- [x] Request notification permission
- [x] Store FCM token
- [x] Create placeholder notification service/repository abstractions
- [ ] Prepare notification event types
- [ ] Add placeholder for future Cloud Functions

### 9. Firebase Security

- [x] Write Firestore rules
- [x] Ensure only authenticated users can access app data
- [x] Ensure only Circle members can read Circle content
- [x] Ensure only Circle members can write messages
- [x] Ensure users can only write their own Pulse
- [x] Ensure users can only write their own Plan response
- [x] Require invite-code proof when creating non-creator Circle membership
- [x] Prevent member-count increments outside invite-backed join commits
- [x] Require Plan response counts to match response changes
- [x] Protect R2 uploads through backend-generated presigned URLs
- [x] Require Circle membership before signing Circle media uploads
- [x] Confirm Firestore rules compile with Firebase CLI dry run
- [ ] Test basic access manually

Firestore rules are configured locally in `firestore.rules` and referenced from `firebase.json`. They still need to be deployed and manually smoke-tested against the Firebase project.

Firestore indexes are configured locally in `firestore.indexes.json`. The Home screen requires the collection-group index on `members.userId` for `collectionGroup('members').where('userId', ...)`.

### 10. Tests

- [x] Test Pulse date key generation
- [x] Test invite code format
- [x] Test model serialization
- [x] Test media upload metadata helpers
- [x] Test Plan response aggregation logic
- [ ] Test auth routing logic

### 11. UI Polish

- [ ] Add consistent spacing
- [ ] Add reusable button
- [ ] Add reusable text field
- [x] Add EmptyState widget
- [x] Add LoadingView widget
- [x] Add ErrorView widget
- [x] Add CircleCard widget
- [x] Add Avatar widget
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
- Photo uploads require the backend/serverless presigned URL endpoint to be deployed before manual testing.
- Authentication starts with email/password.
- Groups are private by default.
- Invite is by code in MVP.
- Every user can create multiple Circles.
- Every Circle can have multiple members.
- Every member can post one Pulse per day per Circle.
- Every member can create Plans.
- Every member can vote on Plans.

## Manual Smoke Test Checklist

Run this after deploying Firestore rules, Firestore indexes, and the Cloudflare
Worker upload signer, then launching Flutter with `R2_UPLOAD_SIGNER_URL`.

- [ ] User A can sign up
- [ ] User A can complete profile setup
- [ ] User A can create a Circle
- [ ] User B can sign up and complete profile setup
- [ ] User B can join User A's Circle by invite code
- [ ] User B cannot join a Circle by writing only a known `circleId`
- [ ] Circle members can send and receive a real-time text message
- [ ] Circle members can send and view a photo message
- [ ] Circle members can upload today's Pulse
- [ ] Circle members can view today's Pulse wall
- [ ] Home shows truthful Pulse progress for each Circle
- [ ] A user can upload and see a profile avatar
- [ ] Notification permission can be requested and an FCM token is stored when available
- [ ] Circle members can create a Plan
- [ ] Circle members can respond to a Plan and see counts update
- [ ] A member cannot directly manipulate Plan response counts without a matching response write
- [ ] A signed-in non-member cannot read Circle messages, Pulses, Plans, or sign Circle media uploads

Manual security checks still required because this repo does not yet include a
Firebase Emulator rules test harness:

- [ ] Signed-out reads to `users`, `circles`, Circle subcollections, and `inviteCodes` are denied
- [ ] Signed-in exact `get` to a valid `inviteCodes/{code}` works, but list/query is denied
- [ ] Signed-in non-member cannot create `circles/{circleId}/members/{uid}` without `inviteCodeUsed`
- [ ] Signed-in non-member cannot read or write Circle messages, Pulses, Plans, or responses
- [ ] Plan count-only writes are denied unless paired with the current user's response write
- [ ] R2 signer denies Circle media signing for signed-in non-members

## Next Step

Continue MVP implementation:

1. deploy Firestore rules, Firestore indexes, and the Cloudflare Worker upload signer
2. run the two-user smoke checklist above, including Pulse and message photo upload
3. polish Circle Room/Home layout after real-device testing
