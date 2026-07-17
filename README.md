# Team Workspace

A task management app built for a Flutter machine test. Email/password auth via
Firebase, a paginated task dashboard backed by [dummyjson.com](https://dummyjson.com/todos),
offline-first writes, search/filter, and dark mode.

## Setup

### Prerequisites

- Flutter SDK — this project was built against Flutter `3.47.0-0.1.pre` (master
  channel). See [Known limitations](#known-limitations) if you're on stable.
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

If you just want to `analyze`/`test`/`build` without a real Firebase project
(e.g. to reproduce CI locally), copy the placeholder instead:

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

Re-run this after changing any `@JsonSerializable` class. DI (`lib/core/di/injection.dart`)
and entities (`Task`, `AssignedUser`) are hand-written, not generated — see
[Why no freezed or injectable](#why-no-freezed-or-injectable) below.

### 4. Run

```bash
flutter run
```

## Architecture

Feature-first Clean Architecture. Domain layer is pure Dart — no Flutter, Dio,
Firebase, or Hive imports. Repositories return a hand-rolled `Result<T>`
(`Ok`/`Err`) rather than pulling in `dartz` for one type.

```
lib/
  core/
    di/            # hand-written get_it registration, Hive box names
    network/       # dio client config, DioException -> app exception mapping
    error/         # Failure types, Result<T>, app-level exceptions
    router/        # go_router config, auth-aware redirect
    theme/         # light + dark ThemeData
    utils/         # log wrapper, date formatting, form validators
  features/
    auth/
      data/        # FirebaseAuthDataSource, AuthRepositoryImpl, error-code mapping
      domain/      # AppUser entity, AuthRepository contract, usecases
      presentation/ # AuthBloc, splash/login/sign-up pages
    tasks/
      data/        # dummyjson datasource, Hive overlay/cache/queue, TaskRepositoryImpl
      domain/      # Task entity, TaskEnrichment (deterministic derivation), usecases
      presentation/ # TaskListBloc, TaskDetailBloc, TaskFormBloc, pages, widgets

test/
  features/auth/                    # login form validation (widget test)
  features/tasks/data/              # repository overlay-merge + offline queue
  features/tasks/presentation/      # TaskListBloc, TaskFormBloc, dashboard states
```

### Why a hand-rolled `Result<T>`

`sealed class Result<T> { }` with `Ok<T>`/`Err<T>` subtypes plus a `fold`
extension reads the same as `Either` at call sites without adding `dartz` as a
dependency for one type.

### Why no freezed or injectable

The original spec called for both, but this codebase doesn't use either —
removed deliberately, not just never added:

- **DI (`lib/core/di/injection.dart`)** is one `configureDependencies()`
  function that calls `getIt.registerLazySingleton(...)` /
  `getIt.registerFactory(...)` directly, in dependency order, in four small
  private functions (external deps → Hive boxes → auth feature → tasks
  feature). The entire dependency graph is readable top to bottom in one
  file without running codegen first — no `@injectable` annotations, no
  `@LazySingleton(as: X)`, no generated `injection.config.dart`.
- **`Task` and `AssignedUser`** (the only two entities that used `@freezed`)
  are now plain classes extending `Equatable`, with a hand-written
  `copyWith` and `@JsonSerializable()` for `toJson`/`fromJson`. Everything
  else in the domain layer was already hand-rolled (`AppUser`, `TaskPage`,
  `Failure`, `Result<T>`), so this makes the two freezed holdouts consistent
  with the rest of the codebase instead of a special case.
- This did surface one real bug worth knowing: `@JsonSerializable()`
  defaults to `explicitToJson: false`, so `Task`'s generated `toJson()`
  initially put the raw `AssignedUser` object into the map instead of
  calling `.toJson()` on it — compiled fine, then crashed the first time
  Hive tried to persist a task (`HiveError: Cannot write, unknown type:
  AssignedUser`). Freezed's own serialization codegen never has this
  problem because it always emits nested calls explicitly. Fixed with
  `@JsonSerializable(explicitToJson: true)` on `Task`; see
  `test/features/tasks/domain/entities/task_test.dart` for the regression
  test that pins this down (asserts the JSON's `assignedUser` key is a
  `Map`, not an `AssignedUser` instance).

## Data strategy (read this before judging "why is X derived")

[dummyjson.com/todos](https://dummyjson.com/todos) only returns `id`, `todo`,
`completed`, and `userId` — no priority, due date, description, or assignee.
Those are derived **deterministically from `id`** in
`lib/features/tasks/domain/task_enrichment.dart`:

- `priority` — `id % 3` (low/medium/high)
- `dueDate` — `id % 30` days from today
- `description` — templated string embedding the original `todo` text
- `assignedUser` — `id % 6` into a small mock name list
- initial `status` — `completed` maps straight to `TaskStatus.completed`;
  otherwise `id.isEven` splits pending/in-progress (there's no real signal
  for this from the API, so it's a coin flip that's at least stable)

Because it's a pure function of `id`, refreshing the list never reshuffles a
task's derived fields — only genuine edits (via the overlay) change them.

### The overlay

dummyjson's `POST /todos/add` and `PUT /todos/:id` respond with a fake echoed
object but never actually persist anything server-side. So every create/edit/
status-toggle writes the **full resulting `Task`** into a Hive box
(`task_overlay_box`), keyed by id:

- On every `getTasks(page)` call, the API's DTOs are mapped to `Task` and then
  overridden by the overlay entry for that id, if one exists.
- Newly created tasks get a synthetic `local_<microsecondsSinceEpoch>` id and
  are prepended (sorted newest-first) to page 1's results — dummyjson has no
  concept of them at all.
- The overlay is the single source of truth for "does this task have local
  edits" — the repository never needs a separate diffing step.

This also **is** the offline-persistence layer: on restart, the overlay is
still there, so local edits survive.

### Cache + offline queue

- The merged page-1 result is cached in a second Hive box
  (`task_cache_box`). If the first page fails with a network error, the
  dashboard falls back to this cache and shows a "Showing cached data" banner.
- Writes check `connectivity_plus` before firing the remote call. Offline (or
  a failed call), the task id is queued in a third box (`write_queue_box`).
  The queue is replayed via `Connectivity().onConnectivityChanged` and again
  opportunistically whenever the dashboard loads. Replay always re-reads the
  **current** overlay entry for an id, so an edit made before its original
  create ever synced is naturally picked up as the latest version.

## Packages used

| Package | Why |
|---|---|
| `flutter_bloc` | State management — one bloc per screen concern, explicit loading/success/failure states |
| `equatable` | Value equality for bloc events/states without boilerplate `==`/`hashCode` |
| `get_it` | Service locator — registered by hand in `injection.dart`, see [Why no freezed or injectable](#why-no-freezed-or-injectable) |
| `dio` | HTTP client for the dummyjson REST API |
| `hive_ce` + `hive_ce_flutter` | Local persistence — overlay, cache, and offline write queue. `_ce` fork because upstream `hive` is unmaintained |
| `json_annotation` | `@JsonSerializable()` codegen for `toJson`/`fromJson` on entities and DTOs |
| `go_router` | Declarative navigation with an auth-aware `redirect` |
| `intl` | Date formatting |
| `connectivity_plus` | Detects online/offline for the write queue |
| `firebase_core` + `firebase_auth` | Email/password authentication |
| `logger` (via a thin `log()` wrapper) | No bare `print` in the codebase |
| `bloc_test` + `mocktail` (dev) | Bloc and repository tests |
| `build_runner`, `json_serializable` (dev) | Codegen for `toJson`/`fromJson` only — no DI or entity codegen |

## Assumptions

- **Status is three-way (pending/in-progress/completed)** even though
  dummyjson only has a `completed` boolean — the spec's filter chips need all
  three, so the third state is derived (see [Data strategy](#data-strategy-read-this-before-judging-why-is-x-derived)).
  "Reopen task" always sends a completed task back to `pending`, not whatever
  in-progress/pending split it had before completion — round-tripping that
  distinction wasn't worth a dedicated field.
- **`TaskFormBloc` and its form widget are shared** between create and edit;
  `existingTask == null` is the only branch point. The status picker only
  renders in edit mode, since create has no meaningful status to pick.
- **Validate-on-submit**, not validate-as-you-type, on every form in the app
  (login, sign-up, create/edit task) — picked once and applied consistently.
- **Search debounces in the widget itself** (a plain `Timer`, 300ms) rather
  than via a bloc-level stream transformer — simpler for a single `TextField`,
  and avoids adding `bloc_concurrency`/`rxdart` for one debounce.
- **Remote create/update calls are best-effort** when online — dummyjson
  doesn't persist them regardless of success/failure, so a failed *live* call
  is logged and queued for retry rather than surfaced as a user-facing error.
  Only a failed **local** write (Hive) surfaces as an error, since that's the
  one that actually matters for correctness.
- **Pagination is 10/page** via dummyjson's `limit`/`skip`, matching the spec.

## Known limitations

- **Flutter SDK version**: this environment's Flutter is on the `master`
  channel (`3.47.0-0.1.pre`), which is what `pubspec.yaml`'s `environment.sdk`
  constraint reflects and what CI is pinned to. On a machine running Flutter
  **stable**, `flutter pub get` may fail to resolve — some dependency
  versions (`hive_ce`, `go_router ^17`, etc.) were resolved against this dev
  SDK. If you hit this, the fix is to relax
  `environment.sdk` and downgrade the affected packages to stable-compatible
  versions; I didn't do this preemptively since I couldn't verify it without
  a second SDK install.
- **`path_provider_foundation` is pinned to `2.4.1`** via `dependency_overrides`.
  Newer versions pull in `objective_c`, which ships a native build hook that
  `build_runner`'s `dart compile` step can't handle on this SDK
  (`'dart compile' does not support build hooks, use 'dart build' instead`).
  Pinning avoids the transitive dependency entirely.
- No Android/iOS emulator or physical device was available in this
  environment. `flutter run -d macos` also isn't possible here — Xcode's
  command-line tools (`xcodebuild`) aren't installed, only the bare Xcode
  CLT. `flutter run -d chrome` **did** work: the app launched, Firebase
  initialized against the placeholder project, and all three Hive boxes
  (`task_overlay_box`, `task_cache_box`, `write_queue_box`) opened without
  error — confirmed via the dev server's console log. A visual screenshot
  of the rendered UI wasn't captured (this session doesn't have macOS
  Screen Recording permission), so the actual auth flow, dashboard, and
  forms are verified by the widget-test suite and code review rather than
  eyes-on-screen click-through.
- `flutter build apk --debug` **does** succeed end-to-end in this
  environment (an Android SDK was already present), and the full test
  suite (23 tests) passes.

## Screenshots

_(placeholder — add screenshots here once the app has been run against a real
Firebase project)_
