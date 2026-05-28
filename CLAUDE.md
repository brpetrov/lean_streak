# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
flutter run -d chrome          # Run web (primary target)
flutter run -d android          # Run on Android device/emulator
flutter test                    # Run all tests
flutter test test/health_calculator_test.dart   # Run a single test file
flutter analyze                 # Lint (uses flutter_lints)
firebase deploy --only hosting  # Deploy web build to Firebase Hosting
firebase deploy --only firestore:rules  # Deploy Firestore security rules
```

The web build outputs to `build/hosting`. Firebase Hosting serves it with SPA rewrites.

## Architecture

**State management:** Riverpod. StreamProviders for real-time Firestore data, StateNotifier-style controllers for mutations.

**Routing:** GoRouter with reactive auth-based redirects. The router listens to both `authStateProvider` and `userProfileProvider` and enforces: Splash → Auth → Onboarding → Dashboard. Route names live in `AppRoutes` in `lib/app/router.dart`.

**Data flow:** Repository pattern. Each Firestore collection has a repository (`lib/repositories/`) that handles reads/writes. Services (`lib/services/`) compose repositories for business logic. Providers (`lib/providers/`) expose state to the UI and wire up controllers.

**Firestore structure:** All user data lives under `/users/{uid}/` with subcollections for meals, daily summaries, check-ins, AI usage, and period reviews. Security rules enforce owner-only access.

## Key Domain Logic

- **Health calculations** (`lib/helpers/health_calculator.dart`): Pure functions for BMI, BMR (Mifflin-St Jeor), TDEE, and daily calorie targets. Has safety floors. Extensively tested.
- **Daily summaries** (`lib/services/daily_summary_service.dart`): Recomputed from meals whenever a meal is logged/edited. Includes calorie totals, tag counts, and a green/yellow/red status based on adherence to target (±10% green, ±20% yellow, else red).
- **AI calorie estimation** (`lib/services/calorie_estimate_service.dart`): Uses Google Gemini 2.5 Flash to estimate calories from meal descriptions. Has a daily usage limit (10/user/day) tracked in Firestore.
- **Period reviews** (`lib/services/period_review_service.dart`): Aggregates daily summaries into weekly/monthly review data.

## Models

All models use manual Firestore serialization (no codegen). Each model has `fromFirestore` / `toFirestore` methods. Enums use `fromString` factory constructors with legacy value handling (e.g., `ActivityLevel` accepts both old and new string formats).

Key models: `UserProfile` (with enums for Gender, ActivityLevel, TrainingFrequency, WeightGoal, DeficitLevel), `Meal` (with `MealTag` enum categorized by tone: healthy/neutral/unhealthy), `DailySummary`, `CheckIn`, `PeriodReview`.

## Conventions

- Dart SDK `^3.11.4`, uses modern Dart 3 features (switch expressions, pattern matching, records).
- `speech_to_text` package is already a dependency.
- `lib/core/config/api_keys.dart` holds the Gemini API key, treat as sensitive.
- Notifications handled by `flutter_local_notifications` via `NotificationService`, initialized at startup.
- The app targets web primarily but also supports Android and iOS.
