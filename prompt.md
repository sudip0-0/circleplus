# prompt.md

## Project Codename

**CirclePulse**

## One-Sentence Product Definition

CirclePulse is a Flutter mobile app for private friend groups where people stay genuinely connected through group chat, daily photo check-ins, and lightweight meetup planning.

## Core Product Principle

This is **not** a public social network.

Do not build:
- public feed
- followers
- explore page
- public profiles
- influencer tools
- infinite scrolling discovery
- random friend requests

Build a private, intentional social app focused on small groups of real friends.

## Target User

People who already have real friend circles but feel disconnected because normal social media is noisy, performative, and feed-driven.

The user wants:
- a private space for close friends
- daily life updates without public pressure
- easy meetup planning
- group memories
- less scrolling, more real connection

## MVP Scope

Build the first usable MVP with these features only:

1. Authentication
2. User profile
3. Group creation
4. Group invite by code/link
5. Group member list
6. Group chat
7. Send text messages
8. Send photo messages
9. Daily photo check-in inside each group
10. Event planning card
11. Event response voting

## Recommended Stack

Use:

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Cloudflare R2 for media storage through backend-generated presigned URLs
- Riverpod for state management
- GoRouter for navigation
- Freezed/json_serializable for models if useful
- Clean Architecture-inspired folder structure

Avoid over-engineering. Keep the MVP simple and maintainable.

## Product Naming

Use the temporary name **CirclePulse** across code and documentation.

Core feature names:

- Group = **Circle**
- Daily update = **Pulse**
- Event planning = **Plan**

Example copy:

- “Create a Circle”
- “Share today’s Pulse”
- “Start a Plan”

## Main Screens

### 1. Auth Screens

Required:
- Sign in
- Sign up
- Basic validation
- Firebase Auth connection

Supported auth methods for MVP:
- Email/password

Optional later:
- Google sign-in
- Apple sign-in
- Phone sign-in

### 2. Home Screen

Shows all Circles the current user belongs to.

Each Circle card should show:
- circle name
- circle image or generated initials
- last message preview
- number of members
- today’s Pulse progress, for example `3/6 posted`
- next upcoming Plan if available

Primary actions:
- create Circle
- join Circle by invite code
- open Circle

### 3. Circle Room Screen

Main private group space.

Sections:
- top header with Circle name and members
- today’s Pulse module
- upcoming Plan card if exists
- message list
- message composer

The app should feel like a private room, not a noisy social feed.

### 4. Pulse Screen

Daily photo update screen.

User can:
- capture or upload photo
- add short caption
- add optional mood
- post to selected Circle for today

Rules:
- one Pulse per user per Circle per day
- user can update/replace today’s Pulse if needed
- Pulse is visible inside that Circle only
- no public sharing

Optional product mechanic:
- show a user the full Pulse wall after they post their own Pulse for the day

### 5. Plan/Event Screen

A Plan is a lightweight meetup proposal inside a Circle.

User can create:
- title
- date and time
- location
- description
- response options

Default responses:
- `in`
- `maybe`
- `cant`

Other members can:
- respond
- change response
- leave a short comment

## Data Model Requirements

Use clear typed models.

Minimum models:

- AppUser
- Circle
- CircleMember
- Message
- Pulse
- Plan
- PlanResponse

Use server timestamps where appropriate.

## Firestore Collection Design

Recommended structure:

```txt
users/{userId}

circles/{circleId}

circles/{circleId}/members/{userId}

circles/{circleId}/messages/{messageId}

circles/{circleId}/pulses/{yyyyMMdd_userId}

circles/{circleId}/plans/{planId}

circles/{circleId}/plans/{planId}/responses/{userId}
```

## Storage Design

Recommended Cloudflare R2 object paths:

```txt
users/{userId}/avatar.jpg

circles/{circleId}/cover.jpg

circles/{circleId}/messages/{messageId}.jpg

circles/{circleId}/pulses/{yyyyMMdd_userId}.jpg
```

Do not put R2 credentials in the Flutter app. Use a backend or serverless
endpoint to create presigned upload URLs, then store uploaded media object keys
or URLs in Firestore.

## UX Direction

The UI should be:
- calm
- modern
- private
- warm
- minimal
- not childish
- not corporate

Avoid looking like a clone of Instagram, TikTok, Snapchat, or Discord.

The app should feel like a private home for close friends.

## Suggested Visual Style

Use:
- soft background
- rounded cards
- generous spacing
- clear typography
- warm accent color
- minimal icons
- friendly empty states

Avoid:
- aggressive colors
- infinite content walls
- complex dashboards
- public vanity metrics

## Required Empty States

Build helpful empty states:

### No Circles

Message:
> “Create your first Circle and invite the people who matter.”

Actions:
- Create Circle
- Join with Code

### No Pulse Today

Message:
> “No one has shared today’s Pulse yet.”

Action:
- Share Pulse

### No Plans

Message:
> “Start a Plan and make the group actually meet.”

Action:
- Start Plan

### No Messages

Message:
> “Say something to get the Circle started.”

Action:
- focus message input

## Non-Negotiable Rules

1. Do not add a public feed.
2. Do not add follower counts.
3. Do not add like counts.
4. Do not add random user discovery.
5. Do not add complex social graph features before the MVP works.
6. Do not implement features without connecting them to the private-group concept.
7. Keep the first version small and functional.
8. Prefer simple working code over clever architecture.
9. Use strongly typed models.
10. Keep Firebase calls behind repositories/services.

## Implementation Order

Follow this order:

1. Create Flutter project structure
2. Configure dependencies
3. Set up routing
4. Set up Firebase initialization
5. Build auth flow
6. Build user profile creation
7. Build Circle model and repository
8. Build create/join Circle
9. Build Home Screen
10. Build Circle Room Screen
11. Build messages
12. Build photo upload
13. Build Pulse feature
14. Build Plan feature
15. Polish UI and empty states
16. Add basic tests

## Quality Bar

Code should be:
- readable
- modular
- typed
- easy to modify
- realistic for a solo developer
- not filled with placeholders
- not filled with fake TODOs unless they are listed in progress.md

## Definition of Done for MVP

The MVP is done when a user can:

1. Create an account
2. Create a Circle
3. Invite another user with a code
4. Join a Circle
5. Send messages in the Circle
6. Send photos in the Circle
7. Post today’s Pulse
8. View group Pulse updates
9. Create a Plan
10. Vote on a Plan
11. See responses from friends
