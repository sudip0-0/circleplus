# CirclePlus — Two-User Beta Smoke-Test Checklist

**Setup:** Two physical devices (or one device + one simulator).
Label them **Device A** (User Alice) and **Device B** (User Bob).
Use unique email addresses. Complete sections in order — later sections
depend on data created earlier.

---

## 0. Pre-flight

| # | Check | A | B |
|---|---|---|---|
| 0.1 | App installs and launches without crash | ☐ | ☐ |
| 0.2 | Splash/loading screen shown while checking auth state | ☐ | ☐ |
| 0.3 | Unauthenticated → redirected to Sign In screen | ☐ | ☐ |
| 0.4 | No blank white screen at any point during launch | ☐ | ☐ |

---

## 1. Authentication

### 1.1 Sign Up

| # | Check | A | B |
|---|---|---|---|
| 1.1.1 | Tap "Create account" → Sign Up screen opens | ☐ | ☐ |
| 1.1.2 | Submit with empty fields → validation errors shown | ☐ | ☐ |
| 1.1.3 | Submit with invalid email format → error shown | ☐ | ☐ |
| 1.1.4 | Submit with password < 6 chars → error shown | ☐ | ☐ |
| 1.1.5 | Valid sign-up with unique email → account created | ☐ | ☐ |
| 1.1.6 | After sign-up → redirected to Profile Setup screen | ☐ | ☐ |
| 1.1.7 | Duplicate email → friendly error message shown | ☐ | ☐ |

### 1.2 Sign In

| # | Check | A | B |
|---|---|---|---|
| 1.2.1 | Sign out and sign back in with correct credentials → success | ☐ | ☐ |
| 1.2.2 | Wrong password → error snackbar shown | ☐ | ☐ |
| 1.2.3 | Non-existent email → error shown (not a crash) | ☐ | ☐ |
| 1.2.4 | After sign-in → redirected to Home screen directly (profile already exists) | ☐ | ☐ |

### 1.3 Password Reset

| # | Check | A | B |
|---|---|---|---|
| 1.3.1 | Tap "Forgot password?" on Sign In screen → bottom sheet opens | ☐ | — |
| 1.3.2 | Email field pre-filled if email was already entered | ☐ | — |
| 1.3.3 | Submit valid email → success message shown in sheet | ☐ | — |
| 1.3.4 | Check inbox → password reset email received | ☐ | — |
| 1.3.5 | Submit empty email → validation error | ☐ | — |

### 1.4 Sign Out

| # | Check | A | B |
|---|---|---|---|
| 1.4.1 | Sign out from profile/settings → redirected to Sign In | ☐ | ☐ |
| 1.4.2 | Re-open app after sign-out → stays on Sign In (no auto-login) | ☐ | ☐ |

---

## 2. Profile Creation & Edit

| # | Check | A | B |
|---|---|---|---|
| 2.1 | After first sign-up → profile setup screen shown with display name field | ☐ | ☐ |
| 2.2 | Submit empty display name → validation error | ☐ | ☐ |
| 2.3 | Submit valid display name → profile saved, Home screen shown | ☐ | ☐ |
| 2.4 | Navigate to Profile / Edit Profile → current name shown | ☐ | ☐ |
| 2.5 | Change display name → tap Save → name updates immediately | ☐ | ☐ |
| 2.6 | Upload avatar photo → photo picker opens | ☐ | ☐ |
| 2.7 | Select photo → compression runs → photo uploaded to R2 | ☐ | ☐ |
| 2.8 | Avatar visible in profile screen after upload | ☐ | ☐ |
| 2.9 | Avatar visible in Circle member list | ☐ | ☐ |
| 2.10 | Avatar visible in message bubbles | ☐ | ☐ |
| 2.11 | Display name and avatar persist after full app restart | ☐ | ☐ |

---

## 3. Circles

### 3.1 Create Circle (Device A — Alice)

| # | Check | A |
|---|---|---|
| 3.1.1 | Home → "Create Circle" or FAB → Create Circle screen | ☐ |
| 3.1.2 | Submit empty name → validation error | ☐ |
| 3.1.3 | Submit name "Weekend Crew" → Circle created | ☐ |
| 3.1.4 | Circle appears immediately in Home list | ☐ |
| 3.1.5 | Circle card shows name, member count = 1 | ☐ |
| 3.1.6 | Enter Circle Room → 6-character invite code visible | ☐ |
| 3.1.7 | Invite code matches `[A-Z0-9]{6}` pattern | ☐ |
| 3.1.8 | Member list shows Alice with "Creator" badge | ☐ |

### 3.2 Join Circle (Device B — Bob)

| # | Check | B |
|---|---|---|
| 3.2.1 | Home → "Join Circle" → Join screen | ☐ |
| 3.2.2 | Submit empty code → validation error | ☐ |
| 3.2.3 | Submit invalid code (e.g. "XXXX") → user-friendly error | ☐ |
| 3.2.4 | Submit Alice's valid code → Bob joins Circle | ☐ |
| 3.2.5 | Circle appears in Bob's Home list | ☐ |
| 3.2.6 | Member count on Alice's device updates to 2 in real time | ☐ |
| 3.2.7 | Bob sees Alice in member list | ☐ |
| 3.2.8 | Bob cannot join same Circle again → "Already in this Circle" error | ☐ |

### 3.3 Leave Circle

| # | Check | A | B |
|---|---|---|---|
| 3.3.1 | Bob leaves Circle → Circle disappears from Bob's Home list | — | ☐ |
| 3.3.2 | Alice's member count decrements to 1 in real time | ☐ | — |
| 3.3.3 | Alice (as creator) attempts to leave with Bob present → blocked with explanation | ☐ | — |
| 3.3.4 | Alice (as sole member) leaves → Circle is deleted, removed from Alice's Home | ☐ | — |

> **Re-join for remaining tests:** Have Bob re-join the Circle after 3.3 tests, or skip 3.3.3–3.3.4 until end.

---

## 4. Messaging

_Prerequisite: Both Alice and Bob are in the same Circle._

### 4.1 Text Messages

| # | Check | A | B |
|---|---|---|---|
| 4.1.1 | Circle Room → Messages tab (or default view) shows message composer | ☐ | ☐ |
| 4.1.2 | Send text "Hello from Alice" → appears in list immediately | ☐ | — |
| 4.1.3 | Bob's device receives the message in real time (no refresh) | — | ☐ |
| 4.1.4 | Send text "Hello back from Bob" → appears on both devices | ☐ | ☐ |
| 4.1.5 | Own messages right-aligned; other's messages left-aligned | ☐ | ☐ |
| 4.1.6 | Sender name and avatar shown for messages from others | ☐ | ☐ |
| 4.1.7 | Message timestamp visible | ☐ | ☐ |
| 4.1.8 | Empty message cannot be sent (send button disabled or validation) | ☐ | ☐ |
| 4.1.9 | Circle card on Home shows last message preview | ☐ | ☐ |

### 4.2 Photo Messages

| # | Check | A | B |
|---|---|---|---|
| 4.2.1 | Tap photo icon in composer → image picker opens | ☐ | — |
| 4.2.2 | Select a photo → upload progress shown | ☐ | — |
| 4.2.3 | Photo message appears with image rendered | ☐ | — |
| 4.2.4 | Bob sees the photo in real time | — | ☐ |
| 4.2.5 | Photo with optional caption — caption shown below image | ☐ | ☐ |
| 4.2.6 | Broken image URL shows a broken-image placeholder icon | ☐ | ☐ |
| 4.2.7 | Large photo (e.g. 10 MB HEIC) — compression runs, upload completes < 500 KB | ☐ | — |

### 4.3 Delete Message

| # | Check | A | B |
|---|---|---|---|
| 4.3.1 | Long-press own message → confirm dialog appears | ☐ | ☐ |
| 4.3.2 | Tap Cancel → message unchanged | ☐ | ☐ |
| 4.3.3 | Long-press own message → confirm → "Message removed" placeholder shown | ☐ | ☐ |
| 4.3.4 | Other user sees "Message removed" placeholder in real time | ☐ | ☐ |
| 4.3.5 | Long-press on OTHER user's message → no delete option | ☐ | ☐ |
| 4.3.6 | Long-press on "Message removed" placeholder → no delete option | ☐ | ☐ |

---

## 5. Pulses

| # | Check | A | B |
|---|---|---|---|
| 5.1 | Pulse tab in Circle Room shows today's Pulse wall | ☐ | ☐ |
| 5.2 | Empty state shown when no Pulses exist today | ☐ | ☐ |
| 5.3 | Tap "Post Pulse" → Create Pulse screen opens | ☐ | ☐ |
| 5.4 | Photo is required — submit without photo → validation error | ☐ | ☐ |
| 5.5 | Select photo → compressed → upload to R2 → Pulse created | ☐ | ☐ |
| 5.6 | Pulse appears on Alice's wall immediately | ☐ | — |
| 5.7 | Pulse appears on Bob's wall in real time | — | ☐ |
| 5.8 | Caption and mood (optional) shown when provided | ☐ | ☐ |
| 5.9 | Progress indicator on Home/Circle shows "1/2 pulsed today" after one posts | ☐ | ☐ |
| 5.10 | Bob posts Pulse → progress shows "2/2 pulsed today" | ☐ | ☐ |
| 5.11 | Posting a second Pulse on same day → overwrites/updates (upsert) | ☐ | — |
| 5.12 | Alice cannot post a Pulse for Bob (unauthorized) | ☐ | — |

---

## 6. Plans

### 6.1 Create Plan

| # | Check | A |
|---|---|---|
| 6.1.1 | Plans tab → "Create Plan" → Create Plan screen | ☐ |
| 6.1.2 | Submit without title → validation error | ☐ |
| 6.1.3 | Fill title "Coffee Run", pick date/time → Create Plan | ☐ |
| 6.1.4 | Redirected to Plan Detail screen | ☐ |
| 6.1.5 | Plan visible in Plans list for both users in real time | ☐ |
| 6.1.6 | Date badge and meta info (host, date, time) shown correctly | ☐ |

### 6.2 Respond to Plan

| # | Check | A | B |
|---|---|---|---|
| 6.2.1 | Both users see In / Maybe / Can't response buttons | ☐ | ☐ |
| 6.2.2 | Bob taps "In" → count updates to 1 on both devices in real time | ☐ | ☐ |
| 6.2.3 | Bob taps "Maybe" → inCount decrements, maybeCount increments | ☐ | ☐ |
| 6.2.4 | Response list shows Bob's response | ☐ | ☐ |
| 6.2.5 | Alice responds "Can't" → cantCount = 1 | ☐ | ☐ |

### 6.3 Edit Plan (Alice only)

| # | Check | A |
|---|---|---|
| 6.3.1 | Plan Detail → ⋯ button visible for Alice (creator) | ☐ |
| 6.3.2 | ⋯ button NOT visible for Bob | — |
| 6.3.3 | Tap "Edit Plan" → Edit sheet opens with pre-filled values | ☐ |
| 6.3.4 | Change title to "Coffee & Cake" → Save → title updates on both devices | ☐ |
| 6.3.5 | Change date/time via pickers → saved correctly | ☐ |

### 6.4 Cancel Plan (Alice only)

| # | Check | A | B |
|---|---|---|---|
| 6.4.1 | ⋯ → "Cancel Plan" → confirm dialog | ☐ | — |
| 6.4.2 | Confirm cancel → plan shows red "Cancelled" banner on both devices | ☐ | ☐ |
| 6.4.3 | Response buttons disabled after cancel | ☐ | ☐ |
| 6.4.4 | ⋯ button no longer visible (plan not active) | ☐ | — |
| 6.4.5 | Cancelled plan not shown in active plans list | ☐ | ☐ |

---

## 7. Push Notifications

_Prerequisite: Cloud Functions deployed, both users have granted notification
permission._

| # | Check | A | B |
|---|---|---|---|
| 7.1 | App prompts for notification permission on first launch after sign-in | ☐ | ☐ |
| 7.2 | FCM token stored in Firestore `users/{id}.fcmTokens` | ☐ | ☐ |
| 7.3 | Alice sends a message → Bob receives push notification within ~5 s | — | ☐ |
| 7.4 | Push notification shows sender name and Circle name in title | — | ☐ |
| 7.5 | Push shows message text (truncated if > 120 chars) | — | ☐ |
| 7.6 | Alice creates a new Plan → Bob receives push notification | — | ☐ |
| 7.7 | Plan notification shows creator name and plan title | — | ☐ |
| 7.8 | Alice does NOT receive a push for her own messages/plans | ☐ | — |
| 7.9 | App foregrounded — no crash on receiving push | ☐ | ☐ |
| 7.10 | App backgrounded — push notification visible in system tray | ☐ | ☐ |

---

## 8. Media Rendering

| # | Check | A | B |
|---|---|---|---|
| 8.1 | R2-hosted Pulse photos load on Pulse wall | ☐ | ☐ |
| 8.2 | R2-hosted message photos load in chat | ☐ | ☐ |
| 8.3 | Avatar photos load in member list | ☐ | ☐ |
| 8.4 | Loading indicator shown while image downloads | ☐ | ☐ |
| 8.5 | Broken/expired URL shows placeholder icon — no white box | ☐ | ☐ |
| 8.6 | Photos load on slow connection (throttle to 3G) | ☐ | ☐ |

---

## 9. Security Verification

_These verify the Firestore rules are enforced from the client. Use a
test account that is NOT a member of Alice's Circle._

| # | Check |
|---|---|
| 9.1 | Non-member cannot see Circle in Firestore (confirm via Firebase Console → no reads from outside UID) |
| 9.2 | Invite code for an unknown Circle returns "No Circle found" error |
| 9.3 | Expired/revoked invite code returns error (if implemented) |
| 9.4 | User A cannot read User B's profile document (confirm via rules test or Firestore REST probe) |
| 9.5 | All Cloud Function triggers execute with `firebase-admin` (bypasses client rules safely) |
| 9.6 | R2 presigned URL expires after 5 minutes — old URL rejected |
| 9.7 | R2 Worker rejects uploads > 10 MB |
| 9.8 | R2 Worker rejects file extensions outside allowlist (e.g. `.exe`) |

---

## 10. Offline / Edge Cases

| # | Check | A | B |
|---|---|---|---|
| 10.1 | Airplane mode → app shows last known data (Firestore persistence) | ☐ | ☐ |
| 10.2 | No crash or freeze when offline | ☐ | ☐ |
| 10.3 | Reconnect → pending data syncs, new messages appear | ☐ | ☐ |
| 10.4 | Send message while offline → appears after reconnect | ☐ | — |
| 10.5 | Upload photo while offline → graceful error shown | ☐ | — |
| 10.6 | Create plan while offline → graceful error shown | ☐ | — |
| 10.7 | App restored from background after 30+ mins → data still fresh | ☐ | ☐ |
| 10.8 | Rapid navigation (back/forward quickly) → no navigation crashes | ☐ | ☐ |

---

## 11. Navigation

| # | Check | A |
|---|---|---|
| 11.1 | Back button works on all screens (no "stuck" states) | ☐ |
| 11.2 | Deep navigation (Home → Circle → Plans → Plan Detail) → back returns correctly | ☐ |
| 11.3 | After creating a Plan → pushed to Plan Detail, back goes to Circle | ☐ |
| 11.4 | After joining a Circle → Circle Room opens, Home accessible | ☐ |
| 11.5 | Sign out from deep in navigation → routed to Sign In (no leftover screens) | ☐ |
| 11.6 | Navigating to Sign In while already authenticated → redirected away | ☐ |
| 11.7 | Profile setup screen not shown after profile already exists | ☐ |
| 11.8 | Android system back button works consistently | ☐ |

---

## 12. Error States

| # | Check | A | B |
|---|---|---|---|
| 12.1 | Error snackbar shown on auth failure (not a crash) | ☐ | ☐ |
| 12.2 | Error snackbar shown on Firestore write failure | ☐ | ☐ |
| 12.3 | Loading spinner shown while async operations run | ☐ | ☐ |
| 12.4 | Empty state shown when Circle has no messages | ☐ | ☐ |
| 12.5 | Empty state shown when Circle has no Pulses today | ☐ | ☐ |
| 12.6 | Empty state shown when Circle has no Plans | ☐ | ☐ |
| 12.7 | No screen is ever blank/white without explanation | ☐ | ☐ |

---

## Sign-off

| Tester | Device | OS | App version | Date | Pass? |
|---|---|---|---|---|---|
| Alice | | | | | ☐ |
| Bob | | | | | ☐ |

**Known issues found during smoke test:**
<!-- List any issues here -->

---

_Checklist generated for CirclePlus beta — commit `89db39b`_
