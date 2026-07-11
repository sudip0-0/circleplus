# Deploy checklist (manual AuthZ gate)

Local rules and Worker code do **not** protect your Firebase/Cloudflare
project until you deploy them. Complete these steps before beta smoke testing.

## 1. Deploy Firestore rules + indexes

```bash
firebase deploy --only firestore
```

Or separately:

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

Confirm in Firebase Console → Firestore → Rules that the deployed rules match
`firestore.rules` in this repo.

## 2. Deploy R2 upload/download Worker

```bash
cd backend/r2-upload-worker
# ensure wrangler.toml has FIREBASE_PROJECT_ID, R2_*, ALLOWED_ORIGIN
wrangler secret put R2_ACCESS_KEY_ID
wrangler secret put R2_SECRET_ACCESS_KEY
npm run deploy
```

Copy the Worker URL for Flutter:

```bash
flutter run --dart-define=R2_UPLOAD_SIGNER_URL=https://YOUR_WORKER_URL
```

## 3. Enable Crashlytics (after Phase 2 code lands)

- Firebase Console → Crashlytics → enable for the Android/iOS apps
- Ship a release or profile build once to verify reports appear

## 4. Post-deploy AuthZ smoke (minimum)

Use two accounts (see `BETA_SMOKE_TEST.md` for full matrix):

- [ ] Signed-out reads denied
- [ ] Non-member cannot read Circle messages / Pulses / Plans
- [ ] Member can upload media; Worker rejects non-member Circle sign
- [ ] Member can resolve a signed download for Circle media
- [ ] Soft-deleted Circle does not appear on Home; invite join fails

## Status

Leave these unchecked in `progress.md` until **you** confirm the cloud deploys:

- [ ] Firestore rules deployed
- [ ] Firestore indexes deployed
- [ ] R2 Worker deployed
- [ ] AuthZ smoke above passed
