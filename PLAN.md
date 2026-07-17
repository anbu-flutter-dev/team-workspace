# Team Workspace — Build Plan

1. Project scaffold — pubspec deps, folder skeleton, .gitignore, analysis_options
2. Core — di (get_it/injectable), network (dio), error (Failure/Result), theme, router skeleton
3. Auth data/domain — entities, repository contract, Firebase datasource, repository impl
4. Auth presentation — AuthBloc, splash, login, sign-up pages
5. Tasks data/domain — entities, repository contract, dummyjson datasource, Hive overlay, repository impl
6. Dashboard — TaskListBloc, paginated list UI, pull-to-refresh, loading/empty/error states
7. Task details — TaskDetailBloc, optimistic complete/reopen, task-updated stream
8. Create task — TaskFormBloc, form UI, validation
9. Edit task — reuse form + status field
10. Search & filter — debounced search, filter chips, client-side compose
11. Offline queue + sync — connectivity_plus, write queue, replay on reconnect
12. Tests — bloc_test/mocktail for TaskListBloc, TaskFormBloc, repository; widget tests
13. Dark mode — ThemeMode.system, light/dark themes
14. CI — GitHub Actions (analyze, test, build apk debug)
15. README polish — setup, architecture, packages, assumptions, screenshots placeholder

Delete this file before the final commit.
