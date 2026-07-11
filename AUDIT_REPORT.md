# CirclePulse Codebase Audit Report

**Date:** 2026-07-11  
**Scope:** Full multi-lens audit (read-only). No code was modified.  
**Method:** Docs + source trace (imports, call sites, rules, Worker, tests). Claims verified against implementation before ranking.

---

## Remediation status (2026-07-11)

Phases A–E implemented in code. Live Firebase/Cloudflare deploy was **not**
performed (manual). See `progress.md` Session 8 for file-level notes.

| ID | Status |
|----|--------|
| F01–F05, F07–F11, F13–F17, F19–F30, F32–F34 | Fixed / addressed in repo |
| F03 | Documented accepted MVP limitation (public R2 URLs) |
| F06 | Manual deploy still required |
| F12, F18 | Documented accepted MVP risk |
| F31 | Docs reminder added |

---

## Phase 0 — Orientation summary

**CirclePulse** (`circleplus`) is a single Flutter/Dart mobile app for private friend groups (“Circles”): email/password auth via Firebase Auth, real-time data in Cloud Firestore, and media uploads to Cloudflare R2 through a Cloudflare Worker that issues Firebase-authenticated, membership-checked presigned PUT URLs. The client is feature-first (`lib/features/{auth,profile,circles,messages,pulses,plans}` with `data` / `domain` / `presentation`), Riverpod for state, GoRouter for auth-aware navigation, and Material 3 plus a shared warm UI layer (`circlepulse_ui.dart`). Supporting pieces: root Firestore rules/indexes, `backend/r2-upload-worker`, Jest/emulator `rules-tests/`, and Dart unit tests under `test/`. There is no monorepo workspace, no Docker app runtime, and no GitHub Actions CI. Docs (`readme.md`, `architecture.md`, `AGENTS.md`, `progress.md`) describe an MVP that progress marks feature-complete pending deploy and device smoke tests.

---

## Executive summary

- Architecture matches the intended feature/repository/Riverpod shape; domain stays free of Firebase/Flutter imports, and widgets do not call Firestore directly.
- **Delete Circle is broken against current Firestore rules** (member-delete rule requires a surviving Circle doc while the client deletes that doc in the same transaction).
- **Message soft-delete is broken against current rules** (client writes `text`/`mediaUrl: null`; rules require those keys to be absent — use `FieldValue.delete()` or change the rule). Emulator tests do not match the client payload.
- **Private Circle media is stored behind publicly reachable R2 URLs**; membership protects Firestore, not the object bytes once a URL is known.
- Upload size limit (10 MB) is documented in the Worker but not enforced when the Flutter client omits `contentLength`.
- Core AuthZ for membership/sender/self-writes lives in Firestore rules (not UI-only); Worker JWT + membership checks for uploads look sound.
- MVP product flows are largely present (including forgot-password and leave-circle UI). Gaps are misleading affordances (cover picker no-op, home `more_vert`), weak error retry, and incomplete delete semantics.
- Performance: home Circle list does N+1 Circle document fetches; Home also opens per-Circle Pulse streams — acceptable for tiny groups, not for growth.
- Tests cover models/utils and many rules paths, but miss the broken delete/soft-delete client shapes, auth routing, and controllers. **No CI** runs analyze/test on PRs.
- Deploy of rules, indexes, and the R2 Worker is still unchecked in `progress.md`; until verified in cloud, local hardening does not protect production.
- Prior `PRODUCTION_AUDIT.md` is partly stale (e.g. forgot-password now exists).

---

## Findings table

| ID | Severity | Lens | Location | Issue | Suggested fix |
|----|----------|------|----------|-------|---------------|
| F01 | **Critical** | Security / Functional | `firestore.rules:197-204`, `236-242`; `lib/features/circles/data/firebase_circle_repository.dart:202-230`; `circle_members_screen.dart:235-264` | **Delete Circle cannot succeed.** Creator last-member flow deletes Circle + member in one transaction. Circle delete allows that pattern, but member delete requires `getAfter(circlePath).data.memberCount` — impossible once the Circle doc is gone. UI promises permanent removal. | Align rules + client: e.g. allow member delete when `!existsAfter(circlePath)` for creator last-member, **or** soft-delete/tombstone Circle and cascade via backend. Add emulator test for the exact client transaction. |
| F02 | **Critical** | Security | `firestore.rules:201-204`, `218-231`, `152-153`; delete only touches parent + creator member (`firebase_circle_repository.dart:226-229`) | **Even a “successful” client delete would leave orphaned subcollections** (messages, pulses, plans, other members) and an **immutable invite code**. A crafted client can create a member under the old `circleId` with that invite (join create does not require Circle parent existence) and then satisfy `isCircleMember()` to read orphans. | Prefer trusted backend recursive delete + invite revocation; or soft-delete parent and require non-deleted Circle in every auth helper. Never claim “all content removed” until cascade is real. |
| F03 | **High** | Security | `backend/r2-upload-worker/src/index.ts:157-166`; architecture/product “private Circles” | **Circle media is returned as public R2 URLs.** Firestore membership does not protect object access if URL leaks. | Serve private objects via authz’d Worker / short-lived signed GETs; keep avatars public only if product accepts that. **Needs product decision.** |
| F04 | **High** | Functional / Security | `firestore.rules:271-278`; `firebase_message_repository.dart:103-118`; `rules-tests/.../firestore.rules.test.ts:688-695` | **Soft-delete mismatch.** Rules require `text`/`mediaUrl` keys absent; client sets them to `null` (keys remain). Rules tests update only `type`/`deletedAt` and still leave `text` present — likely not validating the real rule intent or client path. | Client: `FieldValue.delete()` for `text`/`mediaUrl`, **or** rules: allow `null`. Mirror exact client payload in emulator tests. |
| F05 | **High** | Security | `r2-upload-worker/src/index.ts:35-45`, `234-242`; `storage_service.dart:86-102` | **10 MB upload cap is optional.** Flutter never sends `contentLength`; presign does not bind size. | Require + bind content length in signed PUT, or proxy uploads with a hard limit; enforce at R2 if available. |
| F06 | **High** | Reliability / Ops | `progress.md:145-147`; `PRODUCTION_AUDIT.md:82-84` | **Firestore rules/indexes and R2 Worker deploy still unmarked.** Local rules do not protect a live project until deployed. | Treat as release blocker: deploy, then verify live rules/Worker match repo. Manual smoke per `BETA_SMOKE_TEST.md`. |
| F07 | **High** | DX / Reliability | No `.github/workflows/*`; `rules-tests/README.md:6-42` | **No CI** for `flutter analyze`, `flutter test`, or rules-tests. | Add GitHub Actions: analyze + unit tests; optional emulator job for rules-tests. |
| F08 | **High** | Performance | `firebase_circle_repository.dart:117-139` | **`watchUserCircles` N+1:** membership stream then sequential `get` per Circle (prior audit M1, still present). | Batch/parallel gets, denormalize Circle summary onto member docs, or maintain a user→circles index. |
| F09 | **High** | UI / Functional | `create_circle_screen.dart:114-124`; `storage_service.dart` `circleCover` unused; create always `coverUrl: null` (`firebase_circle_repository.dart:31-43`) | **Cover picker is a visible no-op** (`onTap: () {}`). Misleading UX; cover upload type exists but unused. | Remove/disable until P1 cover work, or implement picker + R2 upload. **Needs product decision.** |
| F10 | **Medium** | Security | `firestore.rules:176-195`, `218-231` | **Join member create does not require atomic `memberCount + 1`.** Client does increment correctly; malicious client can skip it → wrong counts; compounds unsafe last-member delete (F01/F02). | Require matching count increment in the same commit for join creates. |
| F11 | **Medium** | Security | `firestore.rules:359-365` (no `status == 'active'`); UI disables votes when cancelled | **Rules allow Plan responses after cancel.** UI-only restriction. | Require plan `status == 'active'` on response create/update and count updates. |
| F12 | **Medium** | Security | `firestore.rules:290-303`; `firebase_pulse_repository.dart:62-83` | **“One Pulse per day / today only” is mostly client-side.** Rules check ID shape/UID, not calendar day or field lockdown on update. | Tighten rules (date vs `request.time`, ID/`dateKey` consistency, update allow-list) or accept as MVP risk and document. |
| F13 | **Medium** | Security | `r2-upload-worker/src/index.ts:41-45`, `210-221` | **Any `image/*` MIME** accepted; extension checked separately (e.g. SVG + `.png` mismatch risk). | Exact MIME allow-list; reject SVG; map MIME↔extension; ideally re-encode server-side. |
| F14 | **Medium** | UI/UX | `error_view.dart:3-31`; call sites e.g. `home_screen.dart:39-42`, `message_list.dart:30-38`, `pulse_wall_screen.dart:24-32`, `plans_screen.dart:34-51` | **`ErrorView.onRetry` unused** on stream screens — transient failures need navigate-away/restart. | Wire `ref.invalidate(...)` / refresh callbacks on data-driven screens. |
| F15 | **Medium** | UI/UX | `home_screen.dart:30-35`; `auth_controller.dart:58-61` | **Sign-out has no loading/error UI** on Home (unlike auth forms). | Watch/listen `authControllerProvider`; disable icon + snackbar on failure. |
| F16 | **Medium** | Architecture | Controllers import `Firebase*Repository` e.g. `auth_controller.dart:4-12`, `circle_controller.dart:4-14` (same pattern across features) | **Presentation wires concrete Firebase repos**, leaking data layer into UI composition vs `presentation → domain` docs. | Centralize provider registration (e.g. `lib/app/providers.dart`); presentation depends on interfaces only. |
| F17 | **Medium** | Code quality | `circle_room_screen.dart` (~841 lines), `plan_detail_screen.dart` (~718 lines) | Large screen files mix layout, streams, dialogs, forms — higher regression cost. | Extract section widgets / sheets; keep screens as composition. |
| F18 | **Medium** | Performance | `home_screen.dart:271-294`, `349-389`; `pulse_controller.dart:18-36` | **One today-Pulse query (+ my-Pulse) per Circle on Home** while visible. | Accept for MVP, or denormalize progress onto Circle/member docs. |
| F19 | **Medium** | Performance | `firebase_plan_repository.dart:18-29`, `98-114`; members stream unbounded | **Plans/responses (and members) streams unbounded**; chat capped at 100 with **no “load earlier”**. | Limit/paginate plans; later message cursor pagination (already P1 in progress). |
| F20 | **Medium** | Performance | `pubspec.yaml` (no `cached_network_image`); `Image.network` in pulse wall, messages, avatar | **No disk image cache** for R2 media. | Add `cached_network_image` (already suggested in readme) or equivalent. |
| F21 | **Medium** | Testing | `test/*` models/utils only; `app_router.dart:36-80` untested; `leave_circle_test.dart` tests a **local helper**, not repository/rules/UI | Risky routing and leave/delete paths lack real automated coverage. | Auth redirect widget/unit tests; emulator tests for leave/delete; fix soft-delete tests (F04). |
| F22 | **Medium** | Testing / Docs | `test/leave_circle_test.dart:7-114` vs `circle_members_screen.dart:150-303` | Leave/delete UI exists, but unit test does not exercise it — false confidence. | Replace/extend with repository + rules tests matching F01. |
| F23 | **Low** | A11y | Pulse wall / photo messages / recent moments (`pulse_wall_screen.dart:45-68`, `message_list.dart:278-341`, `circle_room_screen.dart:796-819`) | Photo content lacks `Semantics` labels. | `Semantics(image: true, label: …)` for meaningful images. |
| F24 | **Low** | UI | `home_screen.dart:201-208` | Non-interactive `more_vert` looks like a menu. | Remove, use chevron, or implement menu. |
| F25 | **Low** | Code quality | Profile precondition duplicated in circle/message/pulse/plan controllers (~lines 112-124 / 96-108 / 101-113 / 151-163) | Drift risk for “profile required” errors. | Shared helper / use-case. |
| F26 | **Low** | Code quality | Timestamp `dynamic` helpers duplicated across models e.g. `circle.dart:61-76`, `message.dart:78-93`, `plan.dart:86-97` | Runtime risk on malformed data; duplication. | Shared typed converter. |
| F27 | **Low** | Dead code | `lib/services/firebase/firebase_service.dart:1-3` | Empty `FirebaseService` — no call sites. | Delete or give a real role. |
| F28 | **Low** | API clarity | `message_repository.dart:20-26`; `firebase_message_repository.dart:103-119` | `senderId` unused in soft-delete impl (rules enforce ownership). | Drop param or assert against auth uid in a use-case. |
| F29 | **Low** | Docs | `readme.md:70-80` vs Session 7 removal of FCM | README still says “Firebase Cloud Messaging-ready structure”. | Remove/qualify claim. |
| F30 | **Low** | DX | `readme.md` setup vs `pubspec.yaml`; R2 define split across readme/Worker/storage error | Not a true 10-minute clone→run path; readme still mentions `cached_network_image` not in manifest. | Linear quickstart + single config checklist. |
| F31 | **Low** | Security / Ops | `.env` present locally (5 lines); `.gitignore:46-49` ignores `.env` and Worker `wrangler.toml`; `git ls-files` does not track them | Local plaintext Cloudflare/R2 secrets are expected for dev but are high-value if shared/backed up insecurely. | Rotate if ever exposed; keep gitignore; never commit. |
| F32 | **Low** | Security | `r2-upload-worker/src/index.ts:227-231`, `301-306` | `circleId` blocks `/` and `..` but not other URL-unsafe chars; interpolated without encoding. | Strict ID charset or encode path segments. |
| F33 | **Nitpick** | Code quality | `create_plan_screen.dart:127` | Stale placeholder comment. | Remove or ticket. |
| F34 | **Nitpick** | Tooling | `analysis_options.yaml` | Baseline `flutter_lints` only; no CI enforcement. | Optional stricter lints once CI exists. |

### Lenses with little additional signal

- **State management fit:** Riverpod + `AsyncValue` loading/error/data on main streams is appropriate for this MVP; no recommendation to switch libraries.
- **CORS/CSRF/cookies:** Mobile Flutter + Firebase Auth tokens; Worker CORS via `ALLOWED_ORIGIN`. No classic cookie CSRF surface like a browser SPA session.
- **XSS/HTML injection:** No WebView/`dart:html` sinks found; user text via Flutter `Text`.
- **Circular dependencies:** None found of significance.
- **Silent swallowed exceptions:** Controllers generally use `AsyncValue.guard`; no empty catch pattern found in the audit pass.

---

## Prioritized remediation plan

### Phase A — Critical correctness & privacy holes (ship first)

**Goal:** Make Delete Circle and soft-delete actually work under rules; close orphan/invite resurrection path; decide media privacy model.

| Items | Notes |
|-------|--------|
| F01 | Fix delete Circle rules ↔ transaction; add emulator test |
| F02 | Cascade/tombstone + revoke invite; honest UI copy |
| F04 | Align soft-delete client + rules + tests |
| F03 | **Decision required** (see below) — do not “fix” by only hiding URLs in UI |

**Exit criteria:** Emulator tests for delete + soft-delete matching production client payloads; progress/smoke checklist updated.

### Phase B — AuthZ hardening & upload abuse

| Items | Notes |
|-------|--------|
| F10 | Require join `memberCount` bump in rules |
| F11 | Block responses on cancelled plans in rules |
| F12 | Pulse day/field lockdown (or document accepted risk) |
| F05, F13, F32 | Worker size bind, MIME allow-list, safer IDs |

**Exit criteria:** New/updated `rules-tests` cases; Worker validation tests if present or added.

### Phase C — Broken / misleading UX & ops readiness

| Items | Notes |
|-------|--------|
| F09 | Cover affordance: remove or implement (**decision**) |
| F14, F15, F24 | Retry, sign-out feedback, dead `more_vert` |
| F06 | Deploy rules/indexes/Worker; run `BETA_SMOKE_TEST.md` |
| F07, F21, F22 | CI + auth routing + real leave/delete tests |
| F29, F30 | README / onboarding accuracy |

### Phase D — Performance & architecture polish

| Items | Notes |
|-------|--------|
| F08, F18, F19, F20 | N+1, Home Pulse listeners, pagination, image cache |
| F16, F17, F25–F28, F33–F34 | Provider boundaries, split large screens, cleanup |

### Phase E — Accessibility & nitpicks

| Items | Notes |
|-------|--------|
| F23, F31 | Semantics; secret hygiene reminder |

Phases A–B are independently reviewable. Phase C can ship without D. Do not mix mass reformat into any phase.

---

## Decisions needed before Phase 4

Please choose (or defer) these before remediation starts:

1. **Private media (F03)**  
   - **(a)** Keep public R2 URLs for MVP (document as known limitation), or  
   - **(b)** Authenticated/signed download path (larger change).

2. **Circle deletion (F01 + F02)**  
   - **(a)** Soft-delete / tombstone Circle + block reads via rules, or  
   - **(b)** Backend recursive delete + invite revoke (Cloud Function/Worker), or  
   - **(c)** Minimal rule fix so last-member delete works, accepting orphaned subcollections temporarily with corrected copy.

3. **Soft-delete (F04)**  
   - **(a)** Client `FieldValue.delete()`, or  
   - **(b)** Relax rules to allow `null`.

4. **Cover picker (F09)**  
   - **(a)** Remove/disable UI now, or  
   - **(b)** Implement cover upload in the same remediation wave.

5. **Pulse day enforcement (F12)**  
   - **(a)** Tighten Firestore rules now, or  
   - **(b)** Document as accepted MVP risk and skip for now.

6. **Process**  
   - Which phases to run (A / B / C / D / E)?  
   - Pause for checkpoint after each phase, or run approved phases continuously?

---

## Explicitly out of scope / not inflated

- Adding public feed, DMs, reactions, etc. (forbidden scope creep per `AGENTS.md`).
- Rewriting to a different state library (Riverpod fits).
- Claiming production is compromised without deploy verification — F06 is an ops gate, not proof of open rules in the live project.
- `firebase_options.dart` client API keys are normal for Firebase; safety depends on rules + API key restrictions, not treating them as R2 secrets.

---

## Stop — approval gate

**Phase 3 complete.** No remediation code has been written.

**Please reply with:**

1. Which remediation phases to proceed with (e.g. `A only`, `A+B`, `A–C`, …).  
2. Your choices on decisions 1–5 above (or “use your recommended defaults”).  
3. Whether to **pause between phases** or **run approved phases without stopping**.

Recommended defaults if you want a fast path: **1a** (document public media for MVP), **2c then schedule 2b**, **3a** (`FieldValue.delete()`), **4a** (remove cover no-op), **5b** (document Pulse day risk), phases **A → B → C** with pause after each phase.
