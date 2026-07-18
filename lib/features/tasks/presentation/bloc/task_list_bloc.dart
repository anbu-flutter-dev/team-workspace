import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/core/network/api_constants.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/repositories/task_repository.dart';
import 'package:team_workspace/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_state.dart';

class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc(this._getTasks, this._repository)
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
  late final StreamSubscription<Task> _taskUpdatesSubscription;

  Future<void> _onStarted(
    TaskListStarted event,
    Emitter<TaskListState> emit,
  ) async {
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
    final current = state;
    if (current is! TaskListLoadSuccess) return false;
    if (!current.hasMore || current.isLoadingNextPage) return false;

    emit(current.copyWith(isLoadingNextPage: true, paginationError: null));
    final nextPage = current.currentPage + 1;
    final result = await _getTasks(page: nextPage);
    var fetchedMore = false;
    result.fold(
      (failure) => emit(
        current.copyWith(
          isLoadingNextPage: false,
          paginationError: failure.message,
        ),
      ),
      (page) {
        fetchedMore = true;
        emit(
          current.copyWith(
            tasks: [...current.tasks, ...page.tasks],
            currentPage: nextPage,
            hasMore: page.hasMore,
            isLoadingNextPage: false,
          ),
        );
      },
    );
    return fetchedMore;
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
    await _ensureEnoughFilteredResults(emit);
  }

  Future<void> _onStatusFilterToggled(
    TaskListStatusFilterToggled event,
    Emitter<TaskListState> emit,
  ) async {
    final current = state;
    if (current is! TaskListLoadSuccess) return;
    final updated = Set.of(current.selectedStatuses);
    if (!updated.remove(event.status)) updated.add(event.status);
    emit(current.copyWith(selectedStatuses: updated));
    await _ensureEnoughFilteredResults(emit);
  }

  Future<void> _onPriorityFilterToggled(
    TaskListPriorityFilterToggled event,
    Emitter<TaskListState> emit,
  ) async {
    final current = state;
    if (current is! TaskListLoadSuccess) return;
    final updated = Set.of(current.selectedPriorities);
    if (!updated.remove(event.priority)) updated.add(event.priority);
    emit(current.copyWith(selectedPriorities: updated));
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
