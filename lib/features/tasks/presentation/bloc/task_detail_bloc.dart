import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';
import 'package:team_workspace/features/tasks/domain/repositories/task_repository.dart';
import 'package:team_workspace/features/tasks/domain/usecases/get_task_by_id_usecase.dart';
import 'package:team_workspace/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_detail_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_detail_state.dart';

@injectable
class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState> {
  TaskDetailBloc(this._getTaskById, this._updateTask, this._repository)
    : super(const TaskDetailLoading()) {
    on<TaskDetailStarted>(_onStarted);
    on<TaskDetailToggleStatusRequested>(_onToggleStatusRequested);
    on<TaskDetailExternalUpdateReceived>(_onExternalUpdateReceived);
    _taskUpdatesSubscription = _repository.taskUpdates.listen(
      (task) => add(TaskDetailExternalUpdateReceived(task)),
    );
  }

  final GetTaskByIdUseCase _getTaskById;
  final UpdateTaskUseCase _updateTask;
  final TaskRepository _repository;
  late final StreamSubscription<Task> _taskUpdatesSubscription;

  Future<void> _onStarted(
    TaskDetailStarted event,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(const TaskDetailLoading());
    final result = await _getTaskById(event.taskId);
    result.fold(
      (failure) => emit(TaskDetailLoadFailure(failure.message)),
      (task) => emit(TaskDetailLoadSuccess(task)),
    );
  }

  Future<void> _onToggleStatusRequested(
    TaskDetailToggleStatusRequested event,
    Emitter<TaskDetailState> emit,
  ) async {
    final current = state;
    if (current is! TaskDetailLoadSuccess) return;

    final previous = current.task;
    final optimistic = previous.copyWith(
      status: previous.isCompleted ? TaskStatus.pending : TaskStatus.completed,
    );
    emit(TaskDetailLoadSuccess(optimistic));

    final result = await _updateTask(optimistic);
    result.fold((failure) {
      emit(TaskDetailToggleFailed(previous, failure.message));
      emit(TaskDetailLoadSuccess(previous));
    }, (updated) => emit(TaskDetailLoadSuccess(updated)));
  }

  void _onExternalUpdateReceived(
    TaskDetailExternalUpdateReceived event,
    Emitter<TaskDetailState> emit,
  ) {
    final current = state;
    if (current is TaskDetailLoadSuccess && current.task.id == event.task.id) {
      emit(TaskDetailLoadSuccess(event.task));
    }
  }

  @override
  Future<void> close() {
    unawaited(_taskUpdatesSubscription.cancel());
    return super.close();
  }
}
