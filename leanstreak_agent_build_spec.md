# LeanStreak — Agent Build Specification (Flutter + Firebase)

## 1. How to use this document

This file is the **single source of truth** for building LeanStreak.

The local AI agent must follow this document **in order**.
Do **not** skip ahead.
Do **not** add extra features unless they are listed here.
Do **not** redesign the product into a full calorie tracking app.

The app goal is simple:

> Help users lose weight and improve health by making daily consistency easy to track, easy to understand, and rewarding.

This is **not** a macro-heavy nutrition app.
This is **not** a food database app.
This is **not** a social fitness app.

The product is a **low-friction habit + calorie consistency tracker** with:

- simple onboarding
- quick meal logging
- daily scoring
- daily category result
- weekly overview
- per-user stored review data

---

## 2. Product definition

### 2.1 Core product idea

LeanStreak is a Flutter mobile app using Firebase.
Each user creates an account, enters basic body and goal data, receives a calorie target, logs meals quickly, and sees how each day and each week went.

### 2.2 Main user promise

The app should make the user feel:

- "I know how I’m doing today"
- "I know how my week is going"
- "I know what to improve next"
- "I can stay on track without logging everything perfectly"

### 2.3 Product personality

The app should feel:

- simple
- calm
- modern
- motivating
- slightly game-like
- not childish
- not shame-based

### 2.4 Main UX rule

**Every important action should take as few taps as possible.**

Meal logging must be fast.
The home screen must be understandable in seconds.
Weekly review must be simple and useful.

---

## 3. Scope

## 3.1 In scope for v1

Build only these features:

- Flutter app
- Firebase Auth (email/password)
- Firestore storage per user
- first-time onboarding flow
- BMI calculation
- daily calorie target calculation
- simple meal logging
- meal quality tags
- daily scoring system
- daily category result
- home/dashboard
- review screen
- weekly overview page
- profile page with editable user details

## 3.2 Optional if very easy

These are allowed only if they do not slow down the core build:

- weight logging
- streak counter
- dark mode

## 3.3 Explicitly out of scope for v1

Do **not** build any of the following:

- barcode scanning
- food search database
- image recognition
- recipe builder
- macro breakdown per meal
- micronutrients
- premium subscriptions
- social feed
- comments/chat
- wearable integrations
- push notifications
- complex achievement system
- coach chat bot

---

## 4. Functional summary

A complete v1 should let the user do the following:

1. create an account
2. complete onboarding
3. receive BMI + daily calorie target
4. log meals using only calories + tags + meal type
5. see total calories for today
6. see today’s score and day category
7. see previous daily results in review
8. review how the last 7 days went
9. update profile details if needed

---

## 5. High-level user flow

### 5.1 Authentication flow

- User opens app.
- If unauthenticated -> show auth screen.
- User can sign up or sign in with email/password.
- After sign in:
  - if onboarding not completed -> go to onboarding
  - if onboarding completed -> go to home dashboard

### 5.2 Onboarding flow

Collect:

- name
- age
- gender
- height (cm)
- current weight (kg)
- activity level (Light / Medium / Hard)
- target weight (kg)
- target date

After submit:

- validate input
- calculate BMI
- calculate calorie target
- validate whether the goal pace is realistic
- save user profile to Firestore
- mark onboarding complete
- route to dashboard

### 5.3 Daily use flow

- User opens app.
- Dashboard shows current day summary.
- User taps “Log meal”.
- Enters calories.
- Selects meal type.
- Selects one or more tags.
- Saves meal.
- Dashboard updates automatically.
- Day score and category update automatically.

### 5.4 Weekly use flow

- User opens weekly overview page.
- Sees the last 7 days summary.
- Sees average score, total logged calories, day categories, top patterns, and short guidance.

---

## 6. Technical decisions

These decisions should be followed unless there is a strong technical reason not to.

### 6.1 Stack

- Flutter
- Dart
- Firebase Auth
- Cloud Firestore
- Firebase Core

### 6.2 Suggested architecture

Use **clean, simple feature-first architecture**.
Do not overengineer.
Avoid unnecessary abstraction.

Recommended structure:

- `lib/app/`
- `lib/core/`
- `lib/features/auth/`
- `lib/features/onboarding/`
- `lib/features/dashboard/`
- `lib/features/meals/`
- `lib/features/review/`
- `lib/features/summary/`
- `lib/features/profile/`
- `lib/shared/`

### 6.3 State management

Use **flutter_riverpod** or **Provider**.
Preferred choice: **flutter_riverpod**.
Keep it simple. No codegen required.

### 6.4 Navigation

Use `go_router`.

### 6.5 Data storage

Use Firestore for all user data.
Store everything under the authenticated user’s UID.

---

## 7. Required packages

Use only what is needed.

Suggested packages:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `flutter_riverpod`
- `go_router`
- `intl`
- `equatable` (optional)
- `uuid` (optional)

Do not add many packages unless necessary.

---

## 8. Data model

## 8.1 Firestore collections

Use this structure:

```text
users/{uid}
users/{uid}/meals/{mealId}
users/{uid}/daily_summaries/{yyyy-MM-dd}
users/{uid}/weekly_summaries/{yyyy-ww}   // optional cache, not required for v1
users/{uid}/weight_logs/{weightLogId}     // optional for v1
```

## 8.2 User document schema

Path: `users/{uid}`

```json
{
  "uid": "string",
  "email": "string",
  "name": "string",
  "age": 28,
  "gender": "male|female|other",
  "heightCm": 178,
  "currentWeightKg": 77,
  "targetWeightKg": 72,
  "activityLevel": "light|medium|hard",
  "targetDate": "timestamp",
  "bmi": 24.3,
  "bmr": 1712,
  "tdee": 2653,
  "dailyCalorieTarget": 2150,
  "goalPaceKgPerWeek": 0.45,
  "goalPaceLevel": "safe|caution|warning",
  "onboardingCompleted": true,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## 8.3 Meal document schema

Path: `users/{uid}/meals/{mealId}`

```json
{
  "id": "string",
  "date": "2026-04-12",
  "timestamp": "timestamp",
  "mealType": "breakfast|lunch|dinner|snack",
  "calories": 650,
  "tags": ["high_protein", "balanced", "home_cooked"],
  "note": "optional string",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## 8.4 Daily summary document schema

Path: `users/{uid}/daily_summaries/{yyyy-MM-dd}`

```json
{
  "date": "2026-04-12",
  "totalCalories": 1970,
  "targetCalories": 2150,
  "calorieDelta": -180,
  "mealCount": 3,
  "tagCounts": {
    "high_protein": 2,
    "balanced": 2,
    "processed": 1
  },
  "score": 6,
  "maxScore": 10,
  "category": "very_good|good|bad|very_bad",
  "explanation": [
    "Stayed within target range",
    "Had at least one high protein meal"
  ],
  "updatedAt": "timestamp"
}
```

## 8.5 Optional weight log schema

Path: `users/{uid}/weight_logs/{weightLogId}`

```json
{
  "id": "string",
  "weightKg": 76.4,
  "date": "2026-04-12",
  "timestamp": "timestamp",
  "note": "optional string"
}
```

---

## 9. Business rules

## 9.1 Activity levels

Keep activity options simple.
Show plain language help text in the UI.

- **Light**: little exercise, mostly sitting, low daily movement
- **Medium**: some walking or light exercise a few times per week
- **Hard**: regular training, active work, or high daily movement

### Activity multipliers

Use these:

- Light = `1.35`
- Medium = `1.55`
- Hard = `1.75`

## 9.2 BMI formula

Use:

```text
BMI = weightKg / ((heightCm / 100) ^ 2)
```

Show BMI as **reference only**.
Do not use BMI to calculate calories.

## 9.3 BMR formula

Use Mifflin-St Jeor.

For male:

```text
BMR = 10 * weightKg + 6.25 * heightCm - 5 * age + 5
```

For female:

```text
BMR = 10 * weightKg + 6.25 * heightCm - 5 * age - 161
```

If `other` is selected, use a neutral fallback rule or ask the agent to use the average of male and female formulas for v1.
Keep implementation simple and clearly commented.

## 9.4 TDEE formula

```text
TDEE = BMR * activityMultiplier
```

## 9.5 Goal pace logic

Calculate:

- `totalKgToLose = currentWeightKg - targetWeightKg`
- `daysToTarget = targetDate - today`
- `weeklyRequiredLoss = totalKgToLose / (daysToTarget / 7)`

Use these rules:

- `<= 0.75 kg/week` -> `safe`
- `> 0.75 and <= 1.00 kg/week` -> `caution`
- `> 1.00 kg/week` -> `warning`

## 9.6 Daily calorie target

Use the common approximation:

```text
1 kg fat ~= 7700 kcal
```

Then:

- calculate required total calorie deficit
- divide by days to target
- subtract from TDEE

```text
dailyCalorieTarget = TDEE - requiredDailyDeficit
```

### Safety floor

- Female minimum = `1200 kcal`
- Male minimum = `1500 kcal`
- If `other`, use a safe fallback floor such as `1350 kcal`

If the calculated target is below the minimum floor:

- clamp the target to the minimum
- show the user a message that the goal pace is too aggressive
- suggest extending the target date

---

## 10. Meal logging design

## 10.1 Meal types

Use these four:

- breakfast
- lunch
- dinner
- snack

## 10.2 Required meal fields

Every meal log must include:

- calories
- meal type
- at least 1 tag
- timestamp

Optional field:

- note

## 10.3 Meal tags

Use a short fixed list.
Do not let users create custom tags in v1.

### Positive tags

- balanced
- high_protein
- fruit_veg
- home_cooked
- filling

### Warning tags

- processed
- sugary
- fried
- alcohol
- overate

Keep labels user-friendly in UI.
Store values in normalized lowercase snake_case.

---

## 11. Daily scoring system

The app must calculate a day score automatically based on logged meals.
The app must also show **how the score was built**.
This explanation is required.

## 11.1 Scoring goal

The scoring system should:

- reward staying near calorie target
- reward better meal quality
- reward protein and balanced choices
- penalize obvious overeating patterns
- stay understandable
- not be perfect nutrition science

## 11.2 Proposed v1 scoring model

Use a **0 to 10** style system with positive and negative adjustments.
Clamp the result between `0` and `10`.

### Base scoring

Start each day at:

```text
score = 5
```

### Calorie adherence points

Compare `totalCalories` vs `dailyCalorieTarget`.

- within target ± 5% -> `+2`
- within target ± 10% -> `+1`
- above target by 10% to 20% -> `-1`
- above target by more than 20% -> `-2`
- below target by more than 25% -> `-1`

### Positive tag points

Add:

- at least 1 `high_protein` meal -> `+1`
- at least 1 `balanced` meal -> `+1`
- at least 2 total `fruit_veg` tags in the day -> `+1`

### Negative tag points

Subtract:

- `overate` tag present -> `-2`
- 2 or more `processed` tags in the day -> `-1`
- 2 or more `sugary` tags in the day -> `-1`
- `alcohol` and `overate` both present same day -> additional `-1`

### Logging completeness rule

- if no meals logged for the day -> category `very_bad`, score `0`, explanation `No meals logged`
- if only 1 meal logged -> no bonus or penalty, keep normal scoring

## 11.3 Daily category mapping

Map final score to category:

- `8 to 10` -> `very_good`
- `6 to 7` -> `good`
- `3 to 5` -> `bad`
- `0 to 2` -> `very_bad`

## 11.4 Score explanation

Store an array of explanation strings for the day.
Example:

- `Stayed close to calorie target`
- `Included at least one high protein meal`
- `Had an overeating meal`

The UI must show this clearly.
The user should never wonder why the day received its result.

---

## 12. Weekly review logic

The weekly review is a key feature.
It should summarize the last 7 days and give short guidance.

## 12.1 Weekly review content

Show:

- average daily score
- best day
- worst day
- number of very good / good / bad / very bad days
- total logged calories for the week
- average calories per day
- total meals logged
- most frequent positive tags
- most frequent warning tags
- short guidance section

## 12.2 Weekly guidance rules

Generate simple rule-based feedback.
Do not use AI summaries in v1.

### Example rules

If average score >= 8:

- `Excellent week. Keep repeating what worked.`

If average score between 6 and 7.99:

- `Solid week. Focus on reducing a few off-track meals.`

If average score < 6:

- `This week had some struggles. Focus on staying closer to your calorie target and reducing overeating meals.`

If `high_protein` appears often:

- `Protein choices are helping. Keep that up.`

If `overate` appears 2+ times:

- `Overeating happened multiple times this week. Focus on portion control and more filling meals.`

If `processed` or `sugary` tags are high:

- `Try replacing some processed or sugary meals with more balanced options.`

If meals were logged on fewer than 4 days:

- `Logging was inconsistent this week. Better logging will make the score more useful.`

## 12.3 Weekly range

Use a rolling last 7 days window.
Do not depend on calendar month logic.

---

## 13. Screen list

Build these screens only.

## 13.1 Splash / auth gate

Purpose:

- decide where the user goes on app launch

## 13.2 Auth screen

Features:

- sign in
- sign up
- loading states
- validation
- clear error messages

## 13.3 Onboarding screen

Features:

- form fields listed above
- activity level help text
- realistic goal warning
- submit button

## 13.4 Dashboard / home screen

Must show:

- greeting with user name
- today’s calorie target
- today’s total logged calories
- remaining calories
- today’s score
- today’s day category
- score explanation summary
- button to log meal
- quick link to review
- quick link to weekly review

## 13.5 Log meal screen / modal

Must show:

- calories input
- meal type selector
- tag multi-select
- optional note
- save button

## 13.6 Review screen

Must show:

- week and month options
- calendar-style day grid
- each day square can show a good icon, warning icon, or stay blank if no data
- tap day to see more detail

## 13.7 Weekly review screen

Must show:

- last 7 days summary
- average score
- category counts
- weekly guidance
- top helpful tags
- top risky tags

## 13.8 Profile screen

Must show:

- current profile values
- edit profile
- save changes
- recalculate bmi/tdee/target when relevant fields change
- sign out

---

## 14. UX and design rules

## 14.1 Visual style

Use a clean and calm UI.
Avoid clutter.
Avoid overly bright game UI.
Avoid childish visuals.

## 14.2 Home screen priority

The most important information must be visible immediately:

- calories today
- target today
- score today
- category today
- log meal button

## 14.3 Logging priority

The meal log must be fast.
Avoid nested steps if possible.

## 14.4 Language style

Use constructive language.
Do not shame the user.
Do not overpraise tiny actions.

Examples of good app copy:

- `Today is going well`
- `You stayed close to your target`
- `This week had some strong days`
- `Focus on one improvement next week`

---

## 15. Suggested folder structure

Use a simple feature-first structure similar to this:

```text
lib/
  app/
    app.dart
    router.dart
  core/
    constants/
    theme/
    utils/
    services/
  shared/
    widgets/
    models/
  features/
    auth/
      data/
      presentation/
    onboarding/
      data/
      domain/
      presentation/
    dashboard/
      data/
      domain/
      presentation/
    meals/
      data/
      domain/
      presentation/
    review/
      presentation/
    summary/
      domain/
      presentation/
    profile/
      data/
      presentation/
```

Keep the structure practical.
Do not create empty layers just for style.

---

## 16. Implementation order

This section is the most important part for the local AI agent.
Follow these phases in order.
Do not move to the next phase until the acceptance criteria for the current phase are met.

---

## Phase 1 — Project setup

### Tasks

1. Create Flutter project.
2. Add required dependencies.
3. Configure Firebase for Android, Web( ) and iOS.
4. Initialize Firebase in app startup.
5. Create base app theme.
6. Set up routing.
7. Add auth gate / splash decision screen.

### Acceptance criteria

- app runs successfully
- Firebase initializes correctly
- routes work
- app can open auth screen and placeholder home screen

---

## Phase 2 — Authentication

### Tasks

1. Build sign up screen.
2. Build sign in screen.
3. Add email/password validation.
4. Connect to Firebase Auth.
5. Handle auth loading and error states.
6. Route authenticated users correctly.

make it use the same route port number for web and remember the user once they login. And if they go to
the login screen just do the standard either biometric or rembmer of previous login details etc..

### Acceptance criteria

- user can sign up
- user can sign in
- user stays signed in after app restart
- auth errors are shown clearly

---

## Phase 3 — User profile model and Firestore integration

### Tasks

1. Create user profile model.
2. Create Firestore repository for user profile.
3. Implement create, read, and update methods.
4. Add onboarding completion flag.
5. Ensure all data is stored under UID.

### Acceptance criteria

- user profile document is created
- onboardingCompleted can be read reliably
- profile can be updated and reloaded

---

## Phase 4 — Onboarding UI and validation

### Tasks

1. Build onboarding form.
2. Add validation for all fields.
3. Add activity level explanations.
4. Add target date picker.
5. Add realistic goal pace warning state.
6. Save completed onboarding data.

### Acceptance criteria

- onboarding form works end to end
- invalid values are blocked
- realistic goal pace warning is shown when needed
- onboarding sends user to dashboard after completion

---

## Phase 5 — Health calculations

### Tasks

1. Implement BMI calculator.
2. Implement BMR calculator.
3. Implement TDEE calculator.
4. Implement goal pace calculator.
5. Implement daily calorie target calculator.
6. Implement safe minimum calorie floor.
7. Save all derived values to the user document.

### Acceptance criteria

- BMI is correct
- BMR/TDEE calculations are correct
- calorie target is calculated correctly
- unrealistic goals are flagged properly

---

## Phase 5.5 — AI calorie estimator

### Overview

Users often do not know how many calories a meal contains.
This phase adds a lightweight AI estimation button inside the meal logging flow.
The user describes their meal in plain language and the app returns a calorie estimate instantly.

No food database is used. Natural language descriptions ("a big bowl of pasta with tomato sauce",
"chicken wrap from the cafe") are handled better by AI than by a keyword search index.

### Data source

- **Google Gemini 2.5 Flash** via `google_generative_ai` Dart package
  - Free tier: 1,500 requests/day (sufficient for personal and small-scale use)
  - Paid tier if exceeded: ~$0.00005 per estimate — negligible at any realistic scale
  - One API key from Google AI Studio (no credit card required)

### Daily usage limit

Each user is limited to **10 AI estimates per day**.
Usage is tracked in Firestore at `users/{uid}/ai_usage/{yyyy-MM-dd}` as `{ count: int }`.
The document path changes every day, so the counter resets automatically at midnight.
This keeps the free Gemini tier well within limits even across many users, and is trivial to raise later.

### Tasks

1. Add `google_generative_ai` package to `pubspec.yaml`.
2. Store the Gemini API key in `lib/core/config/api_keys.dart` (add to `.gitignore`).
3. Create `AiUsageRepository` — reads and increments the daily count in Firestore.
4. Create `CalorieEstimateService` — checks usage limit, calls Gemini, parses response, increments count.
5. Add an "Estimate with AI" button below the calorie input in `log_meal_sheet.dart`.
6. Tapping it reveals an inline description field. User types their meal and taps **"Estimate"**.
7. Show a loading indicator, then display the result card with kcal + one-line note.
8. **"Use this"** pre-fills the calorie input (still editable).
9. Show remaining estimates for the day (e.g. "7 of 10 remaining").
10. When limit is reached, disable the button and show "Daily limit reached — resets tomorrow".

### Prompt design

```
You are a nutrition assistant. The user will describe a meal.
Respond with ONLY a JSON object: {"kcal": <integer>, "note": "<one short sentence explaining the estimate>"}.
Do not include any other text. Be concise and practical — estimate for a typical portion.

Meal: {userInput}
```

### UX flow

1. User is on the log meal sheet, calorie field is empty (or they are unsure).
2. They tap **"Not sure? Estimate with AI"** (shows remaining count e.g. "7 of 10 left today").
3. A small text field expands inline. User types their meal description and taps **"Estimate"**.
4. Loading spinner shown, then result card appears:
   > **~480 kcal** — Typical grilled chicken wrap with lettuce and sauce.
5. **"Use this"** fills the calorie input. User can adjust before saving.
6. If the daily limit is hit, button shows "Daily limit reached — resets tomorrow" and is disabled.
7. If the API fails, show a short error and let the user type calories manually.

### Acceptance criteria

- Estimate returns a reasonable kcal number for common meal descriptions
- Daily usage is tracked correctly and resets each day
- Button is disabled when limit is reached with a clear message
- Remaining count is visible to the user
- Result pre-fills the calorie input correctly
- API key is not committed to git
- App works normally if the service is unavailable (graceful error, manual entry still works)

---

## Phase 6 — Meal logging feature

### Tasks

1. Create meal model.
2. Create Firestore meal repository.
3. Build log meal UI.
4. Add meal type selector.
5. Add calorie input.
6. Add tag multi-select.
7. Save meals to Firestore.
8. Support editing and deleting meals only if easy; otherwise skip for v1.

### Acceptance criteria

- user can log meals
- meals are saved under correct date and user
- meal list can be read back correctly

---

## Phase 7 — Daily summary calculation

### Tasks

1. Create daily summary model.
2. Build service that aggregates all meals for a date.
3. Calculate total calories.
4. Count tags.
5. Calculate score.
6. Calculate category.
7. Generate explanation strings.
8. Save/update daily summary document.

### Acceptance criteria

- adding a meal updates daily summary correctly
- score logic works consistently
- category matches score mapping
- explanation is visible and understandable

---

## Phase 8 — Dashboard

### Tasks

1. Build home dashboard.
2. Show greeting and today summary.
3. Show calories vs target.
4. Show remaining calories.
5. Show today’s score.
6. Show today’s category.
7. Show score explanation.
8. Add clear button to log meal.
9. Add links to review and weekly review.

### Acceptance criteria

- dashboard loads fast
- dashboard reflects real meal data
- user can understand today’s status immediately

---

## Phase 9 — Review screen

### Tasks

1. Replace the history list concept with a review screen.
2. Add week and month options on the same screen.
3. Build clickable calendar day cells from daily summaries.
4. Show a clear visual state for good days, warning days, and blank days.
5. Reuse a simple day detail view on tap.

### Acceptance criteria

- previous days are visible in calendar form
- daily data is accurate
- review is easy to scan

---

## Phase 9.5 CHANGES — Monthly review calendar

### Tasks

1. Build the month calendar layout for the review screen.
2. Add month-to-month navigation.
3. Keep empty days visible but blank when no data exists.
4. Add a quick link to review from the dashboard.

### Acceptance criteria

- month review loads correctly
- month navigation works
- the dashboard can open review quickly

---

## Phase 10 — Weekly review

### Tasks

1. Read last 7 daily summaries.
2. Calculate weekly stats.
3. Build weekly review UI.
4. Add rule-based guidance text.
5. Highlight best and worst day.
6. Show common tag patterns.

### Acceptance criteria

- weekly review shows last 7 days correctly
- average score is correct
- guidance matches weekly data
- page feels useful, not noisy

---

## Phase 11 — Profile editing

### Tasks

1. Build profile page.
2. Allow editing of user profile fields.
3. Recalculate BMI/BMR/TDEE/target when relevant fields change.
4. Save updated profile.
5. Add sign out.

### Acceptance criteria

- user can update profile
- recalculated values save correctly
- user can sign out safely

---

## Phase 12 — Polish and cleanup

### Tasks

1. Improve loading states.
2. Improve empty states.
3. Improve validation messages.
4. Improve spacing and visual hierarchy.
5. Remove dead code.
6. Ensure naming consistency.
7. Confirm all screens work on small devices.

### Acceptance criteria

- app feels cohesive
- no broken flows
- no major visual issues
- no obvious dead-end states

---

## 17. Logic details the agent must respect

## 17.1 Daily summary update strategy

Whenever a meal is added, updated, or deleted:

1. fetch all meals for that date
2. recalculate the daily summary from scratch
3. overwrite the daily summary document for that date

This is simpler and safer than incremental partial updates in v1.

## 17.2 Weekly review update strategy

For v1, calculate weekly review on demand from the last 7 daily summaries.
Do **not** build background summary caching unless needed.

## 17.3 Date handling

Store both:

- machine-safe date key (`yyyy-MM-dd`)
- timestamp

Use local time carefully when grouping meals by day.
Avoid UTC date boundary mistakes.

---

## 18. Error handling requirements

The app must handle the following cleanly:

- no internet
- Firebase unavailable
- auth failure
- Firestore read/write error
- missing profile data
- empty day with no meals
- invalid numeric input

Use simple, clear messages.
Do not expose raw exception text to the user.

---

## 19. Testing checklist

The agent should test these flows before considering the app complete.

### Auth

- sign up works
- sign in works
- sign out works
- session persists

### Onboarding

- all fields validate correctly
- target date in the past is rejected
- target weight above current weight is handled clearly
- calorie target is computed correctly

### Meal logging

- meal saves correctly
- day total updates correctly
- tags save correctly
- review reflects new data

### Scoring

- day near target scores better than day far above target
- overeating penalizes score
- high protein and balanced meals improve score
- no meals logged gives very_bad and score 0

### Weekly review

- 7 day averages are correct
- category counts are correct
- guidance changes based on patterns

### Profile

- editing profile recalculates derived values
- updated target reflects on next daily summaries

---

## 20. Definition of done

The app is considered complete for v1 only when all of the following are true:

- authentication works
- onboarding works
- user profile persists correctly
- BMI and calorie target are calculated correctly
- meals can be logged quickly
- daily summaries are generated correctly
- daily score and category are visible and understandable
- weekly review works and gives useful guidance
- data is stored per user in Firebase
- the UI is simple, clean, and not cluttered

---

## 21. Final implementation notes for the local AI agent

1. Keep the build small and focused.
2. Prefer correctness and clarity over clever architecture.
3. Prefer simple recomputation over fragile optimization.
4. Do not add features outside scope.
5. Do not turn the app into a nutrition database product.
6. Do not overcomplicate the UI.
7. The product wins by being easy, fast, and motivating.

//THINGS TO CONSIDER !!!!!

-SHOULD WE ALSO COUNT MACROS, Like protein, carbs,fats

-ALSO SHOULD WE TRACK THE PROGRESS OF HTE USER weekly/monthly.
LIKE ASK THEM FOR CHANGES? For example if they lost 2 kg that week is the formula the same or it needs recalculating?

-Maybe after the end of each week, we should display a dialog with a form to the user showing them the review summary, asking them for any info or notes of how it went.. etc.. (or maybe something extra idk???)

-WHAT ABOUT WORKOUTS ?? Can we do a simillar logging for workouts?
