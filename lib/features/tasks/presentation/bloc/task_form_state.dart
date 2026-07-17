import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';

sealed class TaskFormState extends Equatable {
  const TaskFormState();

  @override
  List<Object?> get props => [];
}

final class TaskFormInitial extends TaskFormState {
  const TaskFormInitial();
}

final class TaskFormSubmitting extends TaskFormState {
  const TaskFormSubmitting();
}

final class TaskFormSubmitSuccess extends TaskFormState {
  const TaskFormSubmitSuccess(this.task);

  final Task task;

  @override
  List<Object?> get props => [task];
}

final class TaskFormSubmitFailure extends TaskFormState {
  const TaskFormSubmitFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
