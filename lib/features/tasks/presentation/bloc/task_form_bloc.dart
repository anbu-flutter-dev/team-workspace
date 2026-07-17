import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:team_workspace/core/error/result.dart';
import 'package:team_workspace/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:team_workspace/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_form_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_form_state.dart';

/// Shared by the create and edit screens — `event.existingTask` picks the path.
@injectable
class TaskFormBloc extends Bloc<TaskFormEvent, TaskFormState> {
  TaskFormBloc(this._createTask, this._updateTask)
    : super(const TaskFormInitial()) {
    on<TaskFormSubmitted>(_onSubmitted);
  }

  final CreateTaskUseCase _createTask;
  final UpdateTaskUseCase _updateTask;

  Future<void> _onSubmitted(
    TaskFormSubmitted event,
    Emitter<TaskFormState> emit,
  ) async {
    emit(const TaskFormSubmitting());

    final existingTask = event.existingTask;
    final result = existingTask == null
        ? await _createTask(
            title: event.title,
            description: event.description,
            priority: event.priority,
            dueDate: event.dueDate,
          )
        : await _updateTask(
            existingTask.copyWith(
              title: event.title,
              description: event.description,
              priority: event.priority,
              dueDate: event.dueDate,
              status: event.status ?? existingTask.status,
            ),
          );

    result.fold(
      (failure) => emit(TaskFormSubmitFailure(failure.message)),
      (task) => emit(TaskFormSubmitSuccess(task)),
    );
  }
}
