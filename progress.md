# progress.md

## Project

CirclePulse

## Current Stage

Phase 1 started. Initial Flutter app shell and clean folder structure are in place.

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
- [ ] Add Firebase dependencies
- [ ] Add Riverpod
- [ ] Add GoRouter
- [ ] Add image picker
- [ ] Add Firebase config
- [x] Create folder structure
- [x] Add app theme
- [x] Add router shell

### 2. Authentication

- [ ] Create AuthRepository interface
- [ ] Create FirebaseAuthRepository
- [ ] Build sign up screen
- [ ] Build sign in screen
- [ ] Add logout
- [ ] Add auth state provider
- [ ] Add auth-based routing
- [ ] Create Firestore user document after signup

### 3. Profile

- [ ] Create AppUser model
- [ ] Create ProfileRepository
- [ ] Build edit profile screen
- [ ] Add avatar upload
- [ ] Add display name validation
- [ ] Route user to profile setup if missing

### 4. Circles

- [ ] Create Circle model
- [ ] Create CircleMember model
- [ ] Create CircleRepository
- [ ] Implement create Circle
- [ ] Generate invite code
- [ ] Implement join by invite code
- [ ] Implement list my Circles
- [ ] Implement member list
- [ ] Build Home Screen
- [ ] Build Create Circle Screen
- [ ] Build Join Circle Screen
- [ ] Build Circle Room Screen

### 5. Messages

- [ ] Create Message model
- [ ] Create MessageRepository
- [ ] Implement text messages
- [ ] Implement real-time message stream
- [ ] Implement message composer
- [ ] Implement message list
- [ ] Implement photo message upload
- [ ] Update Circle lastMessage fields
- [ ] Add empty message state

### 6. Pulses

- [ ] Create Pulse model
- [ ] Create PulseRepository
- [ ] Create date key utility
- [ ] Implement one Pulse per user per Circle per day
- [ ] Implement photo upload for Pulse
- [ ] Implement optional caption
- [ ] Implement optional mood
- [ ] Build Today Pulse Card
- [ ] Build Create Pulse Screen
- [ ] Build Pulse Wall Screen
- [ ] Show Pulse progress on Home Screen
- [ ] Show Pulse progress inside Circle Room

### 7. Plans

- [ ] Create Plan model
- [ ] Create PlanResponse model
- [ ] Create PlanRepository
- [ ] Implement create Plan
- [ ] Implement response voting
- [ ] Implement response count updates
- [ ] Build Plan Card
- [ ] Build Create Plan Screen
- [ ] Build Plan Detail Screen
- [ ] Add empty Plans state

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
- [ ] Write Firebase Storage rules
- [ ] Test basic access manually

### 10. Tests

- [ ] Test Pulse date key generation
- [ ] Test invite code format
- [ ] Test model serialization
- [ ] Test Plan response aggregation logic
- [ ] Test auth routing logic

### 11. UI Polish

- [ ] Add consistent spacing
- [ ] Add reusable button
- [ ] Add reusable text field
- [ ] Add EmptyState widget
- [ ] Add LoadingView widget
- [ ] Add ErrorView widget
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
- Authentication starts with email/password.
- Groups are private by default.
- Invite is by code in MVP.
- Every user can create multiple Circles.
- Every Circle can have multiple members.
- Every member can post one Pulse per day per Circle.
- Every member can create Plans.
- Every member can vote on Plans.

## Next Step

Continue Phase 1 setup:

1. add Firebase dependencies
2. add Riverpod
3. add GoRouter
4. add image picker
5. configure Firebase
6. wire router to GoRouter
7. implement auth flow first
