# Tech Stack & Build

## Core Stack

- **Framework:** Flutter (Dart SDK ^3.11.5)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter (`go_router`)
- **UI:** Material 3 with `ColorScheme.fromSeed`
- **Backend:** Firebase (Auth, Cloud Firestore, Cloud Messaging)
- **Media Storage:** Cloudflare R2 via backend-generated presigned URLs (no R2 credentials in the Flutter app)

## Key Dependencies

| Package | Purpose |
|---|---|
| firebase_core | Firebase initialization |
| firebase_auth | Email/password authentication |
| cloud_firestore | Database |
| firebase_messaging | Push notification readiness |
| flutter_riverpod | State management |
| go_router | Declarative routing |
| http | HTTP requests (presigned URL uploads) |
| image_picker | Camera/gallery photo selection |
| intl | Date/number formatting |

## Lint & Analysis

Uses `package:flutter_lints/flutter.yaml` (standard recommended rules).

## Common Commands

```bash
# Get dependencies
flutter pub get

# Run the app (debug)
flutter run

# Analyze code
flutter analyze

# Run tests
flutter test

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

## Environment

A `.env` file exists at the project root for configuration values. Do not commit secrets.
