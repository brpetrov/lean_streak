# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
flutter run -d edge            # Run web (primary target; -d chrome where Chrome is installed)
flutter run -d android          # Run on Android device/emulator
flutter test                    # Run all tests
flutter test test/health_calculator_test.dart   # Run a single test file
flutter analyze                 # Lint (uses flutter_lints)
firebase deploy --only hosting  # Deploy web build to Firebase Hosting
firebase deploy --only firestore:rules  # Deploy Firestore security rules
```

`tools/build_hosting.ps1` builds the web app into `build/hosting` (an `/app` build plus a `/webkit` build for Safari/iOS, behind a small redirect page). Firebase Hosting serves it with SPA rewrites.

## Architecture

**State management:** Riverpod. StreamProviders for real-time Firestore data, StateNotifier-style controllers for mutations.

**Routing:** GoRouter with reactive auth-based redirects. The router listens to both `authStateProvider` and `userProfileProvider` and enforces: Splash → Auth → Onboarding → Dashboard. Route names live in `AppRoutes` in `lib/app/router.dart`.

**Screens:** Today (`DashboardScreen`) is home: calories/protein, the day's meals, a month graph and weight, with the quick-log bar pinned at the bottom (type `chicken wrap 450`, or use the mic). There are no bottom tabs; the top-left menu opens Review, Weight & Progress, Plan Settings and Account Settings as pushed pages. Review combines a week/month calendar with the period review; tapping a day opens its meals for adding, editing or deleting.

**Styling:** Light mode only. `AppColors` is a fixed warm palette and `AppTheme` is built from it; use `AppCard` (`lib/widgets/app_card.dart`) for cards rather than hand-built containers. On wide browser windows `appShellBuilder` (`lib/app/app.dart`) shows the app as one centred column.

**Data flow:** Repository pattern. Each Firestore collection has a repository (`lib/repositories/`) that handles reads/writes. Services (`lib/services/`) compose repositories for business logic. Providers (`lib/providers/`) expose state to the UI and wire up controllers.

**Firestore structure:** All user data lives under `/users/{uid}/` with subcollections for meals, daily summaries, check-ins, AI usage, and period reviews. Security rules enforce owner-only access.

## Key Domain Logic

- **Health calculations** (`lib/helpers/health_calculator.dart`): Pure functions for BMI, BMR (Mifflin-St Jeor), TDEE, and daily calorie targets. Has safety floors. Extensively tested.
- **Daily summaries** (`lib/services/daily_summary_service.dart`): Recomputed from meals whenever a meal is logged/edited. Includes calorie totals, meal count, and a green/yellow/red status based on adherence to target (±10% green, ±20% yellow, else red).
- **AI calorie estimation** (`lib/services/calorie_estimate_service.dart`): Uses Gemini 3.5 Flash-Lite with prompts tuned for UK portions and Bulgarian home cooking; returns calories and protein. Typed estimates have a daily limit (`AiUsageRepository.dailyLimit`, 20/user/day) tracked in Firestore.
- **Period reviews** (`lib/services/period_review_service.dart`): Aggregates daily summaries into weekly/monthly review data, shown under the Review calendar for finished days.
- **Past-day changes** (`lib/providers/log_meal_controller.dart`): adding, editing or deleting a meal on an earlier day uses one of 10 changes per calendar month (`DayEditRepository.monthlyLimit`).
- **Today isn't judged mid-day:** a day only shows its green/yellow/red status once it is finished, on track, or over target (`hasSettledStatus` in `lib/widgets/day_status.dart`).

## Models

All models use manual Firestore serialization (no codegen). Each model has `fromFirestore` / `toFirestore` methods. Enums use `fromString` factory constructors with legacy value handling (e.g., `ActivityLevel` accepts both old and new string formats).

Key models: `UserProfile` (with enums for Gender, ActivityLevel, TrainingFrequency, WeightGoal, DeficitLevel), `Meal` (name, calories, optional protein), `DailySummary`, `CheckIn`, `PeriodReview`.

## Conventions

- Dart SDK `^3.11.4`, uses modern Dart 3 features (switch expressions, pattern matching, records).
- `speech_to_text` package is already a dependency.
- `lib/core/config/api_keys.dart` holds the Gemini API key, treat as sensitive.
- Notifications handled by `flutter_local_notifications` via `NotificationService`, initialized at startup.
- The app targets web primarily but also supports Android and iOS.
