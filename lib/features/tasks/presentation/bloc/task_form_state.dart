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
  const TaskFormSubmitSuccess(this.task, {required this.isPendingSync});

  final Task task;

  /// True when the save only reached the local overlay — offline, or the
  /// remote write failed and got queued — so the UI shouldn't claim the
  /// task was actually synced yet.
  final bool isPendingSync;

  @override
  List<Object?> get props => [task, isPendingSync];
}

final class TaskFormSubmitFailure extends TaskFormState {
  const TaskFormSubmitFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
