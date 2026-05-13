# Project Structure

## Top-Level Layout

```
lib/
  main.dart              # Entry point — Firebase init, ProviderScope, runs app
  app.dart               # MaterialApp.router with theme and router config
  firebase_options.dart  # Generated Firebase config

  core/                  # Cross-cutting utilities
    constants/           # App-wide constants (AppConstants)
    errors/              # Custom exception types (AppException)
    utils/               # Pure helpers (date_key, invite_code_generator, app_logger)

  features/             # Feature modules (one per domain concept)
    auth/
    circles/
    messages/
    notifications/
    plans/
    profile/
    pulses/

  routing/              # GoRouter config and route constants (AppRoutes)
  services/             # Infrastructure services (firebase, notifications, storage)
  shared/               # Reusable UI and models
    extensions/
    models/
    widgets/            # LoadingView, EmptyState, ErrorView, AppTextField
  theme/                # AppTheme (Material 3 light theme)
```

## Feature Module Pattern

Each feature follows a three-layer structure:

```
features/<name>/
  domain/         # Models/entities, repository interfaces (abstract interface class)
  data/           # Firebase/backend implementations of repository interfaces
  presentation/  # Screens, widgets, Riverpod providers/controllers
```

## Architecture Conventions

- **Repository pattern:** Domain defines abstract interfaces; data layer implements them with Firebase.
- **Provider wiring:** Repository providers live in `presentation/` files alongside controllers. A single `Provider<Repository>` creates the concrete implementation.
- **Controllers:** Use `AsyncNotifier` for mutation-heavy logic (e.g., `AuthController`). Use `StreamProvider` / `FutureProvider` for read-only reactive data.
- **No direct Firebase in widgets.** Widget → Provider/Controller → Repository → Firebase service.
- **Immutable models** with `const` constructors and `fromMap`/`toMap` serialization.
- **Route constants** in `AppRoutes` class with private constructor.
- **Shared widgets** handle loading, empty, and error states so screens stay consistent.

## Naming Conventions

- Models: `CircleModel`, `PulseModel`, `PlanModel`, `AppUser`
- Repositories: `AuthRepository`, `CircleRepository`, `ProfileRepository`
- Screens: `SignInScreen`, `HomeScreen`, `CircleRoomScreen`, `CreatePulseScreen`
- Providers: `authRepositoryProvider`, `currentUserProvider`, `authControllerProvider`
- Constants classes use private constructors: `const ClassName._();`
