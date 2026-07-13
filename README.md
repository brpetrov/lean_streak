# LeanStreak

A low-friction habit and calorie-consistency tracker. LeanStreak builds you a
personalised calorie plan from a short onboarding, then makes daily logging fast
enough to actually stick with — including voice-to-text meal entry and AI calorie
estimation — and turns those logs into a simple green/yellow/red picture of how
consistent you're being.

Built with Flutter and Firebase. The primary target is the web build, but the
same codebase also runs on Android and iOS.

## Features

- **Personalised plan** — computes BMI, BMR (Mifflin–St Jeor), TDEE, and a daily
  calorie target from your profile and goal, with safety floors so targets never
  drop to unhealthy levels.
- **Fast meal logging** — log meals by text, by voice (speech-to-text), or with
  AI calorie estimation powered by Google Gemini 2.5 Flash. Meals are categorised
  with tags grouped by tone (healthy / neutral / unhealthy).
- **Daily summaries** — every log recomputes the day's calorie total, tag counts,
  and an adherence status: green (within ±10% of target), yellow (±20%), or red.
- **Past-day editing** — go back and correct earlier days; summaries recompute.
- **Weight tracking** — log weight over time and view progress on charts.
- **Check-ins & reviews** — daily check-ins plus weekly and monthly period reviews
  that aggregate your daily summaries.
- **Reminders** — local notifications to keep the streak going.

## Tech stack

| Concern            | Choice                                             |
| ------------------ | -------------------------------------------------- |
| UI                 | Flutter (Dart SDK `^3.11.4`)                       |
| State management   | Riverpod                                           |
| Routing            | GoRouter with reactive auth-based redirects        |
| Backend            | Firebase Auth + Cloud Firestore                    |
| Hosting            | Firebase Hosting (SPA)                             |
| AI                 | Google Gemini 2.5 Flash (`google_generative_ai`)   |
| Charts             | `fl_chart`                                          |
| Voice input        | `speech_to_text`                                    |
| Notifications      | `flutter_local_notifications`                       |

## Architecture

State is managed with Riverpod — `StreamProvider`s for real-time Firestore data
and controllers for mutations. Routing uses GoRouter, which listens to auth and
profile state and enforces the flow **Splash → Auth → Onboarding → Dashboard**.

Data access follows the repository pattern:

- **Repositories** (`lib/repositories/`) — read/write a single Firestore collection.
- **Services** (`lib/services/`) — compose repositories into business logic.
- **Providers** (`lib/providers/`) — expose state to the UI and wire up controllers.

All user data lives under `/users/{uid}/` with subcollections for meals, daily
summaries, check-ins, weight entries, AI usage, and period reviews. Firestore
security rules enforce owner-only access.

Models use manual Firestore serialization (no codegen) — each has
`fromFirestore` / `toFirestore`, and enums use `fromString` factories that
tolerate legacy stored values.

```
lib/
├── app/           # App root + GoRouter setup
├── core/          # Theme, colors, config
├── helpers/       # Pure logic (health_calculator.dart)
├── models/        # UserProfile, Meal, DailySummary, CheckIn, WeightEntry, ...
├── providers/     # Riverpod providers & controllers
├── repositories/  # Firestore read/write per collection
├── screens/       # Auth, onboarding, dashboard, progress, review, account, ...
├── services/      # Daily summaries, calorie estimation, reviews, notifications
└── widgets/       # Shared UI components
```

## Getting started

### Prerequisites

- Flutter SDK with Dart `^3.11.4`
- A Firebase project (Auth + Firestore enabled)
- Firebase CLI (for deploys)
- A Google Gemini API key (for AI calorie estimation)

### Setup

```bash
flutter pub get
```

This project expects two pieces of local configuration that are not committed:

- `lib/firebase_options.dart` — generate with `flutterfire configure`.
- `lib/core/config/api_keys.dart` — holds the Gemini API key. Treat as sensitive.

### Run

```bash
flutter run -d chrome    # Web (primary target)
flutter run -d android   # Android device/emulator
```

## Testing & linting

```bash
flutter test                                   # Run all tests
flutter test test/health_calculator_test.dart  # Run a single test file
flutter analyze                                # Lint (flutter_lints)
```

Core domain logic is covered by unit tests, including the health calculator,
weight logging, and period reviews.

## Deploy

The web build outputs to `build/hosting`, served by Firebase Hosting with SPA
rewrites.

```bash
firebase deploy --only hosting          # Deploy the web build
firebase deploy --only firestore:rules  # Deploy Firestore security rules
```
