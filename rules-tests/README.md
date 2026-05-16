# CirclePlus – Firestore Security Rules Tests

Automated test harness for all Firestore security rules using
`@firebase/rules-unit-testing` and Jest.

## Requirements

- Node ≥ 18
- Java 11+ (required by the Firebase Emulator)
- Firebase CLI: `npm install -g firebase-tools`

## Setup

```bash
# From project root
cd rules-tests
npm install
```

## Running Tests

### Option A — One-shot (emulator starts, tests run, emulator stops)

```bash
# From the project root
firebase emulators:exec --only firestore "cd rules-tests && npm test"
```

### Option B — Development (emulator stays running)

Terminal 1:
```bash
# From project root
firebase emulators:start --only firestore
```

Terminal 2:
```bash
cd rules-tests
npm test
# or
npm run test:watch
```

## Test Coverage

| Suite | Scenarios |
|---|---|
| User profile rules | Owner CRUD, cross-user deny, unauthenticated deny, email immutability |
| Invite code rules | Read by auth'd user, listing denied, immutability |
| Circle access – non-member denied | Read circle, read members, read messages, read pulses, read plans |
| Circle access – member allowed | Creator read, member read, member list |
| Circle create rules | Unauthenticated deny, wrong memberCount, spoofed creator |
| Circle join – valid & invalid | Valid join, no invite code, wrong code, join as creator, write another's doc, immutable update |
| Message rules | Member read, non-member deny, send text, empty text deny, senderId spoof, deleted type on create, soft-delete own, non-sender deny, hard-delete deny, non-member write deny |
| Pulse rules (write as self only) | Member read, non-member deny, correct id format, wrong userId in id, no photoUrl, own delete, another's delete |
| Plan rules | Member read, non-member deny, valid create, pre-inflated counts, cancelled status on create, non-member create, creator cancel, non-creator cancel, creator edit, non-creator edit, delete deny |
| Plan response + atomic counts | Member read, non-member deny, atomic batch response+count, direct count inflation, another user's response, invalid response value, delete deny |
| Circle update rules | lastMessage fields, arbitrary field deny, non-member deny |
| Collection-group members | Own memberships query, cross-user query deny |

## Architecture Notes

- Each test suite gets its own isolated Firestore project ID (`circleplus-rules-test-<suite>`)
  to prevent cross-suite data contamination.
- Baseline data (Alice as creator, Bob as member, invite code) is seeded with
  `withSecurityRulesDisabled` so tests focus on rule behaviour, not seed operations.
- The rules file is loaded directly from `../firestore.rules` so tests always
  reflect the current state of the rules without a redeploy.
