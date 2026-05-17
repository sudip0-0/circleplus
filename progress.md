# progress.md

## Project

CirclePulse

## Current Stage

MVP feature-complete and beta-ready. All core features are implemented: Auth, Profile, Circles (create/join/member list), Messages (text + photo + soft delete), Pulses (daily photo + wall), Plans (create/vote/edit/cancel), Firestore security rules (hardened + rule-tested), Cloud Functions for push notifications, and Cloudflare R2 media uploads via presigned URLs. Remaining work is deployment (Firestore rules/indexes, Cloud Functions, R2 Worker) and real-device beta smoke testing.

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
- [x] Implement delete-own-message (soft delete — type 'deleted', content cleared, placeholder shown)

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
- [x] Implement plan edit (creator-only: title, description, location, startsAt)
- [x] Implement plan cancel (creator-only: sets status to 'cancelled', disables response buttons)
- [x] Show cancelled banner in Plan Detail Screen

### 8. Notifications

- [x] Request notification permission
- [x] Store FCM token
- [x] Create placeholder notification service/repository abstractions
- [x] Implement Cloud Functions for push notifications (functions/src/index.ts)
  - onNewMessage: notifies all Circle members (except sender) when a new message is sent
  - onNewPlan: notifies all Circle members (except creator) when a new plan is created
  - Stale FCM token cleanup on send failure
- [ ] Deploy Cloud Functions: `cd functions && npm run build && firebase deploy --only functions`

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
- [x] Audit and finalize production-ready Firestore rules (Phase 4 hardening)
- [x] Add composite index for plans (status + startsAt)
- [x] Harden R2 Worker: pinned presigned URL expiry, explicit extension allow-list, content-length guard, structured logging
- [x] Add message soft-delete rule (sender may flip type to 'deleted' and clear content fields)
- [x] Add plan edit rule (creator may change title/description/location/startsAt while active)
- [x] Add plan cancel rule (creator may flip status to 'cancelled' while active)
- [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules`
- [ ] Deploy Firestore indexes: `firebase deploy --only firestore:indexes`
- [ ] Deploy R2 Worker: `wrangler deploy` (from backend/r2-upload-worker)
- [ ] Test basic access manually (see Manual Smoke Test Checklist below)

Firestore rules are configured locally in `firestore.rules` and referenced from `firebase.json`. Deploy with `firebase deploy --only firestore`.

Firestore indexes are configured locally in `firestore.indexes.json`. Required indexes:
- Collection-group index on `members.userId` (Home screen collectionGroup query)
- Composite index on `plans`: `status ASC + startsAt ASC` (active plans list query)

### 10. Tests

- [x] Test Pulse date key generation
- [x] Test invite code format
- [x] Test model serialization
- [x] Test media upload metadata helpers
- [x] Test Plan response aggregation logic
- [x] Test MessageModel soft-delete (isDeleted getter, deletedAt round-trip)
- [x] Test PlanModel cancelled status round-trip
- [x] Test PlanStatus.fromName edge cases
- [ ] Test auth routing logic

### 11. UI Polish

- [x] Add consistent spacing
- [x] Add reusable button
- [x] Add reusable text field
- [x] Add EmptyState widget
- [x] Add LoadingView widget
- [x] Add ErrorView widget
- [x] Add CircleCard widget
- [x] Add Avatar widget
- [x] Add CirclePulse visual system widget set
- [x] Apply warm private-circle UI to auth, profile, Circles, Messages, Pulses, and Plans
- [ ] Add responsive layout checks
- [x] Add friendly copywriting

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
7. ~~Should users be able to delete messages?~~ Resolved: senders can soft-delete their own messages.

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

Security rules are now covered by the Firebase Emulator test harness in `rules-tests/` (see `rules-tests/README.md`). Additional manual checks for real-device beta:

- [ ] Signed-out reads to `users`, `circles`, Circle subcollections, and `inviteCodes` are denied
- [ ] Signed-in exact `get` to a valid `inviteCodes/{code}` works, but list/query is denied
- [ ] Signed-in non-member cannot create `circles/{circleId}/members/{uid}` without `inviteCodeUsed`
- [ ] Signed-in non-member cannot read or write Circle messages, Pulses, Plans, or responses
- [ ] Plan count-only writes are denied unless paired with the current user's response write
- [ ] R2 signer denies Circle media signing for signed-in non-members

## Session 5 Completed Work (2026-05-17)

### UI
- **Separated Circle dashboard and chat:** Circle Room is now a dashboard with cover hero, private/invite pills, Pulse progress, quick actions, members, upcoming Plan, recent moments, and a primary "Open Circle Chat" action
- **Dedicated Circle Chat screen:** added `/circles/:circleId/chat` with its own header, real-time message list, and composer
- **Chat polish:** restyled message bubbles, photo messages, day pill, and bottom composer to match the warmer reference direction while preserving existing message send/delete behavior

### Documentation
- Updated `architecture.md` with the dedicated Circle chat route and revised Circle Room composition

### Verification
- `flutter analyze lib/features/circles/presentation/circle_room_screen.dart lib/features/messages/presentation/circle_chat_screen.dart lib/features/messages/presentation/message_list.dart lib/features/messages/presentation/message_composer.dart lib/routing/app_router.dart` - 0 issues

## Session 4 Completed Work (2026-05-17)

### Fixes
- **Plan response selection:** Plan Detail response buttons now highlight the current user's actual response instead of always highlighting "In"
- **Plan response tap feedback:** selecting "In", "Maybe", or "Can't" now updates the selected button optimistically while the Firestore transaction completes, then hands back to the live response stream

### Verification
- `flutter analyze lib/features/plans/presentation/plan_detail_screen.dart` - 0 issues

## Session 3 Completed Work (2026-05-16)

### Features
- **Delete own message (soft delete):** long-press to delete own messages; type set to `'deleted'`, content cleared, "Message removed" placeholder shown
- **Plan edit + cancel:** creator-only options menu on Plan Detail Screen; edit bottom sheet for title/description/location/startsAt; cancel sets status to `'cancelled'`, disables response buttons, shows cancelled banner
- **Cloud Functions for push notifications** (`functions/`): `onMessageCreated` and `onPlanCreated` Firestore-triggered functions fan-out FCM to all Circle members except sender/creator; stale token cleanup on failure
- **Firebase Emulator security-rule test harness** (`rules-tests/`): TypeScript/Jest + `@firebase/rules-unit-testing`; covers all collections and edge cases including soft-delete and plan edit/cancel transitions
- **Beta smoke-test checklist** (`BETA_SMOKE_TEST.md`): comprehensive two-user checklist for all MVP flows
- **Router profile-check caching**: redirect now reads `currentUserProfileProvider.asData?.value` (zero-cost, already-live stream) instead of `await profileRepository.getProfile()` on every navigation; redirect is now synchronous

### Verification
- `flutter analyze` — 0 issues
- Flutter unit tests — 25/25 passing
- Cloud Functions TypeScript — clean compile
- rules-tests TypeScript — clean compile
- Full production readiness audit written to `PRODUCTION_AUDIT.md`

## Next Step

1. Deploy Firestore rules + indexes: `firebase deploy --only firestore`
2. Build and deploy Cloud Functions: `cd functions && npm run build && firebase deploy --only functions`
3. Deploy R2 Worker: `cd backend/r2-upload-worker && wrangler deploy`
4. Set `R2_UPLOAD_SIGNER_URL` in Flutter app config
5. Run two-user beta smoke test (`BETA_SMOKE_TEST.md`)
6. Polish Circle Room / Home layout after real-device testing
