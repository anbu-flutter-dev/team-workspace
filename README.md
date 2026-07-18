# Team Workspace

A task management app built for a Flutter machine test. Email/password auth via
Firebase, a paginated task dashboard backed by [dummyjson.com](https://dummyjson.com/todos),
offline-first writes with an explicit sync-status signal, pull-to-refresh,
search/filter, and light/dark/system theme switching.

## Setup instructions

### Prerequisites

- Flutter SDK — built against Flutter `3.44.6`;
- A Firebase project (for email/password auth)

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Firebase (manual step)

This repo does not include `lib/firebase_options.dart`, `android/app/google-services.json`,
or `ios/Runner/GoogleService-Info.plist` — they're gitignored because they're
per-Firebase-project. To run the app for real:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Authentication → Sign-in method → Email/Password**.
3. Install the FlutterFire CLI if you don't have it: `dart pub global activate flutterfire_cli`.
4. From the project root, run:
   ```bash
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` and the platform config files, and
   registers Android/iOS apps against your Firebase project.
5. Run the app: `flutter run`.

If you just want to `analyze`/`test`/`build` without a real Firebase project,
copy the placeholder instead:

```bash
cp lib/firebase_options.sample.dart lib/firebase_options.dart
```

The placeholder has fake credentials — auth calls will fail at runtime, but
the app compiles and the widget/bloc test suite doesn't touch real Firebase.

### 3. Generate code

`*.g.dart` files (json_serializable output) are gitignored — generate them with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run

```bash
flutter run
```

### 5. Test

```bash
flutter test
flutter analyze
```

## Architecture overview

Feature-first Clean Architecture. Domain layer is pure Dart — no Flutter, Dio,
Firebase, Hive, or JSON-serialization imports. Repositories return a hand-rolled
`Result<T>` (`Ok`/`Err`) rather than pulling in `dartz` for one type. DI is
hand-written (`lib/core/di/injection.dart`, one `configureDependencies()`
function using `get_it` directly) — no `freezed`/`injectable` codegen.

```
lib/
  core/
    analytics/     # AnalyticsService abstraction, console impl, GoRouter screen-view observer
    di/            # hand-written get_it registration, Hive box names
    network/       # dio client config, DioException -> app exception mapping
    error/         # Failure types, Result<T>, app-level exceptions
    router/        # go_router config, auth-aware redirect
    theme/         # light + dark ThemeData, ThemeCubit (Hive-persisted mode)
    utils/         # log wrapper, date formatting, form validators
  features/
    auth/
      data/        # FirebaseAuthDataSource, AuthRepositoryImpl, error-code mapping
      domain/      # AppUser entity, AuthRepository contract, usecases
      presentation/ # AuthBloc, splash/login/sign-up pages
    tasks/
      data/        # dummyjson datasource + DTOs, Hive overlay/cache/queue, data models
                    # (TaskModel/AssignedUserModel + entity mappers), TaskRepositoryImpl
      domain/      # Task/AssignedUser entities (no serialization), TaskSaveOutcome,
                    # TaskEnrichment (deterministic derivation), usecases
      presentation/ # TaskListBloc, TaskDetailBloc, TaskFormBloc, pages, widgets

test/
  core/                              # DI lifecycle, DioException mapping, form validators
  features/auth/                    # AuthBloc, login/sign-up form validation
  features/tasks/data/              # repository overlay-merge, offline queue + sync status,
                                     # real-Hive round trips, data-model serialization
  features/tasks/domain/            # Task entity behavior
  features/tasks/presentation/      # TaskListBloc, TaskFormBloc, TaskFormView, dashboard states
```

Domain entities (`Task`, `AssignedUser`) have no serialization coupling —
`@JsonSerializable` only exists on data-layer models (`TaskModel`,
`AssignedUserModel`, `TaskDto`), which convert to/from the entities at the
boundary. Hive persistence (overlay, cache, offline write queue) and dummyjson
API responses both go through this data layer; the domain layer and blocs
only ever see `Task`.

## Packages used

| Package | Why |
|---|---|
| `flutter_bloc` | State management — one bloc per screen concern, explicit loading/success/failure states |
| `equatable` | Value equality for bloc events/states without boilerplate `==`/`hashCode` |
| `get_it` | Service locator — registered by hand in `injection.dart`, no `injectable` codegen |
| `dio` | HTTP client for the dummyjson REST API |
| `hive_ce` + `hive_ce_flutter` | Local persistence — overlay, cache, offline write queue, and theme-mode settings. `_ce` fork because upstream `hive` is unmaintained |
| `json_annotation` | `@JsonSerializable()` codegen for `toJson`/`fromJson` on data-layer models and DTOs only — never on domain entities |
| `go_router` | Declarative navigation with an auth-aware `redirect` and a screen-view route observer |
| `intl` | Date formatting |
| `connectivity_plus` | Detects online/offline for the write queue |
| `firebase_core` + `firebase_auth` | Email/password authentication |
| `logger` (via a thin `log()` wrapper) | No bare `print` in the codebase |
| `bloc_test` + `mocktail` (dev) | Bloc and repository tests |
| `build_runner`, `json_serializable` (dev) | Codegen for `toJson`/`fromJson` only — no DI or entity codegen |

## Assumptions made

- **Status is three-way (pending/in-progress/completed)** even though
  dummyjson only has a `completed` boolean — the spec's filter chips need all
  three, so the third state is derived from `id` (see `task_enrichment.dart`).
  "Reopen task" always sends a completed task back to `pending`, not whatever
  in-progress/pending split it had before completion.
- **`TaskFormBloc` and its form widget are shared** between create and edit;
  `existingTask == null` is the only branch point. The status picker only
  renders in edit mode, since create has no meaningful status to pick.
- **Validate-on-submit**, not validate-as-you-type, on every form in the app
  (login, sign-up, create/edit task).
- **Search debounces in the widget itself** (a plain `Timer`, 300ms) rather
  than via a bloc-level stream transformer.
- **Remote create/update calls are best-effort** when online — dummyjson
  doesn't persist them regardless of success/failure, so a failed *live* call
  is logged and queued for retry rather than surfaced as a user-facing error.
  Only a failed **local** write (Hive) surfaces as an error. The UI still
  distinguishes a fully-synced write from a locally-queued one ("Task
  created" vs. "Saved locally. Will sync when online.") via a `TaskSaveOutcome`
  returned alongside the task, so a queued write is never reported as a plain
  success.
- **Pagination is 10/page** via dummyjson's `limit`/`skip`, matching the spec.

## Screenshots
![alt text](Screenshot_1784376136.png)

![alt text](Screenshot_1784376169.png)

![alt text](Screenshot_1784376178.png)

![alt text](Screenshot_1784377469.png)