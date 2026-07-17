import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/repositories/task_repository.dart';
import 'package:team_workspace/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_state.dart';

@injectable
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc(this._getTasks, this._repository)
    : super(const TaskListLoading()) {
    on<TaskListStarted>(_onStarted);
    on<TaskListRefreshRequested>(_onRefreshRequested);
    on<TaskListNextPageRequested>(_onNextPageRequested);
    on<TaskUpdateReceived>(_onTaskUpdateReceived);
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
  }

  Future<void> _onNextPageRequested(
    TaskListNextPageRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final current = state;
    if (current is! TaskListLoadSuccess) return;
    if (!current.hasMore || current.isLoadingNextPage) return;

    emit(current.copyWith(isLoadingNextPage: true, paginationError: null));
    final nextPage = current.currentPage + 1;
    final result = await _getTasks(page: nextPage);
    result.fold(
      (failure) => emit(
        current.copyWith(
          isLoadingNextPage: false,
          paginationError: failure.message,
        ),
      ),
      (page) => emit(
        TaskListLoadSuccess(
          tasks: [...current.tasks, ...page.tasks],
          currentPage: nextPage,
          hasMore: page.hasMore,
          isFromCache: current.isFromCache,
        ),
      ),
    );
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

  @override
  Future<void> close() {
    unawaited(_taskUpdatesSubscription.cancel());
    return super.close();
  }
}
