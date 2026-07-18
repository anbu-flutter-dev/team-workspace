import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/analytics/analytics_service.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/core/network/api_constants.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/repositories/task_repository.dart';
import 'package:team_workspace/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_state.dart';

class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc(this._getTasks, this._repository, this._analytics)
    : super(const TaskListLoading()) {
    on<TaskListStarted>(_onStarted);
    on<TaskListRefreshRequested>(_onRefreshRequested);
    on<TaskListNextPageRequested>(_onNextPageRequested);
    on<TaskUpdateReceived>(_onTaskUpdateReceived);
    on<TaskListSearchQueryChanged>(_onSearchQueryChanged);
    on<TaskListStatusFilterToggled>(_onStatusFilterToggled);
    on<TaskListPriorityFilterToggled>(_onPriorityFilterToggled);
    on<TaskListFiltersCleared>(_onFiltersCleared);
    _taskUpdatesSubscription = _repository.taskUpdates.listen(
      (task) => add(TaskUpdateReceived(task)),
    );
  }

  final GetTasksUseCase _getTasks;
  final TaskRepository _repository;
  final AnalyticsService _analytics;
  late final StreamSubscription<Task> _taskUpdatesSubscription;
  Completer<void>? _refreshCompleter;

  /// Bumped on every full reload (initial load or refresh) — an in-flight
  /// next-page fetch reads this again after its await, so it can tell a
  /// refresh reset the list out from under it and drop its own stale
  /// result instead of appending onto data that's no longer current.
  int _loadGeneration = 0;

  /// True while a page fetch triggered by [_fetchNextPage] is in flight.
  /// Set synchronously before any `await`, so back-to-back scroll-triggered
  /// `TaskListNextPageRequested` events (processed concurrently by the
  /// bloc's default event transformer) can't both pass the `hasMore` check
  /// and fire duplicate requests for the same next page — checking
  /// `state.isLoadingNextPage` alone isn't enough, since that only becomes
  /// true after the first fetch's own `emit` has round-tripped.
  bool _isFetchingNextPage = false;

  /// Fires a refresh and returns a Future that resolves once it (and any
  /// pagination top-up) is fully done — used by RefreshIndicator. Not based
  /// on racing `stream.firstWhere` against `add()`: this bloc never emits
  /// TaskListLoading during a refresh, so the first post-refresh emission
  /// can be an intermediate pagination state rather than the final one,
  /// and depending on scheduling that race can also simply be lost,
  /// leaving the spinner stuck forever.
  Future<void> refresh() {
    final completer = Completer<void>();
    _refreshCompleter = completer;
    add(const TaskListRefreshRequested());
    return completer.future;
  }

  Future<void> _onStarted(
    TaskListStarted event,
    Emitter<TaskListState> emit,
  ) async {
    _loadGeneration++;
    emit(const TaskListLoading());
    unawaited(_repository.syncPendingOperations());
    final result = await _getTasks(page: 1);
    result.fold(
      (failure) => emit(TaskListLoadFailure(failure.message)),
      (page) => emit(
        TaskListLoadSuccess(
          tasks: page.tasks,
          currentPage: 1,
          hasMore: page.hasMore,
          isFromCache: page.isFromCache,
        ),
      ),
    );
  }

  Future<void> _onRefreshRequested(
    TaskListRefreshRequested event,
    Emitter<TaskListState> emit,
  ) async {
    _loadGeneration++;
    final result = await _getTasks(page: 1);
    result.fold(
      (failure) {
        final current = state;
        if (current is TaskListLoadSuccess) {
          emit(current.copyWith(paginationError: failure.message));
        } else {
          emit(TaskListLoadFailure(failure.message));
        }
      },
      (page) => emit(
        TaskListLoadSuccess(
          tasks: page.tasks,
          currentPage: 1,
          hasMore: page.hasMore,
          isFromCache: page.isFromCache,
        ),
      ),
    );
    await _ensureEnoughFilteredResults(emit);
    _refreshCompleter?.complete();
    _refreshCompleter = null;
  }

  Future<void> _onNextPageRequested(
    TaskListNextPageRequested event,
    Emitter<TaskListState> emit,
  ) async {
    // await Future.delayed(const Duration(seconds: 2));
    await _fetchNextPage(emit);
  }

  /// Returns false if there was nothing more to fetch or a fetch failed.
  Future<bool> _fetchNextPage(Emitter<TaskListState> emit) async {
    if (_isFetchingNextPage) return false;
    final current = state;
    if (current is! TaskListLoadSuccess) return false;
    if (!current.hasMore) return false;

    _isFetchingNextPage = true;
    final generation = _loadGeneration;
    emit(current.copyWith(isLoadingNextPage: true, paginationError: null));
    try {
      final nextPage = current.currentPage + 1;
      final result = await _getTasks(page: nextPage);

      // A refresh (or restart) may have reset the list while this was in
      // flight — re-read state instead of trusting `current`, which was
      // captured before the await and would otherwise silently clobber
      // whatever landed in the meantime with a page appended onto stale data.
      if (generation != _loadGeneration) return false;
      final latest = state;
      if (latest is! TaskListLoadSuccess) return false;

      var fetchedMore = false;
      result.fold(
        (failure) => emit(
          latest.copyWith(
            isLoadingNextPage: false,
            paginationError: failure.message,
          ),
        ),
        (page) {
          fetchedMore = true;
          emit(
            latest.copyWith(
              tasks: [...latest.tasks, ...page.tasks],
              currentPage: nextPage,
              hasMore: page.hasMore,
              isLoadingNextPage: false,
            ),
          );
        },
      );
      return fetchedMore;
    } finally {
      _isFetchingNextPage = false;
    }
  }

  /// When a filter/search narrows the visible list, keep pulling pages
  /// underneath until there's enough to show or the API runs dry.
  Future<void> _ensureEnoughFilteredResults(Emitter<TaskListState> emit) async {
    while (true) {
      final current = state;
      if (current is! TaskListLoadSuccess) return;
      if (!current.hasActiveFilters) return;
      if (current.filteredTasks.length >= ApiConstants.pageSize) return;
      if (!current.hasMore || current.isLoadingNextPage) return;
      final fetchedMore = await _fetchNextPage(emit);
      if (!fetchedMore) return;
    }
  }

  void _onTaskUpdateReceived(
    TaskUpdateReceived event,
    Emitter<TaskListState> emit,
  ) {
    final current = state;
    if (current is! TaskListLoadSuccess) return;

    final index = current.tasks.indexWhere((t) => t.id == event.task.id);
    final updatedTasks = index == -1
        ? [event.task, ...current.tasks]
        : (List.of(current.tasks)..[index] = event.task);
    emit(current.copyWith(tasks: updatedTasks));
  }

  Future<void> _onSearchQueryChanged(
    TaskListSearchQueryChanged event,
    Emitter<TaskListState> emit,
  ) async {
    final current = state;
    if (current is! TaskListLoadSuccess) return;
    emit(current.copyWith(searchQuery: event.query));
    if (event.query.isNotEmpty) _analytics.logEvent('search_performed');
    await _ensureEnoughFilteredResults(emit);
  }

  Future<void> _onStatusFilterToggled(
    TaskListStatusFilterToggled event,
    Emitter<TaskListState> emit,
  ) async {
    final current = state;
    if (current is! TaskListLoadSuccess) return;
    final updated = Set.of(current.selectedStatuses);
    final isSelecting = !updated.remove(event.status);
    if (isSelecting) updated.add(event.status);
    emit(current.copyWith(selectedStatuses: updated));
    if (isSelecting) {
      _analytics.logEvent(
        'filter_applied',
        parameters: {'type': 'status', 'value': event.status.name},
      );
    }
    await _ensureEnoughFilteredResults(emit);
  }

  Future<void> _onPriorityFilterToggled(
    TaskListPriorityFilterToggled event,
    Emitter<TaskListState> emit,
  ) async {
    final current = state;
    if (current is! TaskListLoadSuccess) return;
    final updated = Set.of(current.selectedPriorities);
    final isSelecting = !updated.remove(event.priority);
    if (isSelecting) updated.add(event.priority);
    emit(current.copyWith(selectedPriorities: updated));
    if (isSelecting) {
      _analytics.logEvent(
        'filter_applied',
        parameters: {'type': 'priority', 'value': event.priority.name},
      );
    }
    await _ensureEnoughFilteredResults(emit);
  }

  void _onFiltersCleared(
    TaskListFiltersCleared event,
    Emitter<TaskListState> emit,
  ) {
    final current = state;
    if (current is! TaskListLoadSuccess) return;
    emit(
      current.copyWith(
        searchQuery: '',
        selectedStatuses: const {},
        selectedPriorities: const {},
      ),
    );
  }

  @override
  Future<void> close() {
    unawaited(_taskUpdatesSubscription.cancel());
    return super.close();
  }
}
